You'll elevate two Kong Air dependencies into first-class mesh citizens: the **flight-database** (plain TCP) and **AeroPay** (HTTPS with TLS origination). Then you'll add a `MeshRetry` against AeroPay to harden the booking flow.

### Step 0: Platform team — define the naming convention

This step is done **once per mesh** by the platform team. It doesn't change for each new external dependency.

{% navtabs "hostname-generator" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: external-services
  namespace: kong-mesh-system
spec:
  template: "{% raw %}{{ .DisplayName }}{% endraw %}.ext.kongair.com"
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: HostnameGenerator
name: external-services
mesh: default
spec:
  template: "{% raw %}{{ .DisplayName }}{% endraw %}.ext.kongair.com"
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Any `MeshExternalService` tagged `kuma.io/origin: zone` from now on automatically gets a `*.ext.kongair.com` hostname.

### Step 1: Model the flight database as a `MeshExternalService`

The application uses the standard `postgres://` connection string against the new mesh hostname. The sidecar handles the rest.

{% navtabs "flight-db" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: flight-db
  namespace: kong-air-production
  labels:
    kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 5432
    protocol: tcp
  endpoints:
    - address: rds-instance-01.c7x2.us-east-1.rds.amazonaws.com
      port: 5432' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshExternalService
name: flight-db
mesh: default
labels:
  kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 5432
    protocol: tcp
  endpoints:
    - address: rds-instance-01.c7x2.us-east-1.rds.amazonaws.com
      port: 5432' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Verify mesh DNS resolves the new name:

```bash
POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kong-air-production "$POD" -c kuma-sidecar -- \
  nslookup flight-db.ext.kongair.com
```

You should see a VIP. Application code can now use `postgresql://app@flight-db.ext.kongair.com:5432/flightops` — no IP addresses, no AWS endpoint URLs.

### Step 2: Model AeroPay with TLS origination

The application calls **HTTP** at port 80 on the mesh hostname; the sidecar **upgrades to HTTPS** to the real AeroPay endpoint:

{% navtabs "aeropay" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: aeropay-api
  namespace: kong-air-production
  labels:
    kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: api.aeropay.com
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: api.aeropay.com' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshExternalService
name: aeropay-api
mesh: default
labels:
  kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: api.aeropay.com
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: api.aeropay.com' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Test that the call works as plain HTTP from the application's perspective:

```bash
BOOKING_POD=$(kubectl get pod -n kong-air-production -l app=booking-svc -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kong-air-production "$BOOKING_POD" -- \
  curl -s -o /dev/null -w "%{http_code}\n" http://aeropay-api.ext.kongair.com/healthcheck
# 200
```

The sidecar did the TLS upgrade and verified AeroPay's certificate against the standard trust roots. The application never saw an `https://` URL.

### Step 3: Add a `MeshRetry` policy for AeroPay

Use `MeshRetry` — **not** a `MeshHTTPRoute` with a `RequestRetry` filter. Retry up to 3 times on 5xx and connect-failures, with exponential backoff:

{% navtabs "aeropay-retry" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: aeropay-retry
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      default:
        http:
          numRetries: 3
          backOff:
            baseInterval: 100ms
            maxInterval: 1s
          retryOn:
            - 5xx
            - connect-failure
            - reset' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshRetry
name: aeropay-retry
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      default:
        http:
          numRetries: 3
          backOff:
            baseInterval: 100ms
            maxInterval: 1s
          retryOn:
            - 5xx
            - connect-failure
            - reset' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 4: Bound the total budget with `MeshTimeout`

Retries are useful, but unbounded retries can make a slow upstream into a worse slow upstream. Add a 5s ceiling for the whole call (including retries):

{% navtabs "aeropay-timeout" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: aeropay-timeout
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      default:
        http:
          requestTimeout: 5s' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTimeout
name: aeropay-timeout
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      default:
        http:
          requestTimeout: 5s' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 5: Add a circuit breaker to stop hammering AeroPay on outages

If AeroPay is straight-up down, retries don't help and just generate noise. `MeshCircuitBreaker` opens the circuit after a threshold of failures and stops sending requests for a recovery period:

{% navtabs "aeropay-cb" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshCircuitBreaker
metadata:
  name: aeropay-cb
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      default:
        connectionLimits:
          maxConnections: 100
        outlierDetection:
          interval: 10s
          baseEjectionTime: 30s
          maxEjectionPercent: 50
          detectors:
            totalFailures:
              consecutive: 5
            gatewayFailures:
              consecutive: 5' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshCircuitBreaker
name: aeropay-cb
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      default:
        connectionLimits:
          maxConnections: 100
        outlierDetection:
          interval: 10s
          baseEjectionTime: 30s
          maxEjectionPercent: 50
          detectors:
            totalFailures:
              consecutive: 5
            gatewayFailures:
              consecutive: 5' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 6: See AeroPay in the Service Map

Open Grafana from the observability path. `aeropay-api` should now appear as a distinct node on the Service Map, with its own RED metrics. Compare to `flight-control`'s metrics — same level of detail, despite AeroPay being an external dependency.

### What you did

- Defined a `HostnameGenerator` (platform-owned) for the `*.ext.kongair.com` namespace.
- Modelled the flight database as a TCP `MeshExternalService` — application uses the friendly hostname with no driver changes.
- Modelled AeroPay as an HTTP `MeshExternalService` with sidecar-managed TLS origination — application code stays HTTP, mesh ensures HTTPS on the wire.
- Added resilience with **`MeshRetry`** (the right resource — _not_ `MeshHTTPRoute` retry filters), `MeshTimeout` for budget, and `MeshCircuitBreaker` for outage protection.
- Confirmed AeroPay is now visible as a first-class node on the Service Map dashboard.

In Step 3 you'll fix a specific class of mTLS bridging failure that comes up when {{site.base_gateway}} is fronting a strict-mTLS mesh — the canonical "everything is 502'd" scenario.
