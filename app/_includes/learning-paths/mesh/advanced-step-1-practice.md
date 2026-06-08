You'll walk Kong Air's mesh through the three passthrough states — open by default, fully locked down, then opened back up with a precise allowlist — and add a service-specific exception for one workload that legitimately needs broader access.

### Step 1: Confirm the current open-mesh behaviour

From any pod inside the mesh, try to reach an arbitrary external destination. By default it should succeed:

```bash
POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kong-air-production "$POD" -- \
  curl -s -o /dev/null -w "%{http_code}\n" https://example.com
# 200
```

That's the permissive default — anything goes out of the mesh.

### Step 2: Apply a default-deny passthrough at the mesh level

{% navtabs "passthrough-deny" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: secure-perimeter
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: None' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshPassthrough
name: secure-perimeter
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: None' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Re-run the previous command. It should now fail at the sidecar:

```bash
kubectl exec -n kong-air-production "$POD" -- \
  curl -s -o /dev/null -w "%{http_code}\n" https://example.com
# 503 (or a connection timeout)
```

The mesh is now closed: nothing reaches external destinations unless explicitly allowed.

### Step 3: Open up the legitimate Kong Air dependencies

Kong Air's services routinely call:

- **AeroPay** (`api.aeropay.com:443`) — the payment processor.
- **CrewSched** (`api.crewsched.com:443`) — third-party crew scheduling.
- **AWS S3** (`*.s3.amazonaws.com:443`) — operational data uploads.
- A specific log-forwarder VPC endpoint on `10.42.0.0/16`.

Express that as a `Matched` policy. Note that every `Domain` entry needs a `protocol`:

{% navtabs "passthrough-matched" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: secure-perimeter
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: Matched
    appendMatch:
      - type: Domain
        value: api.aeropay.com
        port: 443
        protocol: tls
      - type: Domain
        value: api.crewsched.com
        port: 443
        protocol: tls
      - type: Domain
        value: "*.s3.amazonaws.com"
        port: 443
        protocol: tls
      - type: IP
        value: "10.42.0.0/16"
        port: 514
        protocol: tcp' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshPassthrough
name: secure-perimeter
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: Matched
    appendMatch:
      - type: Domain
        value: api.aeropay.com
        port: 443
        protocol: tls
      - type: Domain
        value: api.crewsched.com
        port: 443
        protocol: tls
      - type: Domain
        value: "*.s3.amazonaws.com"
        port: 443
        protocol: tls
      - type: IP
        value: "10.42.0.0/16"
        port: 514
        protocol: tcp' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Verify the allowlist works:

```bash
kubectl exec -n kong-air-production "$POD" -- \
  curl -s -o /dev/null -w "%{http_code}\n" https://api.aeropay.com/healthcheck
# 200

kubectl exec -n kong-air-production "$POD" -- \
  curl -s -o /dev/null -w "%{http_code}\n" https://example.com
# 503 - still blocked
```

### Step 4: Layer a service-specific exception

The `data-warehouse-loader` workload needs broader S3 access — not just one bucket pattern, but any bucket in the corporate account. Add a `MeshService`-scoped override.

{% navtabs "passthrough-service-override" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: data-warehouse-loader-passthrough
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: MeshService
    name: data-warehouse-loader
  default:
    passthroughMode: Matched
    appendMatch:
      - type: Domain
        value: "*.s3.amazonaws.com"
        port: 443
        protocol: tls
      - type: Domain
        value: "*.s3-accelerate.amazonaws.com"
        port: 443
        protocol: tls
      - type: Domain
        value: "*.s3.dualstack.amazonaws.com"
        port: 443
        protocol: tls' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshPassthrough
name: data-warehouse-loader-passthrough
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: data-warehouse-loader
  default:
    passthroughMode: Matched
    appendMatch:
      - type: Domain
        value: "*.s3.amazonaws.com"
        port: 443
        protocol: tls
      - type: Domain
        value: "*.s3-accelerate.amazonaws.com"
        port: 443
        protocol: tls
      - type: Domain
        value: "*.s3.dualstack.amazonaws.com"
        port: 443
        protocol: tls' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Because this policy targets `MeshService: data-warehouse-loader`, it wins for that workload by precedence (Step 3 of Fundamentals). Other workloads still see only the four mesh-wide allowed destinations.

### Step 5: Confirm the deny shows up in access logs

If you set up `MeshAccessLog` in the previous path, denied traffic will show up there. Tail the sidecar log on a workload that just tried to call something blocked:

```bash
kubectl exec -n kong-air-production "$POD" -c kuma-sidecar -- tail -20 /tmp/access.log \
  | grep -E '"status":(0|403|503)'
```

You should see entries for the blocked attempts, useful as input to a recurring "what is being blocked?" review.

### Step 6: (Optional) move enforcement to the ZoneEgress

If you deployed a ZoneEgress in the previous path, you can lift `MeshPassthrough` to execute there instead of at every sidecar. The policy itself is identical; you just narrow its `targetRef` to the egress proxy. Centralised audit, single firewall scope, one access log to forward.

### What you did

- Confirmed the default open-mesh outbound behaviour.
- Locked down the perimeter mesh-wide with `passthroughMode: None`.
- Opened back up to a precise allowlist of legitimate Kong Air external dependencies.
- Layered a service-specific exception for `data-warehouse-loader` without weakening the mesh-wide default.
- Saw how denied traffic surfaces in `MeshAccessLog` for ongoing review.

In Step 2 you'll go beyond allowlisting and elevate AeroPay and the flight database to **first-class mesh citizens** — friendly internal hostnames, mesh-managed TLS origination, and resilience policies like `MeshRetry`.
