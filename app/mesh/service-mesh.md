---
title: Service meshes
description: Overview of service mesh concepts and how {{site.mesh_product_name}} simplifies secure and reliable service-to-service communication using sidecar proxies and a control plane.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - control-plane
  - data-plane

related_resources:
  - text: "{{site.mesh_product_name}} architecture"
    url: /mesh/architecture/
  - text: "{{site.mesh_product_name}} observability"
    url: /mesh/observability/
  - text: "{{site.mesh_product_name}} policies"
    url: /mesh/policies-introduction/
  - text: "{{site.mesh_product_name}} concepts"
    url: /mesh/concepts/
---

A service mesh is a technology pattern that provides a way to implement modern networking and connectivity among the different services that make up an application. While it's commonly used in the context of microservices, it can be used to improve connectivity in every architecture and on every platform, such as VMs and containers.

When a service wants to communicate with another service over the network, like a monolith talking to a database or a microservice talking to another microservice, by default the connectivity among them is unreliable. The network can be slow, unsecure by default, and those network requests are not logged anywhere in case you need to debug an error.

In order to implement some of these functionalities, you have two options:

* You can extend your applications yourself to address these concerns. Over time, this creates technical debt and more code to maintain in addition to the business logic that your application delivers to the end-user. It also creates fragmentation and security issues as more teams try to address the same concerns on different technology stacks.
* You can delegate the network management to something else that does it for you. For example, an out-of-process proxy that runs on the same underlying host. This proxy is called a [data plane proxy](/mesh/data-plane-proxy/), or sidecar.

In the latter scenario, when delegating network management to another process, you have a data plane proxy for each replica of every service. This is required so you can tolerate a failure to one of the proxies without affecting other replicas, and also because you can assign an identity to each proxy and therefore to each replica of your services. It's also important that the data plane proxy is very lightweight since you'll have many instances running.

While having data plane proxies deployed alongside your services helps with the network concerns described above, managing so many data plane proxies can become challenging. When you want to update your network policies, you don't want to manually reconfigure each one of them. You need a source of truth that can collect all of your configuration, segmented by service or other properties, and then push the configuration to the individual data plane proxies whenever required. This component is called the [control plane](/mesh/control-plane-configuration/). It controls the proxies and, unlike the proxies, it doesn't sit on the execution path of the service traffic.

{% mermaid %}
flowchart TB
    U[User]
    subgraph CP[Control plane]
        C[Configuration]
        P[Policies]
        M[Monitoring]
    end
    subgraph H1[Host/VM/Pod]
        DP1[Data plane proxy]
        S1[Service]
        S1 <--> DP1
    end
    subgraph H2[Host/VM/Pod]
        DP2[Data plane proxy]
        S2[Service]
        S2 <--> DP2
    end

    U --> CP
    CP <---> DP1 & DP2
{% endmermaid %}

You'll have many proxies connected to the control plane in order to always propagate the latest configuration, while simultaneously processing the service-to-service traffic among your infrastructure. 
{{site.mesh_product_name}} includes a control plane (shipped in a `kuma-cp` binary) and Envoy as a data plane proxy (shipped as an `envoy` binary). 
You don't need to learn to use Envoy to use {{site.mesh_product_name}}, because {{site.mesh_product_name}} abstracts away that complexity by bundling Envoy into another binary called `kuma-dp`. Under the hood, `kuma-dp` invokes the `envoy` binary.