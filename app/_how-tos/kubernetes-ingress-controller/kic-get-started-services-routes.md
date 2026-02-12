---
title: Services and Routes
description: |
  Use the an HTTPRoute or Ingress to configure a Service and a Route.
content_type: how_to

permalink: /kubernetes-ingress-controller/get-started/services-and-routes/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Get Started

series:
  id: kic-get-started
  position: 2

tldr:
  q: How do I create a Service and a Route with {{ site.kic_product_name }}?
  a: |
    Create an HTTPRoute that points to a Kubernetes service in your cluster.

products:
  - kic

works_on:
  - on-prem
  - konnect

prereqs:
  skip_product: true
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

Routes are configured using Gateway API or Ingress resources, such as `HTTPRoute`, `TCPRoute`, `GRPCRoute`, `Ingress` and more.

## Deploy an echo service

Let's start by deploying an `echo` service which returns information about the Kubernetes cluster:

```bash
kubectl apply -f {{ site.links.web }}/manifests/kic/echo-service.yaml -n kong
```

## Create an HTTPRoute / Ingress

To route traffic to the `echo` service, create an `HTTPRoute` or `Ingress` resource:


<!--vale off-->
{% httproute %}
matches:
  - path: /echo
    service: echo
    port: 1027
skip_host: true
{% endhttproute %}
<!--vale on-->

## Validate your configuration

Once the resource has been reconciled, you can call the `/echo` endpoint and {{ site.base_gateway }} will route the request to the `echo` service:

{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
