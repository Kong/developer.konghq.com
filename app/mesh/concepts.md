---
title: Concepts
content_type: reference
layout: reference
description: Definitions for the core {{site.mesh_product_name}} terminology used across the scenarios, from meshes and zones to xDS, SPIFFE IDs, KRIs, and policy targeting.
breadcrumbs:
  - /mesh/
products:
  - mesh
works_on:
  - on-prem
  - konnect
min_version:
  mesh: '3.0'
tags:
  - glossary
  - service-mesh
  - multi-zone
related_resources:
  - text: Service meshes
    url: /mesh/service-mesh/
  - text: Architecture overview
    url: /mesh/architecture-overview/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Policy targeting and precedence
    url: /mesh/policy-targeting-and-precedence/
---

This page defines the terminology used throughout the {{site.mesh_product_name}} documentation. Each definition is deliberately short and links to the guide that covers the subject in depth.

For a conceptual introduction to what a service mesh is and the problems it solves, see [Service meshes](/mesh/service-mesh/).

## Mesh

A mesh is the top-level resource that represents an isolated service mesh deployment. The mesh is the parent resource for all policies, services, and data planes, which gives it a separate domain of configuration and communication. Workloads in one mesh cannot reach workloads in another mesh except through an explicitly configured external destination.

On Kubernetes, a resource joins a mesh through the `kuma.io/mesh` label. See [Resource scoping](/mesh/resource-scoping/).

## Zone

A zone is a deployment unit that represents a distinct infrastructure environment, typically a Kubernetes cluster, VPC, or data center. All data plane proxies within a zone must be able to reach each other directly. Every zone runs its own zone control plane, and each zone control plane attaches to one global control plane.

A zone is either a Kubernetes zone or a Universal zone, depending on whether workloads run as pods or as processes on VMs and bare metal. Both use the same resource model.

For how zones discover each other's services and route traffic between them, see [Multi-zone architecture](/mesh/multi-zone-architecture/).

## Control plane

The control plane is the management layer of {{site.mesh_product_name}}. It computes the configuration each data plane proxy needs and pushes it out. The control plane does not sit on the path of application traffic, so an unavailable control plane does not by itself stop requests that are already configured.

