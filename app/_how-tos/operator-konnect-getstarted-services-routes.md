---
title: Create a Service and Route
description: Provision a service and route in Konnect using Kubernetes CRDs.
content_type: how_to
permalink: /operator/konnect/get-started/service-and-route/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: kgo-get-started
  position: 4

tldr:
  q: How do I expose an upstream service using Konnect CRDs?
  a: |
    Use `KongService` and `KongRoute` resources to define and expose your service through the Konnect Gateway.

products:
  - operator

works_on:
  - konnect

entities: []

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## How Kubernetes resources map to {{site.base_gateway}} entities

A Service inside Kubernetes is a way to abstract an application that is running on a set of Pods. This maps to two entities in {{site.base_gateway}}: Service and Upstream.

The Service entity in {{site.base_gateway}} holds the protocol information needed to talk to the upstream service and various other protocol-specific settings. The Upstream object defines load balancing and health-checking behavior.

<!--vale off-->
{% mermaid %}
flowchart LR
    H(Request traffic)
    subgraph Pods
        direction LR
        E(Target)
        F(Target)
        G(Target)
    end

    subgraph Kubernetes Service
        direction TB
        C(Service)
        D(Upstream)
    end
    
    subgraph Ingress / HTTPRoute
        direction LR
        A(Route)
        B(Route)
    end

    A --> C
    B --> C
    C --> D
    D --> E
    D --> F
    D --> G
    H --> A

    linkStyle 6 stroke:#b6d7a8
{% endmermaid %}
<!--vale on-->

## Create a `KongService` 

Create a Gateway Service in the [{{site.konnect_short_name}} Gateway Manager](/gateway-manager/). The Service must reference an existing `KonnectGatewayControlPlane`.

<!-- vale off -->
{% konnect_crd %}
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: service
spec:
  name: service
  host: httpbin.konghq.com
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

## Create a `KongRoute`

To expose the Service, create a `KongRoute` associated with the `KongService` defined above.

<!-- vale off -->
{% konnect_crd %}
kind: KongRoute
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: route
spec:
  name: route
  protocols:
  - http
  paths:
  - /
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: service
{% endkonnect_crd %}
<!-- vale on -->

## Validation

To validate, check that the Route and Service were configured correctly: 

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongService
name: service
{% endvalidation %}
<!-- vale on -->

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongRoute
name: route
{% endvalidation %}
<!-- vale on -->