---
title: Architecture

description: |
  How does {{ site.kic_product_name }} work? Which Kubernetes resources does it interact with?

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Gateway API
    url: /kubernetes-ingress-controller/gateway-api/
  - text: Ingress
    url: /kubernetes-ingress-controller/ingress/
---

The {{site.kic_product_name}} configures {{site.base_gateway}} using Ingress or [Gateway API](https://gateway-api.sigs.k8s.io/) resources created inside a Kubernetes cluster.

{{site.kic_product_name}} enables you to configure plugins, load balance the services, check the health of the Pods, and leverage all that Kong offers in a standalone installation.

{:.info}
> The {{ site.kic_product_name }} does not proxy any traffic directly. It configures {{ site.base_gateway }} using Kubernetes resources.

The figure illustrates how {{site.kic_product_name}} works:

<!--vale off-->
{% mermaid %}
flowchart LR
    subgraph Kubernetes cluster
        direction LR
        A(<img src="/assets/icons/kubernetes.svg" style="max-width:25px; display:block; margin:0 auto;" /> API server) --> |events| B(<img src="/assets/icons/KogoBlue.svg" style="max-width:25px; display:block; margin:0 auto;" />Controller)
        B --> |configuration| C(<img src="/assets/icons/KogoBlue.svg" style="max-width:25px; display:block; margin:0 auto;"/>Kong)
        C --> D(services)
    end

    E(Request traffic)
    E --> C

    %% Change the arrow colors
    linkStyle 0,1 stroke:#d44324,color:#d44324  
    linkStyle 2,3 stroke:#b6d7a8
{% endmermaid %}
<!--vale on-->

The Controller listens for changes inside the Kubernetes cluster and dynamically updates {{site.base_gateway}} in response to those changes. 
In this setup, {{site.base_gateway}} can respond to changes around scaling, configuration, and failures that occur inside a Kubernetes cluster in real time.

For more information on how {{site.base_gateway}} works with Routes, Gateway Services, and Upstreams,
please see the [proxy](/gateway/traffic-control/proxying/) and [load balancing](/gateway/load-balancing/) documentation.

## Kubernetes resources

In Kubernetes, there are several concepts that are used to logically identify workloads and route traffic between them.

### Service / Pods

A [Service](https://kubernetes.io/docs/concepts/services-networking/service/) inside Kubernetes is a way to abstract an application that is running on a set of Pods. This maps to two objects in {{site.base_gateway}}: Gateway Service and Upstream.

The Gateway Service object in {{site.base_gateway}} holds the information of the protocol needed to talk to the upstream service and various other protocol-specific settings. The Upstream object defines load balancing and health-checking behavior.

Each Kubernetes Service is defined as an Upstream in {{site.base_gateway}}. Each Pod associated with the Kubernetes Service is added as a Target within the Upstream. {{site.base_gateway}} load balances across the Pods of your service. This means that **all requests flowing through {{site.base_gateway}} are not directed through kube-proxy but directly to the Pod**.


### Gateway API

Gateway API resources can also be used to produce running instances and configurations for {{site.base_gateway}}.

The main concepts of the Gateway API are:

- A [Gateway](https://gateway-api.sigs.k8s.io/concepts/api-overview/#gateway) resource in Kubernetes describes how traffic
  can be translated to services within the cluster.
- A [GatewayClass](https://gateway-api.sigs.k8s.io/concepts/api-overview/#gatewayclass) defines a set of Gateways that share
  a common configuration and behaviour.
  Each GatewayClass is handled by a single controller, although controllers
  may handle more than one GatewayClass.
- [HTTPRoute](/kubernetes-ingress-controller/routing/http/) can be attached to a Gateway which
  configures the HTTP routing behavior.

For more information about Gateway API resources and features supported by {{site.kic_product_name}}, see
[Gateway API](/kubernetes-ingress-controller/gateway-api).


### Ingress

An [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resource in Kubernetes defines a set of rules for proxying traffic. These rules correspond to the concept of a Route in {{site.base_gateway}}.

The following diagram describes the relationship between Kubernetes concepts and Kong's Ingress configuration. The colored boxes represent Kong concepts, and the outer boxes represent Kubernetes concepts.

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
    
    subgraph Ingress / Gateway API
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
{% endmermaid %}
<!--vale on-->

