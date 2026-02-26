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
    1. **Defining distinct MeshService resources** for each version (e.g., `v1` and `v2`).
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
    User([User Request]) --> Gateway["Kong Gateway"]
    Gateway --> Route{"MeshHTTPRoute"}
    Route -->|"90% Weight"| Stable["booking-engine-v1 (MeshService)"]
    Route -->|"10% Weight"| Canary["booking-engine-v2 (MeshService)"]
{% endmermaid %}

## Configuration

### 1. Define Explicit MeshServices

Unlike legacy meshes that group everything under a single service name and filter by tags, {{site.mesh_product_name}} encourages you to define each version as a unique `MeshService`.

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
      version: v1 # Selects v1 pods
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
      version: v2 # Selects v2 pods' | kubectl apply -f -
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
      version: v1 # Selects v1 pods
---
type: MeshService
name: booking-engine-v2
mesh: default
spec:
  selector:
    dataplaneTags:
      app: booking-engine
      version: v2 # Selects v2 pods' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### 2. Configure the Weighted Route

Now, create a `MeshHTTPRoute` that distributes traffic between these two resources. We target the "source" service (the one making the request) and define the split in the `backendRefs`.

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
    name: passenger-portal # The service making the booking requests
  to:
    - targetRef:
        kind: MeshService
        name: booking-engine # The "virtual" entry point for the booking service
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshService
                name: booking-engine-v1
                weight: 90 # 90% traffic to stable
              - kind: MeshService
                name: booking-engine-v2
                weight: 10 # 10% traffic to canary' | kubectl apply -f -
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

## Verification

To verify the split, run a simple loop from the `passenger-portal` and observe the headers or responses:

```bash
for i in {1..20}; do curl -s passenger-portal:8080 | grep "version"; done
```

You should see approximately 18 responses from `v1` and 2 responses from `v2`.

{% tip %}
**Observability Bonus**: Because we used explicit `MeshService` resources, you can go to your Prometheus dashboard and see metrics broken down by `booking-engine-v1` and `booking-engine-v2` as separate entities, without needing to adjust your PromQL queries for complex tag filtering.
{% endtip %}
