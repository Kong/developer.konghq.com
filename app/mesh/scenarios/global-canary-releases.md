---
title: "Zone-Specific Canary Deployments with Cross-Region Failover"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Implement progressive canary deployments controlled independently per zone while maintaining cross-region failover capabilities using {{site.mesh_product_name}}.
products:
  - mesh
tldr:
  q: How do I perform a canary release in one zone without affecting others?
  a: |
    Use **scoped MeshHTTPRoute** policies to:
    1. **Target specific zones** using the `kuma.io/zone` tag in the `targetRef`.
    2. **Shift traffic locally** between stable and canary `MeshMultiZoneService` resources.
    3. **Maintain failover** so that if a local canary fails, traffic automatically recovers to a stable version in another region.
prereqs:
  inline:
    - title: Architecture
      content: |
        A multi-zone {{site.mesh_product_name}} deployment.
    - title: Resources
      content: |
        Separate **MeshMultiZoneService** resources for your `stable` and `canary` workloads.
next_steps:
  - text: "Global Color Routing"
    url: "/mesh/scenarios/global-color-routing/"
---

The Kong Air engineering team wants to test a new **Baggage Tracking API** in the East region without impacting the West region's stable check-in flow. This guide demonstrates how to use `MeshHTTPRoute` and `MeshMultiZoneService` to achieve asymmetrical rollouts with global safety nets.

## What this proves

{% table %}
columns:
  - title: Scenario Requirement
    key: goal
  - title: Outcome
    key: outcome
rows:
  - goal: Zone-Isolated Testing
    outcome: Kong Air can rollout a 10% canary in the **East** zone while keeping the **West** zone 100% stable.
  - goal: Seamless Abstraction
    outcome: Developers use a single MMZS hostname; the mesh handles the complex regional routing logic.
  - goal: Cross-Region Safety Net
    outcome: If the East canary (or stable) pool fails, traffic automatically failover to a stable pool in the West.
{% endtable %}

### The Asymmetrical Rollout

{% mermaid %}
graph TD
    User([User Request]) --> Gateway["Kong Gateway"]
    
    subgraph "Region: East (Canary Testing)"
        Gateway -->|"90% Weight"| Stable_East["check-in-api (stable)"]
        Gateway -->|"10% Weight"| Canary_East["check-in-api (canary)"]
    end

    subgraph "Region: West (Stable Flow)"
        Gateway -->|"100% Weight"| Stable_West["check-in-api (stable)"]
    end

    Canary_East -.->|Failover| Stable_West
    Stable_East -.->|Failover| Stable_West
{% endmermaid %}

## Configuration

### 1. Define the Global Multi-Zone Service Resources

First, create the `MeshMultiZoneService` (MMZS) resources on the **Global Control Plane**. These resources aggregate standard `MeshService` backends across all zones into a single, global hostname.

{% warning %}
The `kuma.io/origin: global` label is required on MMZS resources to ensure they are properly synchronized across the global fabric.
{% endwarning %}

{% navtabs "mmzs-resources" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-stable
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
        version: stable # Targets only pods with the "stable" version label
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-canary
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
        version: canary # Targets only pods with the "canary" version label
  ports:
    - port: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: MeshMultiZoneService
name: check-in-api-stable
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: check-in-api
        version: stable # Targets only pods with the "stable" version label
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: check-in-api-canary
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: check-in-api
        version: canary # Targets only pods with the "canary" version label
  ports:
    - port: 8080
      appProtocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### 2. East Zone Policy (Canary Active)
This policy targets only sidecars in the `east` zone. It routes 10% of traffic to the canary service.

{% navtabs "east-canary" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: check-in-east-canary
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal-east # Limits this policy to sidecars in the East region
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-stable
                weight: 90 # 90% traffic stays on the stable release
              - kind: MeshMultiZoneService
                name: check-in-api-canary
                weight: 10 # 10% traffic shifts to the new baggage tracking canary' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: check-in-east-canary
mesh: default
spec:
  targetRef:
    kind: MeshService 
    name: passenger-portal-east # Limits this policy to sidecars in the East region
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-stable
                weight: 90 # 90% traffic stays on the stable release
              - kind: MeshMultiZoneService
                name: check-in-api-canary
                weight: 10 # 10% traffic shifts to the new baggage tracking canary' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### 3. West Zone Policy (Stable Only)
This policy targets only sidecars in the `west` zone. It routes 100% of traffic to the stable service.

{% navtabs "west-stable" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: check-in-west-stable
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal-west # Limits this policy to sidecars in the West region
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-stable
                weight: 100 # West remains 100% stable while East carries the canary risk' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: check-in-west-stable
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal-west # Limits this policy to sidecars in the West region
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-stable
                weight: 100 # West remains 100% stable while East carries the canary risk' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### 4. Cross-Region Failover (Locality Aware Load Balancing)
To ensure that traffic prefers the local zone but fails over to the remote zone if the local service is down, apply a `MeshLoadBalancingStrategy`.

{% navtabs "locality-failover" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshLoadBalancingStrategy
metadata:
  name: check-in-locality
  namespace: kong-air-production
spec:
  targetRef:
    name: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      default:
        localityAwareness:
          crossZone:
            failover:
              - to:
                  type: Any # If local stable pods fail, route to the remote region
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-canary
      default:
        localityAwareness:
          disabled: false # Ensure locality is active for the canary as well
          crossZone:
            failover:
              - to:
                  type: Any # If local canary fails, fallback to ANY available remote (likely stable)' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshLoadBalancingStrategy
name: check-in-locality
mesh: default
spec:
  targetRef:
    name: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      default:
        localityAwareness:
          crossZone:
            failover:
              - to:
                  type: Any # If local stable pods fail, route to the remote region
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-canary
      default:
        localityAwareness:
          disabled: false # Ensure locality is active for the canary as well
          crossZone:
            failover:
              - to:
                  type: Any # If local canary fails, fallback to ANY available remote (likely stable)' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## How It Works
1.  **Traffic Split**: `MeshHTTPRoute` in East splits traffic: 90% to `backend-service-stable`, 10% to `backend-service-canary`.
2.  **Locality**: For the requests going to `backend-service-stable`, Envoy sees endpoints from both East and West (aggregated by `MeshMultiZoneService`).
3.  **Preference**: `MeshLoadBalancingStrategy` instructs Envoy to prefer endpoints in the local zone (East).
4.  **Failover**: If all East endpoints for `backend-service-stable` fail, Envoy automatically streams traffic to West endpoints because of the `MeshLoadBalancingStrategy`.

---

## Pattern: Zone-Local Override (Self-Service)
A powerful feature of {{site.mesh_product_name}} is that **Zone-originated policies take precedence over Global-originated policies** of the same specificity.

If your teams prefer a `kubectl`-only workflow localized to their cluster, they can apply `MeshHTTPRoute` policies directly to their **Zone Cluster**.

### How it works:
1.  **Global Base**: You can have a "Global" policy that sets 100% traffic to `stable`.
2.  **Zone Override**: When it's time to rollout in `east`, the team runs `kubectl apply` in the `east` cluster with a weight of 10% to `canary`.
3.  **Local Effect**: Sidecars in `east` will see both policies, but the **local** one wins. Sidecars in `west` continue to see only the Global 100% stable policy.
4.  **No Sync-Up**: Because these policies target a `MeshMultiZoneService`, they are **not** treated as "Producer Policies" and will **not** be synced up to other zones. This ensures the canary rollout is completely isolated to that region.
