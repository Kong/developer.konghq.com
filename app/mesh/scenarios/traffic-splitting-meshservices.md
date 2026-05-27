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
        Multiple versions of a service (e.g., `booking-engine`) deployed with identifying labels.
next_steps:
  - text: "Understanding MeshSubsets"
    url: "/mesh/scenarios/subsets-and-targeting/"
---

The Kong Air engineering team is launching a new **Booking Engine v2**. To ensure a smooth transition, they want to route 90% of traffic to the stable `v1` and 10% to the new `v2` for a group of internal pilot users. 

This guide demonstrates how to achieve this using **Explicit Subsetting**, the recommended pattern for modern service mesh architectures.

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
    Route -->|"90% Weight"| Stable["booking-engine-v1 (MeshService)"]
    Route -->|"10% Weight"| Canary["booking-engine-v2 (MeshService)"]
{% endmermaid %}

## Configuration

### 1. Define Explicit MeshServices

On current Kuma, the control plane can generate baseline `MeshService` resources automatically for workloads. For rollout patterns like canary and blue/green, though, you still want version-specific destinations that the route can name directly.

On **Kubernetes**, the validated 2.13 path is to create **versioned Services** (`booking-engine-v1`, `booking-engine-v2`) and let Kuma generate healthy `MeshService` resources from them. On **Universal**, you define the `MeshService` resources directly.

{% navtabs "meshservice-split" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: v1
kind: Service
metadata:
  name: booking-engine-v1
  namespace: kong-air-production
spec:
  selector:
    app: booking-engine
    version: v1
  ports:
    - port: 8080
      targetPort: 8080
      appProtocol: http
---
apiVersion: v1
kind: Service
metadata:
  name: booking-engine-v2
  namespace: kong-air-production
spec:
  selector:
    app: booking-engine
    version: v2
  ports:
    - port: 8080
      targetPort: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshService
name: booking-engine-v1
mesh: kong-air-mesh
spec:
  ports:
    - port: 8080
      appProtocol: http
  selector:
    dataplaneTags:
      app: booking-engine-v1
---
type: MeshService
name: booking-engine-v2
mesh: kong-air-mesh
spec:
  ports:
    - port: 8080
      appProtocol: http
  selector:
    dataplaneTags:
      app: booking-engine-v2' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
**Validated 2.13 Kubernetes behavior.** Hand-authored version-specific `MeshService` resources selected by dataplane tags stayed unhealthy in the test mesh. Creating versioned Kubernetes `Service` objects and letting Kuma generate `MeshService` resources from them produced healthy backends and a working split.
{% endtip %}

### 2. Configure the Weighted Route

Now, create a `MeshHTTPRoute` that distributes traffic between these two resources. The best-practice source target is the calling **`Dataplane`** selected by labels; the destination remains the shared `MeshService` that represents the booking API entry point.

{% navtabs "weighted-route" %}
{% navtab "Kubernetes" %}
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
    kind: Dataplane
    labels:
      app: passenger-portal # The workload making the booking requests
  to:
    - targetRef:
        kind: MeshService
        name: booking-engine # The shared booking API entry point
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshService
                name: booking-engine-v1
                port: 8080
                weight: 90 # 90% traffic to stable
              - kind: MeshService
                name: booking-engine-v2
                port: 8080
                weight: 10 # 10% traffic to canary' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: booking-traffic-split
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
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
                port: 8080
                weight: 90
              - kind: MeshService
                name: booking-engine-v2
                port: 8080
                weight: 10' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## Verification

To verify the split, run a simple loop from the `passenger-portal` and count the responses:

```bash
v1=0; v2=0
for i in $(seq 1 100); do
  out=$(curl -s http://booking-engine:8080/)
  case "$out" in
    *'"version":"v1"'*) v1=$((v1+1)) ;;
    *'"version":"v2"'*) v2=$((v2+1)) ;;
  esac
done
echo "v1=$v1 v2=$v2"
```

You should see a distribution close to the configured weights. In the validated 2.13 test mesh, a `90/10` route produced `94/6` over 100 requests.

{% tip %}
**Observability Bonus**: Because we used explicit `MeshService` resources, you can go to your Prometheus dashboard and see metrics broken down by `booking-engine-v1` and `booking-engine-v2` as separate entities, without needing to adjust your PromQL queries for complex tag filtering.
{% endtip %}
