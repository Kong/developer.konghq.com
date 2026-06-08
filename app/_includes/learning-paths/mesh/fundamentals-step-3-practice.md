You'll layer three `MeshTimeout` policies — one at each level of the target hierarchy — and watch the "most specific wins" rule decide which one a request actually gets.

### Step 1: Set a mesh-wide baseline

Apply a generous 30-second request timeout for every workload in the mesh:

{% navtabs "mesh-timeout-baseline" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: baseline-timeout
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 30s' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTimeout
name: baseline-timeout
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 30s' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Every outbound request from every sidecar now has a 30s ceiling unless something more specific overrides it.

### Step 2: Tighten an entire region with `MeshSubset`

Kong Air's `us-east-1` region runs cross-AZ and tends to be a few hundred milliseconds slower than the others. Cap requests there at 15s:

{% navtabs "mesh-timeout-subset" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: us-east-1-timeout
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: MeshSubset
    tags:
      region: us-east-1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 15s' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTimeout
name: us-east-1-timeout
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      region: us-east-1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 15s' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Any workload tagged `region: us-east-1` now uses 15s. Workloads in other regions still use the 30s baseline.

### Step 3: Override one critical service with `MeshService`

`flight-control` calls a slow downstream that occasionally takes up to 45s. Override the 15s subset value just for that service:

{% navtabs "mesh-timeout-service" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: flight-control-timeout
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: MeshService
    name: flight-control
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 60s' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTimeout
name: flight-control-timeout
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: flight-control
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 60s' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 4: Confirm what actually applies

`kumactl inspect dataplane` shows the effective merged configuration on a specific sidecar. Pick a `flight-control` pod in `us-east-1` and confirm the resolved timeout is 60s, not 15s and not 30s:

```bash
kumactl inspect dataplane flight-control-xyz-0 --mesh default --type config-dump | jq '.. | objects | select(.requestTimeout?) | .requestTimeout'
```

You should see `"60s"` — the `MeshService`-level policy wins, even though both broader policies match the same workload.

Now pick a workload in `us-east-1` that is **not** `flight-control` (e.g., `passenger-portal-xyz-0`). Its effective timeout should be `15s` — the subset-level policy wins over the mesh baseline.

A workload in `us-west-2` with no overrides should resolve to `30s` — the mesh baseline.

### Step 5: Clean up

If you don't need these timeouts going forward, remove them so they don't interact with later steps:

{% navtabs "cleanup-timeouts" %}
{% navtab "Kubernetes" %}
```bash
kubectl delete meshtimeout baseline-timeout us-east-1-timeout flight-control-timeout -n kong-mesh-system
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
kumactl delete meshtimeout baseline-timeout --mesh default
kumactl delete meshtimeout us-east-1-timeout --mesh default
kumactl delete meshtimeout flight-control-timeout --mesh default
```
{% endnavtab %}
{% endnavtabs %}

### What you did

- Applied a baseline `MeshTimeout` at `Mesh` scope.
- Overrode it for a region with `MeshSubset`.
- Overrode that for a specific service with `MeshService`.
- Used `kumactl inspect dataplane` to confirm the "most specific wins" precedence rule resolves correctly at the sidecar.

In Step 4 you'll use the same `targetRef` shape — this time on `MeshHTTPRoute` and `MeshService` resources — to split traffic between two versions of Kong Air's booking engine.
