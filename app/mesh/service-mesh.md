---
title: Service meshes
content_type: reference
layout: reference
description: What a service mesh is, the problems it solves, and how {{site.mesh_product_name}} uses sidecar proxies and a control plane to deliver it.
breadcrumbs:
  - /mesh/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tags:
  - service-mesh
  - control-plane
  - data-plane
related_resources:
  - text: Concepts
    url: /mesh/concepts/
  - text: Architecture overview
    url: /mesh/architecture-overview/
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Mesh policies
    url: /mesh/policies/
---
A service mesh is a pattern for connecting the services that make up an application.
Teams often use it with microservices, but it works for any architecture and on any platform, such as virtual machines (VMs) and containers.

## Why services need a mesh

Services call each other over the network.
For example, a monolith calls a database, or one microservice calls another.
Without help, these calls are hard to run safely: the network can be slow or fail, the traffic isn't encrypted, and nothing logs the requests when you need to debug an error.

You can solve these problems in two ways:

* In each application: Each team adds retries, encryption, and logging to its own code. Over time, this adds code to maintain beside the business logic. Teams also solve the same problems differently on different technology stacks, which creates gaps in security.
* In a proxy next to each application: A separate process on the same host handles the network for the application. This process is a [data plane proxy](/mesh/concepts/#data-plane-proxy-or-sidecar), also called a sidecar.

With the second approach, every replica of every service gets its own data plane proxy.
When one proxy fails, the other replicas keep working.
With a [MeshIdentity](/mesh/policies/meshidentity/), each proxy also presents a certificate with the identity of its workload, so the mesh can authenticate every caller.
The proxies must be lightweight, because you run many of them.

## Why the proxies need a control plane

You don't want to manually reconfigure every proxy when a network policy changes.
A [control plane](/mesh/architecture-overview/#core-architecture) stores the configuration and sends it to each proxy that needs it.
The control plane manages the proxies, but it doesn't carry service traffic.

{% mermaid %}
flowchart TB
    U[User]
    subgraph CP[Control plane]
        C[Configuration]
        P[Policies]
        M[Status]
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
    DP1 <-.->|Service traffic| DP2
{% endmermaid %}

Many proxies connect to the control plane to receive the latest configuration, and they carry the traffic between your services.

{{site.mesh_product_name}} includes a control plane, `kuma-cp`, and uses Envoy as the data plane proxy.
You don't need to learn Envoy.
The `kuma-dp` binary starts and configures Envoy for you.
On Kubernetes, you don't start `kuma-dp` yourself.
When a namespace or Pod has the `kuma.io/sidecar-injection: enabled` label, the control plane adds `kuma-dp` to each new Pod as a sidecar container.

## How {{site.mesh_product_name}} implements a service mesh

{{site.mesh_product_name}} runs a zone control plane in each environment. For multi-zone deployments, the zones connect to a global control plane:

* Global control plane: It stores the central view of your meshes and resources.
* Zone control plane: Each environment where workloads run, such as a Kubernetes cluster, a VPC, or a data center, runs one. It finds the local workloads and sends them Envoy configuration over xDS. It exchanges resources with the global control plane over the Kuma Discovery Service (KDS).

For more information, see [Architecture overview](/mesh/architecture-overview/).

Neither control plane carries traffic.
When a request goes to a service in another zone, the caller's sidecar sends it to the zone ingress of that zone.
A zone ingress is a data plane proxy with a zone ingress listener, deployed for each mesh.
For more information, see [Multi-zone architecture](/mesh/multi-zone-architecture/).

For the terms used in the {{site.mesh_product_name}} documentation, such as xDS, KDS, SPIFFE IDs, and the service and policy resources, see [Concepts](/mesh/concepts/).
