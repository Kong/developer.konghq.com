You'll declare two `MeshService` resources for the two versions of Kong Air's booking engine, route 90/10 between them with `MeshHTTPRoute`, and verify the split end-to-end.

### Step 1: Define explicit `MeshService` resources

Create one `MeshService` per version, each with a selector that resolves only to its own pods. Both selectors share the `app: booking-engine` tag but differ on `version:`.

{% navtabs "meshservice-split" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshService
metadata:
  name: booking-engine-v1
  namespace: kong-air-production
spec:
  selector:
    dataplaneTags:
      app: booking-engine
      version: v1
---
apiVersion: kuma.io/v1alpha1
kind: MeshService
metadata:
  name: booking-engine-v2
  namespace: kong-air-production
spec:
  selector:
    dataplaneTags:
      app: booking-engine
      version: v2' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshService
name: booking-engine-v1
mesh: default
spec:
  selector:
    dataplaneTags:
      app: booking-engine
      version: v1
---
type: MeshService
name: booking-engine-v2
mesh: default
spec:
  selector:
    dataplaneTags:
      app: booking-engine
      version: v2' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Confirm the two services exist and each is selecting the right pods:

```bash
kubectl get meshservices -n kong-air-production
kubectl describe meshservice booking-engine-v1 -n kong-air-production
```

The `Endpoints` section of each `MeshService` should list only the pods of its respective version.

### Step 2: Apply the weighted route

The `MeshHTTPRoute` targets the **source** (`passenger-portal`) and splits its outbound calls to `booking-engine` between the two versions.

{% navtabs "weighted-route" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: booking-traffic-split
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal
  to:
    - targetRef:
        kind: MeshService
        name: booking-engine
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshService
                name: booking-engine-v1
                weight: 90
              - kind: MeshService
                name: booking-engine-v2
                weight: 10' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: booking-traffic-split
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal
  to:
    - targetRef:
        kind: MeshService
        name: booking-engine
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshService
                name: booking-engine-v1
                weight: 90
              - kind: MeshService
                name: booking-engine-v2
                weight: 10' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Verify the split

From a `passenger-portal` pod, hammer the booking endpoint and count which version answers. Each version should return its identity in a response header or body field.

```bash
kubectl exec -n kong-air-production deploy/passenger-portal -- \
  sh -c 'for i in $(seq 1 100); do curl -s http://booking-engine | grep -o "version=v."; done | sort | uniq -c'
```

Expected output (roughly):

```
  90 version=v1
  10 version=v2
```

Small variance is normal — over enough requests the distribution converges on the configured weights.

### Step 4: Confirm metrics are split too

Because `booking-engine-v1` and `booking-engine-v2` are independent resources, Prometheus sees them as two distinct services. Query for request counts and the breakdown is automatic — no PromQL tag filtering needed:

```
sum by (kuma_io_service) (rate(envoy_cluster_upstream_rq_total{kuma_io_service=~"booking-engine-v.*"}[1m]))
```

You should see two separate time series, one per version. If you set up dashboards or alerts against either, they apply independently.

### Step 5: Shift the split

The whole point of this setup is that progressing the rollout is cheap. To move to 50/50:

```bash
kubectl patch meshhttproute booking-traffic-split -n kong-air-production --type=merge -p '{"spec":{"to":[{"targetRef":{"kind":"MeshService","name":"booking-engine"},"rules":[{"matches":[{"path":{"value":"/","type":"PathPrefix"}}],"default":{"backendRefs":[{"kind":"MeshService","name":"booking-engine-v1","weight":50},{"kind":"MeshService","name":"booking-engine-v2","weight":50}]}}]}]}}'
```

Run the verification loop again — you should now see ~50 requests on each version. To roll back, set `v1` to `100` and `v2` to `0` in the same `weight` fields; the failed deploys never reach a passenger.

### What you did

- Modelled each version of `booking-engine` as its own `MeshService` resource.
- Routed 90/10 between them with a single `MeshHTTPRoute` that targets the source service.
- Verified the split with both curl traffic and Prometheus metrics.
- Practiced shifting the split — the operation Kong Air's release engineers will repeat throughout the rollout.

In Step 5 you'll round out the policy model by understanding when to use a `MeshSubset` (cross-cutting, tag-based) versus a `MeshService` (explicit, resource-based) — and why everything you just did used the latter.
