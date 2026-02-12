---
title: Create a Service and Route
description: Provision a service and route in Konnect using Kubernetes CRDs.
content_type: how_to
permalink: /operator/get-started/konnect-crds/service-and-route/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-get-started-konnect-crds
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

---

A Kubernetes Service represents an application running on a group of Pods. In {{site.base_gateway}}, this maps to a `Service` and `Upstream`.

* The **KongService** defines protocol-specific information and connection settings to reach the upstream application.
* The **Upstream** defines load balancing and health checking behavior across backend targets.


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


## Deploy a Service to Kubernetes
Let's deploy an `echo` service to the Kubernetes cluster and setup the `KongService` and `KongRoute`:

```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

## Create a `KongService` 

The `KongService` resource is used to define an upstream service that {{site.konnect_short_name}} will route traffic to. This must include a reference to a `KonnectGatewayControlPlane` to associate the service with your Konnect environment.

<!-- vale off -->
{% konnect_crd %}
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: service
spec:
  name: service
  host: echo.kong.svc.cluster.local
  port: 1027
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

## Create a `KongRoute`

Define a `KongRoute` to expose the Service you created. The Route determines how requests are matched and routed to the associated Service.

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
  - /echo
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: service
{% endkonnect_crd %}
<!-- vale on -->

## Validation

You can validate from the command line or [{{site.konnect_short_name}} UI](/gateway/) to confirm that both the `KongService` and `KongRoute` have been provisioned and are in a valid state:


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