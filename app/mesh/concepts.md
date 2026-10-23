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
This page defines the terms that the {{site.mesh_product_name}} documentation and the Kong Air scenarios use.
Each definition is short and links to the page that covers the subject in depth.

For what a service mesh is and the problems it solves, see [Service meshes](/mesh/service-mesh/).

## Mesh

A mesh is the top-level resource for one isolated service mesh.
Every policy, service, and data plane proxy belongs to one mesh, so each mesh has its own configuration and traffic.
A workload in one mesh can reach a workload in another mesh only through an external destination that you configure.

On Kubernetes, a resource joins a mesh through the `kuma.io/mesh` label.
For more information, see [Resource scoping](/mesh/resource-scoping/).

## Zone

A zone is one infrastructure environment, usually a Kubernetes cluster, a VPC, or a data center.
All data plane proxies in a zone must be able to reach each other directly.
Each zone runs its own zone control plane.
In a multi-zone deployment, each zone control plane connects to one global control plane.

A zone is a Kubernetes zone or a Universal zone, depending on whether the workloads run as Pods or as processes on VMs and bare metal.
Both kinds of zone use the same resources.
For the differences, see [{{site.mesh_product_name}} on Universal](/mesh/universal/).

For how zones find each other's services and route traffic between them, see [Multi-zone architecture](/mesh/multi-zone-architecture/).

## Control plane

The control plane is the management layer of {{site.mesh_product_name}}.
It computes the configuration that each data plane proxy needs and sends it to the proxy.
The control plane doesn't carry application traffic, so when it's unavailable, the proxies keep handling requests with their last configuration.