In 3.0 the control plane is split into two roles. See [Architecture overview](/mesh/architecture-overview/#core-architecture).

### Global control plane

The global control plane holds the central view of the deployment. It owns global resources, provides the inventory of meshes, zones, and workloads, and coordinates the zones. It never connects to a data plane proxy.

### Zone control plane

A zone control plane runs inside one zone. It discovers the workloads running locally, serves them Envoy configuration over xDS, and exchanges supported resources with the global control plane over KDS. If the global control plane becomes unreachable, a zone control plane keeps serving its last known configuration to local proxies.

## Data plane

The data plane handles traffic between services. In practice, the data plane is the set of data plane proxies, or sidecars, that run alongside the applications in your service mesh, plus the zone proxies that carry traffic across zone boundaries.

### Data plane proxy or sidecar

The data plane proxy, or sidecar, is the instance of Envoy that runs alongside one application instance and sends and receives that instance's mesh traffic. The proxy connects to its zone control plane, which computes a configuration specific to it. {{site.mesh_product_name}} ships Envoy inside a binary called `kuma-dp`, and on Kubernetes that binary is injected into the pod as an extra container.

Each proxy is represented in the API by a `Dataplane` resource, which is what policies select when they target workloads.

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

#### Outbound

An outbound is the part of the data plane proxy that sends traffic to servers for a specific destination. Outbounds group multiple remote inbounds as endpoints.

### Transparent proxy

Transparent proxy is the interception mechanism that redirects a workload's inbound and outbound traffic into its sidecar without the application being changed or reconfigured. On Kubernetes it is set up automatically during sidecar injection, which is why in-mesh callers keep using ordinary Kubernetes DNS names such as `check-in-api.kong-air-production.svc.cluster.local`.

### reachableBackends

`reachableBackends` is the list of destinations a data plane proxy declares its workload calls, set through the `kuma.io/reachable-backends` pod annotation on Kubernetes. Each ref selects backends by `kind` and `labels`. The control plane generates outbound configuration only for the declared destinations, and in 3.0 a proxy that declares none reaches nothing, because restricted outbound is on by default. See [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/).

### Zone ingress and zone egress

A zone ingress accepts traffic arriving from another zone and forwards it to a local instance. A zone egress is the outbound hop a zone can use for traffic leaving it, either to another zone or to an external destination.

In 3.0 these are mesh-scoped: each one is an ordinary `Dataplane` resource inside a single mesh rather than a deployment-wide proxy shared by every mesh. They can be selected with the computed labels `kuma.io/listener-zoneingress: enabled` and `kuma.io/listener-zoneegress: enabled`. See [Configure mesh-scoped zone proxies](/mesh/configure-mesh-scoped-zone-proxies/).

### MeshZoneAddress

`MeshZoneAddress` is the resource a zone control plane publishes to advertise the address and port that other zones should dial to reach one mesh's zone ingress. It takes priority over the older deployment-wide `ZoneIngress` resource for any zone that publishes one. See [Multi-zone architecture](/mesh/multi-zone-architecture/).

## Control plane channels

Two protocols carry configuration. Neither carries application traffic.

### xDS

xDS is the Envoy discovery API family that a zone control plane uses to configure its local data plane proxies. Every routing decision, mTLS setting, and authorization rule a proxy enforces arrives over xDS.

### KDS

KDS, the Kuma Discovery Service, is the channel between the global control plane and each zone control plane. Global resources flow down to the zones, and zone-origin resources such as discovered workloads and generated identity material flow up for visibility. KDS synchronization is not symmetric: a resource syncing up to the global control plane does not mean it is installed in every other zone.

## Service model

A service is a destination that callers address by hostname. {{site.mesh_product_name}} represents destinations with three resources.

### MeshService

`MeshService` represents a service inside the mesh. On Kubernetes one is generated for each `Service`, and the port's `appProtocol` becomes the port protocol on the generated resource, which is what makes HTTP-aware behavior such as `MeshHTTPRoute` apply. See [Split traffic with MeshService resources](/mesh/split-traffic-with-meshservice-resources/).

### MeshMultiZoneService

`MeshMultiZoneService` defines one stable destination backed by services that can run in several zones. It is owned by the global control plane, because it needs the service inventory from every zone, and it resolves to a hostname of the form `<name>.mzsvc.mesh.local`. See [Multi-zone architecture](/mesh/multi-zone-architecture/).

### MeshExternalService

`MeshExternalService` represents a destination outside the mesh, such as a SaaS API or a managed database. Traffic to it is deny-by-default at the zone egress listener and is addressed through a generated hostname of the form `<name>.extsvc.mesh.local`. See [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

### HostnameGenerator

`HostnameGenerator` is the resource that decides what hostname a service resource gets. Default generators ship with the control plane. For example, `synced-kube-mesh-service` gives a service synced from another zone the zone-qualified hostname `{% raw %}{{ .DisplayName }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}`.

## Identity and trust

### Identity

A workload's identity is the name encoded in the certificate its proxy presents. An identity is considered valid only if the certificate is signed by a trust the receiving proxy accepts.

Workload identity is connection-scoped and lasts for the lifetime of the workload instance. It identifies the calling service, not the end user whose request that service is handling.

### SPIFFE ID

A SPIFFE ID is the URI form that workload identity takes, carried in the X.509 certificate presented on the mTLS connection. On Kubernetes it encodes the trust domain, the namespace, and the workload's `ServiceAccount`:

```text
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
```
{:.no-copy-code}

`MeshTrafficPermission` authorizes callers by matching on their SPIFFE ID.

### Trust domain

A trust domain is the naming authority a SPIFFE ID belongs to, the part after `spiffe://`. When identity is generated by the built-in provider, the default template is `{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}`, so each zone gets its own trust domain and a zone must be told to trust its peers explicitly.

### Trust

A trust defines which identities you accept as valid. Trust is established through the certificate authorities that issue those identities. A trust is attached to a trust domain, and a mesh can contain multiple trusts.

### MeshIdentity and MeshTrust

`MeshIdentity` configures how workload certificates are issued, through the `Bundled`, `Spire`, or `Extension` provider. `MeshTrust` holds the public CA certificate for a trust domain, so it is the resource you copy between zones to let one zone verify another zone's workloads. See [Manage workload identity and mTLS](/mesh/manage-workload-identity-and-mtls/).

### SNI

SNI is the server name a proxy sends on the TLS connection, and {{site.mesh_product_name}} uses it to carry the intended destination. Policies that match on destination rather than caller match on `sni`. External service traffic uses the form `sni.extsvc.<mesh>.<zone>.<namespace>.<name>.<port>`.

## Resource

A resource is an object you can create, manage, and interact with in {{site.mesh_product_name}}. Resources are the building blocks that define the behavior and state of your service mesh. Each resource is a type of API object with a specific purpose, represented by its state and configuration.

A resource is most often expressed as YAML and can have two formats:

- `Kubernetes` when the backing control plane runs on Kubernetes. In this case, {{site.mesh_product_name}} resources are defined as Kubernetes custom resources.
- `Universal` in other cases, or when you access resources through the {{site.mesh_product_name}} API.

Which control plane owns a given resource, and which namespace it can live in on Kubernetes, is covered in [Resource scoping](/mesh/resource-scoping/).

### Resource labels

Labels carry the identity and provenance of a resource, and policies use them for targeting:

<!-- vale off -->
{% table %}
columns:
  - title: Label
    key: label
  - title: Meaning
    key: meaning
rows:
  - label: "`kuma.io/mesh`"
    meaning: "The mesh the resource belongs to."
  - label: "`kuma.io/zone`"
    meaning: "The zone the resource was discovered or created in."
  - label: "`kuma.io/origin`"
    meaning: "`global` or `zone`, recording which control plane created the resource. A zone control plane connected to a global control plane requires `zone` on resources created locally."
  - label: "`kuma.io/policy-role`"
    meaning: "`system`, `producer`, `consumer`, or `workload-owner`. Used when breaking ties between policies of equal specificity."
  - label: "`k8s.kuma.io/namespace`"
    meaning: "The Kubernetes namespace the resource came from."
{% endtable %}
<!-- vale on -->

### KRI

A KRI, the {{site.mesh_product_name}} Resource Identifier, is the stable string that names one resource across the whole deployment. It has the form:

```text
kri_<shortName>_<mesh>_<zone>_<namespace>_<name>_<sectionName>
```
{:.no-copy-code}

For example, the identity resource `kong-air-identity` in `kong-air-mesh` in `zone1` is:

```text
kri_mid_kong-air-mesh_zone1_kong-mesh-system_kong-air-identity_
```
{:.no-copy-code}

The trailing underscore is the empty `sectionName`. Short names are per resource type, for example `dp` for `Dataplane`, `mid` for `MeshIdentity`, `mtrust` for `MeshTrust`, and `mza` for `MeshZoneAddress`. KRIs appear in control plane inspection output, which makes them the quickest way to confirm that a resource you created is the one a proxy is actually using.

## Policy

Policies are the resources that control the behavior and communication of applications running inside your service mesh. They cover traffic management, security, observability, and reliability. For the full catalog, see [Mesh policies](/mesh/policies/).

### targetRef

`targetRef` is the shared selector structure every policy uses to say what it applies to. A top-level `targetRef` picks the workloads the policy attaches to, and a `to[]` or `from[]` entry narrows the configuration to a specific destination or source. Policies express their settings through `default`, or through `rules[]` where the policy needs per-caller decisions.

When more than one policy matches the same proxy, specificity and then label-based tie-breakers decide which one wins. See [Policy targeting and precedence](/mesh/policy-targeting-and-precedence/) and [Target workloads and services](/mesh/target-workloads-and-services/).

### sectionName

`sectionName` narrows a `targetRef` to one named part of the target rather than the whole resource, such as a single listener on a zone proxy or a single port on a service. It is also the last field of a KRI, which is why most KRIs end in an underscore.
