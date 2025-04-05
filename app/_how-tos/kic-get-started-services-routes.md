---
title: Services and Routes
description: |
  Use the Gateway API and HTTPRoute to configure a Service and a Route.
content_type: how_to

permalink: /kubernetes-ingress-controller/services-and-routes/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Get Started

tldr:
  q: How do I create a Service and a Route with {{ site.kic_product_name }}
  a: |
    Create a HTTPRoute that points to a Kubernetes service in your cluster.

products:
  - kic

works_on:
  - on-prem
  - konnect

prereqs:
  skip_product: true
  expand_accordion: false
---

## How Kubernetes resources map to Kong Entities

A Service inside Kubernetes is a way to abstract an application that is running on a set of Pods. This maps to two objects in Kong: Service and Upstream.

The service object in Kong holds the information of the protocol to use to talk to the upstream service and various other protocol specific settings. The Upstream object defines load-balancing and health-checking behavior.

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

    classDef lightBlue fill:#cce7ff;
    classDef lightGreen fill:#c4e1c4;
    classDef lightPurple fill:#e6d8eb;
    classDef lightGrey fill:#f5f5f5;

    class A,B lightGreen;
    class C lightBlue;
    class D lightPurple;
    class E,F,G lightGrey;

    linkStyle 6 stroke:#b6d7a8
{% endmermaid %}
<!--vale on-->

Routes are configured using Gateway API or Ingress resources, such as `HTTPRoute`, `TCPRoute`, `GRPCRoute`, `Ingress` and more.

## Deploy an echo service

In this guide, you will deploy an `echo` service which returns information about the Kubernetes cluster and route traffic to the service.

```bash
kubectl apply -f {{ site.links.web }}/manifests/kic/echo-service.yaml
```

## Create a HTTPRoute / Ingress

{% include /k8s/httproute.md release=page.release path='/echo' name='echo' service='echo' port='1027' skip_host=true %}

## Validate your configuration

Once the resource has been reconciled, you'll be able to call the `/echo` endpoint and {{ site.base_gateway }} will route the request to the `echo` service.

{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