For more information, see [Architecture overview](/mesh/architecture-overview/#core-architecture).

### Global control plane

The global control plane holds the central view of a multi-zone deployment.
It stores global resources, keeps an inventory of meshes, zones, and workloads, and coordinates the zones.
It never connects to a data plane proxy.

### Zone control plane

A zone control plane runs in one zone.
It finds the local workloads, sends them Envoy configuration over xDS, and exchanges resources with the global control plane over KDS.
If the global control plane is unreachable, the zone control plane keeps the global resources that it last received and keeps configuring its local proxies.

## Data plane

The data plane carries the traffic between services.
It's made of the data plane proxies (sidecars) that run next to the applications, and of the zone proxies that carry traffic between zones.

### Data plane proxy or sidecar

A data plane proxy, or sidecar, is an Envoy instance that runs next to one application instance.
It sends and receives the mesh traffic of that instance.
The proxy connects to its zone control plane, which computes the configuration for that proxy.
The `kuma-dp` binary starts and configures Envoy.
On Kubernetes, sidecar injection adds `kuma-dp` to the Pod as a native sidecar container.

In the API, a `Dataplane` resource represents each proxy, and policies select proxies through it.

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

An inbound is the part of a data plane proxy that receives traffic from clients on one port.
A service usually groups the inbounds of several data plane proxies.

#### Outbound

An outbound is the part of a data plane proxy that sends traffic to one destination.
An outbound uses the inbounds of the destination's proxies as its endpoints.

### Transparent proxy

A transparent proxy redirects the inbound and outbound traffic of a workload into its sidecar, without any change to the application.
On Kubernetes, sidecar injection sets it up.
As a result, callers in the mesh keep using ordinary Kubernetes DNS names, such as `check-in-api.kong-air-production.svc.cluster.local`.

### reachableBackends

`reachableBackends` lists the destinations that a workload calls.
On Kubernetes, you set it with the `kuma.io/reachable-backends` Pod annotation.
The control plane generates outbound configuration only for these destinations.
With the default `restrictOutbound` setting, a proxy without `reachableBackends` reaches no destination.
The Kong Air control plane sets `restrictOutbound` to false, so its proxies reach every destination until the production scenario turns it on.

Each entry selects destinations by `kind` and `labels`.
`kind` accepts `MeshService`, `MeshMultiZoneService`, and `MeshExternalService`, so one list covers services in the zone, services in several zones, and external dependencies.
`labels: {}` selects every destination of that kind.
On Kubernetes, the control plane rejects an annotation entry without `labels`.

For more information, see [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/).

### Zone ingress and zone egress

A zone ingress accepts traffic from other zones and forwards it to a local instance of the service.
A zone egress sends traffic from its zone to external destinations, which `MeshExternalService` resources describe.
Cross-zone traffic goes from the caller's sidecar directly to the remote zone ingress.
It doesn't pass through a zone egress.

Zone proxies are mesh-scoped: each one is an ordinary `Dataplane` resource in one mesh.
The control plane adds the `kuma.io/listener-zoneingress: enabled` and `kuma.io/listener-zoneegress: enabled` labels to them, and policies select them with these labels.
For more information, see [Mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/).

### MeshZoneAddress

A `MeshZoneAddress` publishes the address and port that other zones use to reach the zone ingress of one mesh.
On Kubernetes, the zone control plane creates it from the zone ingress Service.
On Universal, you create it on the zone control plane.
For more information, see [Make ingress reachable from other zones](/mesh/mesh-scoped-zone-proxies/#make-ingress-reachable-from-other-zones).

## Control plane channels

Two protocols carry configuration.
Neither carries application traffic.

### xDS

xDS is the family of Envoy discovery APIs.
A zone control plane uses it to configure its local data plane proxies.
Every routing decision, mTLS setting, and authorization rule that a proxy applies arrives over xDS.

### KDS

The Kuma Discovery Service (KDS) connects the global control plane with each zone control plane.
Global resources flow from the global control plane to the zones.
Zone resources, such as discovered workloads and generated identity material, flow from the zones to the global control plane.
A resource that a zone sends to the global control plane doesn't always reach the other zones.
For example, a `MeshTrust` that a zone generates stays on the global control plane.

## Service model

A service is a destination that callers reach by hostname.
{{site.mesh_product_name}} describes destinations with three resources.

### MeshService

A `MeshService` describes a service inside the mesh.
On Kubernetes, the zone control plane generates one from each `Service`.
The `appProtocol` of each port becomes the protocol of that port, which lets HTTP features such as `MeshHTTPRoute` apply.
For more information, see [MeshService](/mesh/meshservice/).

### MeshMultiZoneService

A `MeshMultiZoneService` defines one destination for a service that runs in several zones.
You create it on the global control plane, because only the global control plane has the services of every zone.
Callers reach it with a hostname of the form `NAME.mzsvc.mesh.local`.
For more information, see [MeshMultiZoneService](/mesh/meshmultizoneservice/).

### MeshExternalService

A `MeshExternalService` describes a destination outside the mesh, such as a SaaS API or a managed database.
Callers reach it with a hostname of the form `NAME.extsvc.mesh.local`, and the traffic leaves through the zone egress.
The zone egress denies this traffic until a `MeshTrafficPermission` allows it.
For more information, see [MeshExternalService](/mesh/meshexternalservice/).

### HostnameGenerator

A `HostnameGenerator` decides the hostname of each service resource.
The control plane creates default generators.
For example, `synced-kube-mesh-service` gives a Kubernetes service from another zone the hostname `{% raw %}{{ .DisplayName }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}`.

## Identity and trust

### Identity

A workload's identity is the name in the certificate that its proxy presents.
The receiving proxy accepts the identity only if a certificate authority (CA) that it trusts signed the certificate.

A workload identity belongs to the connection and lasts as long as the workload instance.
It identifies the calling service, not the end user whose request the service handles.

### SPIFFE ID (Secure Production Identity Framework for Everyone)

A SPIFFE ID is the URI form of a workload identity.
The proxy presents it in the X.509 certificate of the mTLS connection.
On Kubernetes, it contains the trust domain, the namespace, and the workload's `ServiceAccount`:

```text
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
```
{:.no-copy-code}

`MeshTrafficPermission` allows or denies callers by their SPIFFE ID.
For more information, see [SPIFFE ID](/mesh/policies/meshidentity/#spiffe-id).

### Trust domain

A trust domain is the part of a SPIFFE ID after `spiffe://`.
By default, the trust domain is `{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}`, so each zone has its own trust domain.
You then configure each zone to trust the other zones.

### Trust

A trust defines which identities a proxy accepts.
The CAs that issue those identities establish the trust.
Each trust belongs to one trust domain, and a mesh can have several trusts.

### MeshIdentity and MeshTrust

A `MeshIdentity` configures how workloads get their certificates, with the `Bundled`, `Spire`, or `Extension` provider.
A `MeshTrust` holds the public CA certificate of one trust domain.
To let one zone verify the workloads of another zone, you copy the other zone's `MeshTrust`.
For more information, see [MeshIdentity](/mesh/policies/meshidentity/) and [MeshTrust](/mesh/policies/meshtrust/).

### SNI

The server name indication (SNI) is the server name that a proxy sends when it opens a TLS connection.
{{site.mesh_product_name}} uses it to carry the destination of the request.
A `MeshTrafficPermission` on a zone egress matches the destination by its `sni`.
For a `MeshExternalService` that you create on a Kubernetes zone, the SNI has the form `sni.extsvc.MESH.ZONE.NAMESPACE.NAME.PORT`.
On a Universal zone, the SNI has no namespace, and for a resource from the global control plane, it has neither zone nor namespace.

## Resource

A resource is an object that you create and manage in {{site.mesh_product_name}}.
Resources define the behavior and state of the service mesh.
Each resource type is an API object with one purpose.

You usually write a resource in YAML, in one of two formats:

- **Kubernetes**: The resource is a Kubernetes custom resource, which you apply on a Kubernetes zone.
- **Universal**: You apply the resource through the {{site.mesh_product_name}} API or `kongctl`, on a Universal zone or the global control plane.

For which control plane owns a resource, and which namespaces accept it on Kubernetes, see [Resource scoping](/mesh/resource-scoping/).

### Resource labels

The control plane uses labels to record where a resource comes from, and policies use labels to select resources:

<!-- vale off -->
{% table %}
columns:
  - title: Label
    key: label
  - title: Meaning
    key: meaning
rows:
  - label: "`kuma.io/mesh`"
    meaning: "The mesh that the resource belongs to."
  - label: "`kuma.io/zone`"
    meaning: "The zone where the control plane found or created the resource."
  - label: "`kuma.io/origin`"
    meaning: "`global` or `zone`: the control plane that created the resource. The control plane sets it, and you don't need to."
  - label: "`kuma.io/policy-role`"
    meaning: "`system`, `producer`, `consumer`, or `workload-owner`. The control plane sets it. It decides which proxies a policy can reach, and which policy wins when several apply."
  - label: "`k8s.kuma.io/namespace`"
    meaning: "The Kubernetes namespace that the resource came from."
{% endtable %}
<!-- vale on -->

### KRI

A Kuma Resource Identifier (KRI) is a stable string that names one resource across the whole deployment.
It has the following form:

```text
kri_TYPE_MESH_ZONE_NAMESPACE_NAME_SECTION
```
{:.no-copy-code}

For example, the KRI of the `MeshIdentity` named `kong-air-identity`, in `kong-air-mesh` and `zone1`, is:

```text
kri_mid_kong-air-mesh_zone1_kong-mesh-system_kong-air-identity_
```
{:.no-copy-code}

The trailing underscore is the empty `sectionName`.
`TYPE` is a short name for the resource type, for example `dp` for `Dataplane`, `mid` for `MeshIdentity`, `mtrust` for `MeshTrust`, and `mza` for `MeshZoneAddress`.
KRIs appear in the inspection output of the control plane, so you can use them to confirm that a proxy uses the resource that you created.

## Policy

Policies control how the applications in the mesh behave and communicate.
They cover traffic management, security, observability, and reliability.
For the full list, see [Mesh policies](/mesh/policies/).

### targetRef

`targetRef` is the selector that every policy uses:

* The top-level `spec.targetRef` selects the proxies that receive the policy.
* A `targetRef` in a `spec.to[]` entry selects a destination for the traffic that those proxies send.

A policy that configures received traffic uses `spec.rules[]` instead, and each rule matches the callers.
When several policies of the same type apply to the same proxy, the control plane merges them by priority.
For more information, see [Policy targeting](/mesh/policy-targeting/) and [Policy targeting and precedence](/mesh/policy-targeting-and-precedence/).

### sectionName

`sectionName` narrows a `targetRef` to one named part of the target, such as one listener of a zone proxy or one port of a service.
It's also the last field of a KRI, which is why most KRIs end with an underscore.
