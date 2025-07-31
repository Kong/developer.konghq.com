---
title: Gateway Discovery

description: |
  Use one {{ site.kic_product_name }} instance to configure multiple {{ site.base_gateway }} instances. Gateway Discovery is Kong's recommended deployment topology for the {{ site.kic_product_name }}. 

content_type: reference
layout: reference

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Deployment Topologies

products:
  - kic

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Database backed
    url: /kubernetes-ingress-controller/deployment-topologies/db-backed/
  - text: Sidecar (Traditional)
    url: /kubernetes-ingress-controller/deployment-topologies/sidecar/
  - text: Architecture
    url: /kubernetes-ingress-controller/architecture/
next_steps:
  - text: Get started with {{site.kic_product_name}}
    url: /kubernetes-ingress-controller/install/
---

Gateway Discovery is a deployment topology in which {{ site.kic_product_name }} and {{ site.base_gateway }} are separate deployments in the Kubernetes cluster. {{ site.kic_product_name }} uses Kubernetes service discovery to discover the {{ site.base_gateway }} Pods.

It allows you to manage many {{ site.base_gateway }} instances with one {{ site.kic_product_name }}, providing lower resource usage compared to [Sidecar](/kubernetes-ingress-controller/deployment-topologies/sidecar/) deployments.

## How it works

{:.info}
> You don't need to configure this manually due to the default value of `gatewayDiscovery.generateAdminApiService=true` in the Helm chart. The following information is for educational purposes only.

When {{ site.kic_product_name }} starts running it looks for services that match the name in the `--kong-admin-svc` flag. This value is controlled by the `gatewayDiscovery.adminApiService.namespace` and `gatewayDiscovery.adminApiService.name` values in the Helm chart. Once the service is found, {{ site.kic_product_name }} fetches a list of [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/) containing all {{ site.base_gateway }} instances.

{{ site.kic_product_name }} proceeds to send configuration to all detected {{ site.base_gateway }} instances using the `POST /config` endpoint on each running Data Plane. Once the Data Plane has loaded configuration, it is marked as ready and can start proxying traffic.

<!--vale off-->
{% mermaid %}
flowchart LR

A[<img src="/assets/icons/kubernetes.svg" style="max-height:20px"> API Server]
KIC1[<img src="/assets/icons/gateway.svg" style="max-height:20px"> KIC 
&lpar;Active&rpar;]
KIC2[<img src="/assets/icons/gateway.svg" style="max-height:20px"> KIC
&lpar;Standby&rpar;]
KIC3[<img src="/assets/icons/gateway.svg" style="max-height:20px"> KIC
&lpar;Standby&rpar;]
DP1[<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data Plane]
DP2[<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data Plane]
DP3[<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data Plane]
DP4[<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data Plane]

A-.KIC watches 
API server.- KIC1

subgraph B["Deployment with
leader election"]
subgraph C[" "]
  KIC1
end
  KIC2
  KIC3
end

KIC1 ----> DP1 & DP2 & DP3 & DP4

style B stroke-dasharray: 5 5
style C stroke:none,fill:none

{% endmermaid %}
<!--vale on-->

> _**Figure 1**: In a Gateway discovery deployment, one active {{ site.kic_product_name }} instance sends configuration to many {{site.base_gateway}}s, which are scaled independently. Multiple KIC instances can be run for high availability requirements._