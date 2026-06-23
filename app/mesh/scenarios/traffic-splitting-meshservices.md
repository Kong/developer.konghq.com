---
title: "Traffic Splitting with MeshServices"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Implement precise traffic splitting between different service versions using the modern MeshService resource model.
products:
  - mesh
tldr:
  q: How do I split traffic between different versions of my service?
  a: |
    Use **Explicit Subsetting** by:
    1. **Defining distinct versioned destinations** for each version you want to route independently (e.g., `v1` and `v2`).
    2. **Using MeshHTTPRoute** to assign `weights` to each `backendRef`.
    3. **Verifying the split** by monitoring the distribution of requests across the named services.
prereqs:
  inline:
    - title: Architecture
      content: |
        A {{site.mesh_product_name}} deployment with `meshServices.mode: Exclusive` enabled.
    - title: Workloads
      content: |
        Multiple versions of a service (e.g., `passenger-portal`) deployed with identifying labels.
next_steps:
  - text: "Targeting Workloads and Services"
    url: "/mesh/scenarios/subsets-and-targeting/"
---

The Kong Air engineering team is launching a new **Passenger Portal v2**. To ensure a smooth transition, they want to route 90% of traffic to the stable `v1` and 10% to the new `v2` for a group of internal pilot users. 

This guide demonstrates how to achieve this using **explicit `MeshService` versions** routed by a `MeshHTTPRoute`. If you want a refresher on the `targetRef` model and where `MeshService` fits in `to[]`/`backendRefs`, see [How to use policies](/mesh/scenarios/using-policies/); the [Targeting Workloads and Services](/mesh/scenarios/subsets-and-targeting/) guide that follows goes deeper on label-based targeting.

## What this proves

{% table %}
columns:
  - title: Scenario Requirement
    key: goal
  - title: Outcome
    key: outcome
rows:
  - goal: Version Isolation
    outcome: Kong Air can manage `v1` and `v2` as independent, first-class resources with their own metrics.
  - goal: Weighted Distribution
    outcome: Traffic is precisely divided (90/10) without relying on fragile pod counts.
  - goal: Resource Stability
    outcome: Adding or removing pods in either version does not require updating the routing policy.
{% endtable %}

### The Traffic Split

{% mermaid %}
graph TD
    User([User Request]) --> Gateway["{{site.base_gateway}}"]
    Gateway --> Route{"MeshHTTPRoute"}
    Route -->|"90% Weight"| Stable["passenger-portal-v1 (MeshService)"]
    Route -->|"10% Weight"| Canary["passenger-portal-v2 (MeshService)"]
{% endmermaid %}

## Configuration

### 1. Define Explicit MeshServices

{{site.mesh_product_name}} can generate baseline `MeshService` resources automatically for workloads. For rollout patterns like canary and blue/green, though, you still want version-specific destinations that the route can name directly.

On **Kubernetes**, create **versioned Services** (`passenger-portal-v1`, `passenger-portal-v2`) and let {{site.mesh_product_name}} generate the matching `MeshService` resources from them. On **Universal**, define the `MeshService` resources directly.

{% tip %}
For deployments using label-based `MeshService` matching, enable:

```yaml
experimental:
  inboundTagsDisabled: true
```

Generated `MeshService` resources then move away from inbound-tag selection and instead match dataplanes by labels. That is the cleaner model for both Kubernetes and Universal, and it aligns better with the rest of the targeting story.
{% endtip %}

{% tip %}
Why `appProtocol: http`? The Kubernetes `Service` examples below set `appProtocol: http` on the port. In `Exclusive` mode, {{site.mesh_product_name}} reads this field to set the protocol on the generated `MeshService`. Without it, the `MeshService` defaults to `tcp`, and HTTP-aware policies, `MeshHTTPRoute`, weighted splits, retries on `5xx`, silently won't apply. Always set `appProtocol` on Services you intend to route at L7.
{% endtip %}

{% navtabs "meshservice-split" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: v1
kind: Service
metadata:
  name: passenger-portal-v1
  namespace: kong-air-production
spec:
  selector:
    app: passenger-portal
    version: v1
  ports:
    - port: 8080
      targetPort: 8080
      appProtocol: http
---
apiVersion: v1
kind: Service
metadata:
  name: passenger-portal-v2
  namespace: kong-air-production
spec:
  selector:
    app: passenger-portal
    version: v2
  ports:
    - port: 8080
      targetPort: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshService
name: passenger-portal-v1
mesh: kong-air-mesh
spec:
  ports:
    - port: 8080
      appProtocol: http
  selector:
    dataplaneTags:
      app: passenger-portal-v1
---
type: MeshService
name: passenger-portal-v2
mesh: kong-air-mesh
spec:
  ports:
    - port: 8080
      appProtocol: http
  selector:
    dataplaneTags:
      app: passenger-portal-v2' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

For example, a generated label-selected `MeshService` can look like:

```yaml
type: MeshService
name: passenger-portal-v1
mesh: kong-air-mesh
spec:
  selector:
    dataplaneLabels:
      matchLabels:
        app: passenger-portal
        version: v1
        k8s.kuma.io/namespace: kong-air-production
  ports:
    - name: http
      port: 8080
      targetPort: 8080
      appProtocol: http
```

### 2. Configure the Weighted Route

Now, create a `MeshHTTPRoute` that distributes traffic between these two resources. The top-level `targetRef` is `Mesh`, so the split applies to **every client that calls `passenger-portal`**; the destination is the shared `MeshService`, and `backendRefs` weight traffic across the two versions. (To roll the split out to only some clients first, narrow the top level to `Dataplane` with a `labels:` selector.)

{% navtabs "weighted-route" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: booking-traffic-split
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh # Applies to every client that calls passenger-portal
  to:
    - targetRef:
        kind: MeshService
        name: passenger-portal # The shared booking API entry point
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshService
                name: passenger-portal-v1
                port: 8080
                weight: 90 # 90% traffic to stable
              - kind: MeshService
                name: passenger-portal-v2
                port: 8080
                weight: 10 # 10% traffic to canary' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshHTTPRoute
name: booking-traffic-split
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: passenger-portal
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshService
                name: passenger-portal-v1
                port: 8080
                weight: 90
              - kind: MeshService
                name: passenger-portal-v2
                port: 8080
                weight: 10' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## Verification

To verify the split, exec into any in-mesh pod (here `check-in-api` acts as a test client) and run a loop against `passenger-portal`, counting which version responds. **This body-matching check only works if your app echoes its version**, the Kong Air demo apps prefix responses with `v2:`; adapt the `case` matching to whatever your real versions return:

```bash
kubectl exec -n kong-air-production deploy/check-in-api -c check-in-api -- sh -c '
v1=0; v2=0
for i in $(seq 1 50); do
  out=$(wget -qO- --timeout=3 http://passenger-portal.kong-air-production.svc.cluster.local:8080/ 2>/dev/null)
  case "$out" in
    v2:*) v2=$((v2+1)) ;;
    *)    v1=$((v1+1)) ;;
  esac
done
echo "v1=$v1 v2=$v2"
'
```

You should see a distribution close to the configured weights, for a 90/10 split, expect roughly 44–46 v1 and 4–6 v2 from 50 requests.


{% tip %}
Because we used explicit `MeshService` resources, you can go to your Prometheus dashboard and see metrics broken down by `passenger-portal-v1` and `passenger-portal-v2` as separate entities, without needing to adjust your PromQL queries for complex tag filtering.
{% endtip %}
