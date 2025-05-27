---
title: Database backed

description: "Use {{ site.kic_product_name }} to configure a {{ site.base_gateway }} Control Plane that is attached to a PostgreSQL database."
  

content_type: reference
layout: reference

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Deployment Topologies

products:
  - kic
search_aliases:
  - kic PostgreSQL
works_on:
  - on-prem
  - konnect

related_resources:
  - text: Gateway Discovery
    url: /kubernetes-ingress-controller/deployment-topologies/gateway-discovery/
  - text: Sidecar (Traditional)
    url: /kubernetes-ingress-controller/deployment-topologies/sidecar/
  - text: Architecture
    url: /kubernetes-ingress-controller/architecture/
---


Database backed deployments are when {{ site.kic_product_name }} is used to update a Lua control plane that is attached to a PostgreSQL database. {{ site.base_gateway }} may be deployed in either [Traditional](/gateway/traditional-mode/) or [Hybrid](/gateway/hybrid-mode/) mode.

Both [Gateway Discovery](/kubernetes-ingress-controller/deployment-topologies/gateway-discovery/) and [Sidecar](/kubernetes-ingress-controller/deployment-topologies/sidecar/) deployments can be used alongside a database. If you're starting a greenfield project today we recommend using Gateway Discovery.

{:.warning}
> Database backed deployments should only be used in a small set of circumstances. We recommend using [Gateway Discovery](/kubernetes-ingress-controller/deployment-topologies/gateway-discovery/) unless you've been otherwise advised by a member of the Kong team.

## Traditional mode

Traditional mode is when every {{ site.base_gateway }} instance acts as both a Control Plane and a Data Plane. All nodes connect to the database and load the latest configuration at a regular interval.

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

subgraph B[" "]
  KIC1
  KIC2
  KIC3
  note[Deployment with
leader election]
end

subgraph C[" "]
DB
DP1
DP2
DP3
DP4
end

KIC1 --> DP1
DP1 --> DB[(Config 
database)]
DB --> DP2 & DP3 & DP4

style B stroke-dasharray: 5 5
style C stroke:none,fill:none
style note stroke:none,fill:none
{% endmermaid %}
<!--vale on-->

{{ site.kic_product_name }} sends configuration to a random {{ site.base_gateway }} instance, which writes the configuration to the database. All other nodes read the configuration from the database.

## Hybrid mode

Database backed Hybrid mode is similar to Traditional mode, but instead of every node reading from the database a single Control Plane is responsible for managing the configuration and distributing it to all active Data Planes.

In Hybrid mode, {{ site.kic_product_name }} uses Gateway Discovery to find the Control Plane and send {{ site.base_gateway }} configuration to the Admin API. This configuration is persisted to the PostgreSQL database and transmitted to the Data Planes using the {{ site.base_gateway }} CP/DP protocol.

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
CP[<img src="/assets/icons/gateway.svg" style="max-height:20px"> Control Plane]
DP1[<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data Plane]
DP2[<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data Plane]
DP3[<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data Plane]
DB[(Config 
database)]

A-.KIC watches 
API server.-KIC1

subgraph B[" "]
  KIC1
  KIC2
  KIC3
  note[Deployment with
leader election]
end

subgraph C[" "]
  DP1
  DP2
  DP3
end

KIC1 --> CP
CP --> DP1 & DP2 & DP3
CP --> DB

style B stroke-dasharray: 5 5
style C stroke-dasharray: 5 5
style note stroke:none,fill:none

{% endmermaid %}
<!--vale on-->