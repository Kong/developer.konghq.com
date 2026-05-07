---
title: Concepts
description: 'Understand the core concepts of {{ site.mesh_product_name }}, including the Control Plane, Data Plane proxies, inbounds and outbounds, and resources like policies.'
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - glossary

related_resources:
  - text: Service meshes
    url: '/mesh/service-mesh/'
  - text: Mesh Policies
    url: '/mesh/policies-introduction/'
  - text: Mesh architecture
    url: /mesh/architecture/
  - text: Install Kong Mesh
    url: /mesh/#install-kong-mesh

min_version:
  mesh: '2.7'
---

In this page we will introduce concepts that are core to understanding {{ site.mesh_product_name }}.

## Mesh

A mesh is the top-level resource that represents an isolated service mesh deployment. It serves as the parent resource for all policies, services, and data planes, providing a separate domain of configuration and communication.

## Zone

A zone is a deployment unit representing a distinct infrastructure environment—typically a Kubernetes cluster, VPC, or data center. All data plane proxies within a zone must be able to communicate with each other. {{ site.mesh_product_name }} supports [multi-zone deployments](/mesh/mesh-multizone-service-deployment/) where zones can span different regions, clouds, or data centers while remaining part of the same mesh. This enables automatic service discovery and fail-over across zones.

## Control plane

The control plane is the central management layer of {{ site.mesh_product_name }}. It is responsible for configuring and managing the behavior of the data plane,
which handles the actual traffic between services.

## Data plane

The data plane handles traffic between services.
In practice these are the apps that you build and that you want to put inside your service mesh.

### Data plane proxy / sidecar

The data plane proxy or sidecar is the instance of Envoy running alongside the application which will send and receive traffic from the rest of the service mesh.
It connects to the control plane which computes a configuration specific to it.

<!-- vale off -->
{% mermaid %}

flowchart LR
clients
servers

subgraph data plane
app
subgraph data plane proxy/Envoy
inbounds
outbounds
end
end

inbounds -.local traffic.-> app
app -.local traffic.-> outbounds

clients --> inbounds
outbounds --> servers

{% endmermaid %}
<!-- vale on -->

#### Inbound

An inbound is the part of the data plane proxy which receives traffic for a specific port.
Inbounds are usually grouped between different data planes and form a service.

#### Outbound

An outbound is the part of the data plane proxy which sends traffic for a specific service.
Outbounds group multiple remote inbounds as endpoints.

## Resource

A resource is an object or entity that can be created, managed, and interacted with in {{ site.mesh_product_name }}.
Resources are the building blocks that define the behavior and state of your service mesh.
Each resource is defined as a type of API object that has a specific purpose and is represented by its state and configuration.

A resource is most often expressed as YAML and can have 2 formats:

- `Kubernetes` when the backing control plane runs on Kubernetes. In this case {{ site.mesh_product_name }} resources are defined as Kubernetes Custom Resource Definitions.
- `Universal` in other cases or when accessing resources through {{ site.mesh_product_name }}'s REST API.

Resources are most commonly represented in YAML format.

### Policy

Policies are a specific type of resources that controls the behavior and communication of applications running inside your service mesh.
They can enable traffic management, security, observability and traffic reliability.

Policies always have a clear specific area of impact and goal.
To learn more about [policies checkout the in depth introduction](/mesh/policies-introduction/).

### Identity

Who a workload is—a workload's identity is the name encoded in its certificate, and this identity is considered valid only if the certificate is signed by a Trust.

### Trust

Who to believe - Trust defines which identities you accept as valid, and is established through trusted certificate authorities <!-- vale off -->(CAs)<!-- vale on --> that issue those identities. Trust is attached to trust domain, and there can be multiple Trusts in the cluster.
