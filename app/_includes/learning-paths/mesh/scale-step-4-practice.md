You'll set up color affinity for Kong Air's `check-in-api → flight-control` chain — `blu` and `green` rings — using one agnostic `MeshMultiZoneService` per service plus a pair of color-pinning `MeshHTTPRoute` policies per color.

The example assumes `MeshService` resources already exist for each colored ring (`check-in-api-blu`, `check-in-api-green`, `flight-control-blu`, `flight-control-green`) and that the underlying pods carry a `color` label.

### Step 1: Define the color-specific MMZS resources

One MMZS per service, per color. Each selects only `MeshService`s of that color.

{% navtabs "color-mmzs" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-blu
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
        color: blu
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-green
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
        color: green
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: flight-control-blu
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: flight-control
        color: blu
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: flight-control-green
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: flight-control
        color: green
  ports:
    - port: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: MeshMultiZoneService
name: check-in-api-blu
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: check-in-api
        color: blu
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: check-in-api-green
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: check-in-api
        color: green
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: flight-control-blu
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: flight-control
        color: blu
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: flight-control-green
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: flight-control
        color: green
  ports:
    - port: 8080
      appProtocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 2: Define the agnostic MMZS resources

One per service, no color selector — these aggregate every colored ring. Applications call _these_ hostnames.

{% navtabs "agnostic-mmzs" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-all
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: flight-control-all
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: flight-control
  ports:
    - port: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: MeshMultiZoneService
name: check-in-api-all
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: check-in-api
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: flight-control-all
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: flight-control
  ports:
    - port: 8080
      appProtocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Apply the color-pinning routes for the BLU ring

Two routes for `blu`: clients hitting the agnostic `check-in-api-all` go to `check-in-api-blu`, and `check-in-api`'s outbound calls to `flight-control-all` go to `flight-control-blu`.

{% navtabs "blu-routes" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: client-blu-to-check-in-blu
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: client-blu
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-all
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-blu
                weight: 100
---
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: check-in-blu-to-flight-blu
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: check-in-api-blu
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: flight-control-all
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: flight-control-blu
                weight: 100' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: client-blu-to-check-in-blu
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: client-blu
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-all
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-blu
                weight: 100
---
type: MeshHTTPRoute
name: check-in-blu-to-flight-blu
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: check-in-api-blu
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: flight-control-all
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: flight-control-blu
                weight: 100' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Apply the symmetric pair for `green` — same shape, every `blu` replaced with `green`.

### Step 4: Verify color affinity end to end

Call the agnostic hostname from a `blu` client and inspect the response chain:

```bash
BLU_CLIENT=$(kubectl get pod -n kong-air-production -l app=client,color=blu -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n kong-air-production "$BLU_CLIENT" -- \
  curl -s http://check-in-api-all.mzsvc.kong-air-production.mesh.local:8080
```

You should see a nested JSON response showing every hop's color:

```json
{
  "service": "check-in-api",
  "color": "blu",
  "pod": "check-in-api-blu-abc123",
  "backend_call": {
    "url": "http://flight-control-all.mzsvc.kong-air-production.mesh.local:8080",
    "response": {
      "service": "flight-control",
      "color": "blu",
      "pod": "flight-control-blu-def456"
    }
  }
}
```

Two things to notice:

- The `url` field shows the **agnostic** hostname — `check-in-api` is colour-blind in its source code.
- The `color` at both levels is `blu`, matching the original caller.

Run the same exercise from a `green` client; the chain should stay on `green` the whole way.

### Step 5: Verify cross-color isolation

Hammer the agnostic hostname from many `blu` clients and confirm zero requests land on `green`:

```bash
for i in $(seq 1 100); do
  kubectl exec -n kong-air-production "$BLU_CLIENT" -- \
    curl -s http://check-in-api-all.mzsvc.kong-air-production.mesh.local:8080 \
    | grep -o '"color":"[a-z]*"'
done | sort | uniq -c

# 100 "color":"blu"
```

If you see any `green`, you have a misconfigured route — recheck the `targetRef` on the routes you applied.

### Step 6: Test cross-zone failover within a color

Scale down the `blu` ring in your local zone to confirm requests fail over to `blu` endpoints in another zone — _not_ to `green`:

```bash
kubectl --context east scale deployment check-in-api-blu -n kong-air-production --replicas=0
```

Hit the agnostic hostname from an East `blu` client. The response's `color` should still be `blu`, but the `pod` field will show a West pod. Restore when done:

```bash
kubectl --context east scale deployment check-in-api-blu -n kong-air-production --replicas=3
```

### What you did

- Built one MMZS per (service, color) pair and one agnostic MMZS per service.
- Applied paired color-pinning `MeshHTTPRoute` policies for two services in a chain.
- Confirmed end-to-end color affinity: a `blu` request stays `blu` through both hops, no application changes required.
- Confirmed isolation: `blu` traffic never crosses into `green` endpoints.
- Confirmed failover stays within the color ring across zones.

### What's next

You now have a tour-tested multi-zone operating model: per-zone canaries, color affinity, and cross-zone failover all in one mesh. The next path covers the harder edge cases — what to do about traffic _leaving_ the mesh (`MeshPassthrough`, `MeshExternalService`), bridging external ingresses to the mesh, validating resilience with chaos engineering, and the escape hatch for low-level Envoy customisation.
