---
title: "{{site.mesh_product_name}} data plane proxy"
description: Understand data plane proxy components, Dataplane entities, inbounds, outbounds, tags, and how proxies receive configuration.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - data-plane

related_resources:
  - text: 'Data plane on Kubernetes'
    url: '/mesh/data-plane-kubernetes/'
  - text: 'Data plane on Universal'
    url: '/mesh/data-plane-universal/'
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
  - text: Zone ingress
    url: /mesh/zone-ingress/
  - text: Configure data plane proxy membership
    url: /mesh/configure-data-plane-proxy-membership/
---

A data plane proxy (DPP), also known as a sidecar, is the part of {{site.mesh_product_name}} that runs next to each workload that is a member of the mesh.
A DPP is composed of the following components:
* A `Dataplane` entity defines the configuration of the DPP.
* A `kuma-dp` binary runs on each instance that is part of the mesh. This binary spawns the following subprocesses:
  * `Envoy` receives configuration from the control plane to manage traffic correctly.
  * `core-dns` resolves {{site.mesh_product_name}} specific DNS entries.

Each service instance runs its own `kuma-dp` instance.

## Concepts

The following sections define the core elements of the data plane proxy configuration.

### Inbound

An inbound defines the port exposed for each workload. It consists of:
* The port the workload listens on.
* A set of [tags](#tags).

A DPP typically exposes a single inbound. When a workload exposes multiple ports, multiple inbounds can be defined.

### Tags
Tags are a set of key-value pairs that are defined for each DPP inbound. These tags can serve the following purposes:
* Specifying the service this DPP inbound is part of.
* Adding metadata about the exposed service.
* Allowing subsets of DPPs to be selected by these tags.

Tags prefixed with `kuma.io` are reserved:
* `kuma.io/service` identifies the service name. On Kubernetes this tag is automatically created, while on Universal it must be specified manually. This tag must always be present.
* `kuma.io/zone` identifies the zone name in a [multi-zone deployment](/mesh/mesh-multizone-service-deployment/). This tag is automatically created and cannot be overwritten.
* `kuma.io/protocol` identifies the protocol of the service exposed by this inbound. Accepted values are `tcp`, `http`, `http2`, `grpc` and `kafka`.

### Service
A service is a group of all DPP inbounds that have the same `kuma.io/service` tag.

### Outbounds
An outbound allows the workload to consume a service in the mesh using a local port.
Outbounds are not required when using [transparent proxying](/mesh/transparent-proxying/). 

## `Dataplane` entity

The `Dataplane` entity consists of:

* The IP address used by other DPPs to connect to this DPP
* The inbounds configuration
* The outbounds configuration

A `Dataplane` entity must be present for each DPP. `Dataplane` entities are managed differently depending on the environment: 
* On [Kubernetes](/mesh/data-plane-kubernetes/), the control plane automatically generates the `Dataplane` entity. 
* On [Universal](/mesh/data-plane-universal/), the user defines the `Dataplane` entity. 
 
## Dynamic configuration of the data plane proxy 

When the DPP runs:
* The `kuma-dp` retrieves the Envoy startup configuration from the control plane.
* The `kuma-dp` process starts Envoy with this configuration.
* Envoy connects to the control plane using XDS and receives configuration updates when the state of the mesh changes.

The control plane uses policies and `Dataplane` entities to generate the DPP configuration. 

### Data plane proxy ports


When you start a data plane via `kuma-dp`, you expect all the inbound and outbound service traffic to go through it. The inbound and outbound ports are defined in the data plane specification when running in Universal mode, while on Kubernetes the service-to-service traffic always runs on port `15001`.

In addition to the service traffic ports, the data plane proxy also opens the following TCP ports:

* `9901`: The HTTP server that provides the `Envoy` [administration interface](https://www.envoyproxy.io/docs/envoy/latest/operations/admin), It's bound onto the loop-back interfaces, and can be customized using these methods:
    * On Universal: The data field `networking.admin.port` on the data plane object.
    * On Kubernetes: The Pod annotation `kuma.io/envoy-admin-port`.
* `9000`: The HTTP server that provides the [virtual probes](/mesh/annotations/#kuma-io-virtual-probes) functionalities (in version 2.8 and earlier). It is automatically enabled on Kubernetes. On Universal, it needs to be enabled explicitly.
* {% new_in 2.9 %} `9902`: An internal HTTP server that reports the readiness of current data plane proxy. This server is consumed by the `/ready` endpoint of the Envoy Admin API. It can be customized using these methods:
    * On Universal: The environment variable `KUMA_READINESS_PORT` on the data plane host.
    * On Kubernetes: `KUMA_READINESS_PORT` as part of the value of environment variable `KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_ENV_VARS`.
* {% new_in 2.9 %} `9001`: The HTTP server that provides the [application probe proxy](/mesh/annotations/#kuma-io-application-probe-proxy-port) functionalities. It can be customized using these methods:
    * On Universal: The environment variable `KUMA_APPLICATION_PROBE_PROXY_PORT`. 
    * On Kubernetes: The Pod annotation `kuma.io/application-probe-proxy-port`.

## Schema

{% json_schema Dataplane type=proto %}
