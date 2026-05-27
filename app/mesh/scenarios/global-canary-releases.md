---
title: "Zone-Specific Canary Deployments with Cross-Region Failover"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Implement a zone-local canary rollout on 2.13 using MeshMultiZoneService and MeshHTTPRoute, while keeping the stable pool available across zones.
products:
  - mesh
tldr:
  q: How do I perform a canary release in one zone without affecting others?
  a: |
    Use **Global MeshMultiZoneService** resources plus a **zone-local MeshHTTPRoute** to:
    1. **Aggregate the stable pool** across zones behind one MMZS hostname.
    2. **Expose the canary pool** as a separate MMZS, usually present in only one zone.
    3. **Apply the canary split only in the rollout zone**, so other zones are unaffected unless they add their own override.
prereqs:
  inline:
    - title: Architecture
      content: |
        A multi-zone {{site.mesh_product_name}} deployment with `spec.meshServices.mode: Exclusive` set on the `kong-air-mesh` `Mesh` resource.
    - title: Services
      content: |
        A **stable** `MeshService` in every zone you want to fail over between, plus a separate **canary** `MeshService` in the rollout zone.
    - title: Identity
      content: |
        Keep the **same identity model** across the stable and canary backends before you test this pattern. During validation, mixing `MeshIdentity`-backed workloads with legacy service-tag identities caused TLS verification failures even when the route shape was correct. On 2.13, if you apply `MeshIdentity` to existing workloads, restart those workloads before you test the canary route so they actually serve the new certificate.
next_steps:
  - text: "Global Color Routing"
    url: "/mesh/scenarios/global-color-routing/"
---

The Kong Air engineering team wants to test a new **Baggage Tracking API** in one zone without changing the routing policy everywhere else. This guide shows the 2.13 best-practice shape: create global `MeshMultiZoneService` resources on the Global CP, then apply a **zone-local** `MeshHTTPRoute` only in the rollout zone.

## What this proves

{% table %}
columns:
  - title: Scenario Requirement
    key: goal
  - title: Outcome
    key: outcome
rows:
  - goal: Zone-Isolated Testing
    outcome: Kong Air can rollout a 10% canary in one zone while other zones continue using the stable pool unless they define their own local override.
  - goal: Seamless Abstraction
    outcome: Clients use a single MMZS hostname for the stable service, while the mesh resolves the underlying zone-local MeshServices.
  - goal: Stable-Pool Safety Net
    outcome: The stable pool can span multiple zones through one MMZS, which is the foundation for locality-aware cross-zone failover.
{% endtable %}

{% tip %}
**Validated 2.13 behavior.** On the live mesh, the `MeshMultiZoneService` resources synced correctly from Global to each zone, including generated hostnames such as `check-in-api-global.mzsvc.mesh.local`. A zone-local `MeshHTTPRoute` targeting those synced MMZS resources worked when the route referenced them by **`kuma.io/display-name` labels** and included an explicit backend `port`.
{% endtip %}

## Configuration

### 1. Define the Global MeshMultiZoneService resources

Create the `MeshMultiZoneService` (MMZS) resources on the **Global Control Plane**. On 2.13, the cleanest pattern is to select the generated `MeshService` objects by their service-name labels.

{% warning %}
`MeshMultiZoneService` is a **Global CP** resource. On Konnect or a Universal-backed Global CP, create it with `kumactl`. The synced zone copies receive a hash suffix in `metadata.name`, so **zone-local policies should reference them by labels, not by name**.
{% endwarning %}

{% navtabs "mmzs-resources" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-global
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: check-in-api
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-canary-global
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: check-in-api-canary
  ports:
    - port: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal / Konnect Global CP" %}
```bash
echo 'type: MeshMultiZoneService
name: check-in-api-global
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: check-in-api
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: check-in-api-canary-global
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: check-in-api-canary
  ports:
    - port: 8080
      appProtocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

After sync, the zone copies expose hostnames like:

- `check-in-api-global.mzsvc.mesh.local`
- `check-in-api-canary-global.mzsvc.mesh.local`

### 2. Apply the rollout-zone canary route

Apply this route only in the zone where you want the canary split. The validated 2.13 shape is:

- top-level `targetRef.kind: Dataplane`
- select the local callers with labels
- reference the synced MMZS resources by `labels.kuma.io/display-name`
- include `port: 8080` on every `MeshMultiZoneService` backend

{% navtabs "zone-canary" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: check-in-global-canary
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: check-in-api-global
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: check-in-api-global
                port: 8080
                weight: 90
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: check-in-api-canary-global
                port: 8080
                weight: 10' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal / Global CP" %}
```bash
echo 'type: MeshHTTPRoute
name: check-in-global-canary
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: check-in-api-global
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: check-in-api-global
                port: 8080
                weight: 90
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: check-in-api-canary-global
                port: 8080
                weight: 10' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
This route is **zone-local**. Other zones keep using their existing stable path unless they add their own override or you apply a broader global route.
{% endtip %}

### 3. Verify the synced MMZS and route

Check that the synced MMZS resources matched the expected backends:

```bash
kubectl get meshmultizoneservices -n {{site.mesh_system_namespace}} -o yaml
```

On the validated mesh:

- `check-in-api-global` matched **2 MeshServices** (zone1 stable + zone2 stable)
- `check-in-api-canary-global` matched **1 MeshService** (zone1 canary)

You can then test from a pod in the rollout zone:

```bash
kubectl exec -n kong-air-production <caller-pod> -c tools -- \
  curl -sS http://check-in-api-global.mzsvc.mesh.local:8080
```

After the workloads were reconciled onto the same identity model, the live 2.13 mesh produced the expected split again. A `90/10` route returned `54` stable responses and `6` canary responses over `60` requests.

## Optional: locality-aware failover for the stable pool

`MeshLoadBalancingStrategy` is the policy that controls locality-aware failover. The stable-pool part of the pattern is a good fit for it because `check-in-api-global` spans multiple zones.

{% warning %}
We did **not** fully validate the end-to-end failover step on the live 2.13 mesh in this scenario until the workloads were reconciled onto a consistent identity model. Once the stable and canary workloads mixed different identity models, otherwise-correct HTTP routing started failing TLS verification. Treat the load-balancing step below as the right policy family and shape to validate in your environment after you confirm a consistent identity/trust setup and restart the workloads selected by your `MeshIdentity` resources.
{% endwarning %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshLoadBalancingStrategy
metadata:
  name: check-in-locality
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: check-in-api-global
      default:
        localityAwareness:
          disabled: false
          crossZone:
            failover:
              - to:
                  type: Any
```

## What changed from the earlier pattern

This scenario used to assume:

- per-zone services like `passenger-portal-east` and `passenger-portal-west`
- direct MMZS references by `name`
- `MeshHTTPRoute` backends without explicit `port`
- automatic "canary fails over to remote stable" behavior

That was too optimistic for the validated 2.13 path. The safer guidance is:

1. Use **one stable MMZS** spanning the zones you want to fail over between.
2. Use **one canary MMZS** for the rollout pool.
3. Apply the route **only in the rollout zone**.
4. Reference synced global resources by **`kuma.io/display-name` labels** from zone-local policies.
5. Keep the **identity model consistent** across all backends before testing cross-zone failover.

## Pattern: Zone-local override

This remains the core operational pattern:

1. Create the shared `MeshMultiZoneService` resources on the **Global CP**
2. Apply the canary route only in the **rollout zone**
3. Leave other zones untouched until they are ready to add their own override

That gives teams a practical self-service workflow: global service discovery stays centralized, while the rollout decision stays local to the zone that owns the experiment.
