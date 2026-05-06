---
title: 'Single-zone deployment'
description: 'Run {{site.mesh_product_name}} in a single zone with a standalone control plane and interconnected data plane proxies.'
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - deployment-topologies
  - control-plane
  - zones
related_resources:
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
  - text: Mesh DNS
    url: '/mesh/dns/'
min_version:
  mesh: '2.6'
---

This is the simplest deployment mode for {{site.mesh_product_name}}, and the default one. There is one deployment of the control plane that can be scaled horizontally. The data plane proxies connect to the control plane regardless of where they are deployed, and every data plane proxy must be able to connect directly to every other data plane proxy, regardless of where they are deployed.

Single-zone mode is a great choice to start within the context of one zone (for example, within one Kubernetes cluster or one AWS VPC).
You can then [federate](/mesh/federate-zone/) it into a multi-zone deployment.

## Components of a single-zone deployment

A single-zone deployment consists of two components, each with distinct responsibilities:

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibilities
    key: responsibilities
rows:
  - component: Zone control plane
    responsibilities: |
      * Accept connections from data plane proxies.
      * Accept creation and changes to [policies](/mesh/policies/) that apply to data plane proxies.
      * Keep an inventory of all data plane proxies running.
      * Compute and send configurations using XDS to the data plane proxies.
  - component: Data plane proxies
    responsibilities: |
      * Connect to the zone control plane.
      * Receive configurations using XDS from the control plane.
      * Connect to other data plane proxies.
{% endtable %}

## Failure modes

When the zone control plane is offline:

* New data plane proxies can't join the mesh, including new instances (Pod/VM) created by automatic deployment mechanisms such as rolling updates. A control plane connection failure could block application updates.
* On mTLS-enabled meshes, a data plane proxy may fail to refresh its client certificate before it expires (defaults to 24 hours), causing traffic failures.
* Data plane proxy configuration will not be updated.
* Communication between data plane proxies will still work.

{:.info}
> You can think of this failure case as "freezing" the zone mesh configuration.
> Communication still works, but changes are not reflected on existing data plane proxies.

## Limitations

* All data plane proxies need to be able to communicate with every other data plane proxy.
* A single-zone deployment can't mix Universal and Kubernetes workloads.
* A deployment can connect to only one Kubernetes cluster at once.

To avoid these limitations,, see [Multi-zone deployments](/mesh/mesh-multizone-service-deployment/).