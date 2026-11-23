---
title: Concepts
description: 'Understand the core concepts of {{ site.mesh_product_name }}, including the control plane, data plane proxies, inbounds and outbounds, and resources like policies.'
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/v2/

tags:
  - glossary

related_resources:
  - text: Service meshes
    url: '/mesh/v2/service-mesh/'
  - text: Policies
    url: '/mesh/v2/policies-introduction/'
  - text: Mesh architecture
    url: /mesh/v2/architecture/
  - text: Install {{ site.mesh_product_name }}
    url: /mesh/v2/#install-kong-mesh
min_version:
  mesh: '2.7'
major_version:
  mesh: 2

---

This page defines core concepts in {{ site.mesh_product_name }}.

## Mesh

A mesh is the top-level resource that represents an isolated service mesh deployment. The mesh serves as the parent resource for all policies, services, and data planes, providing a separate domain of configuration and communication.

For more information, see the [Mesh resource reference](/mesh/v2/mesh/).

## Zone

A zone is a deployment unit that represents a distinct infrastructure environment, typically a Kubernetes cluster, VPC, or data center. All data plane proxies within a zone must be able to communicate with each other. {{ site.mesh_product_name }} supports [multi-zone deployments](/mesh/v2/mesh-multizone-service-deployment/) where zones can span different regions, clouds, or data centers while remaining part of the same mesh. Multi-zone deployments enable automatic service discovery and failover across zones.

For more information, see the [single-zone](/mesh/v2/single-zone/) and [multi-zone deployment](/mesh/v2/mesh-multizone-service-deployment/) references.

## Control plane

The control plane is the central management layer of {{ site.mesh_product_name }}. The control plane configures and manages the behavior of the data plane, which handles the actual traffic between services.

For more information, see the [control plane configuration reference](/mesh/v2/control-plane-configuration/).

## Data plane

The data plane handles traffic between services. In practice, the data plane consists of the data plane proxies, or sidecars, that run alongside the applications in your service mesh.

For more information, see the [{{ site.mesh_product_name }} architecture reference](/mesh/v2/architecture/).

### Data plane proxy / sidecar

The data plane proxy, or sidecar, is the instance of Envoy that runs alongside the application and sends and receives traffic from the rest of the service mesh. The proxy connects to the control plane, which computes a configuration specific to it.

For more information, see the [data plane proxy reference](/mesh/v2/data-plane-proxy/).

<!-- vale off -->
{% mermaid %}

flowchart LR
Clients
Servers

subgraph Data plane
App
subgraph Data plane proxy
Inbounds
Outbounds
end
end

Inbounds -.Local traffic.-> App
App -.Local traffic.-> Outbounds

Clients --> Inbounds
Outbounds --> Servers

{% endmermaid %}
<!-- vale on -->

#### Inbound

An inbound is the part of the data plane proxy that receives traffic from clients for a specific port. Inbounds are usually grouped across different data planes to form a service.

For more information, see [Inbounds in the data plane proxy reference](/mesh/v2/data-plane-proxy/#inbound).

#### Outbound

An outbound is the part of the data plane proxy that sends traffic to servers for a specific service. Outbounds group multiple remote inbounds as endpoints.

For more information, see [Outbounds in the data plane proxy reference](/mesh/v2/data-plane-proxy/#outbounds).

## Resource

A resource is an object or entity that you can create, manage, and interact with in {{ site.mesh_product_name }}. Resources are the building blocks that define the behavior and state of your service mesh. Each resource is a type of API object that has a specific purpose and is represented by its state and configuration.

A resource is most often expressed as YAML and can have two formats:

- `Kubernetes` when the backing control plane runs on Kubernetes. In this case, {{ site.mesh_product_name }} resources are defined as Kubernetes Custom Resource Definitions.
- `Universal` in other cases or when you access resources through the {{ site.mesh_product_name }} REST API.

### Policy

Policies are a specific type of resource that controls the behavior and communication of applications running inside your service mesh. Policies can enable traffic management, security, observability, and traffic reliability.

For more information, see the [policies introduction](/mesh/v2/policies-introduction/).

### Identity

A workload's identity is the name encoded in its certificate. An identity is considered valid only if the certificate is signed by a trust.

### Trust

A trust defines which identities you accept as valid. Trust is established through trusted certificate authorities (CAs) that issue those identities. A trust is attached to a trust domain, and a cluster can contain multiple trusts.
