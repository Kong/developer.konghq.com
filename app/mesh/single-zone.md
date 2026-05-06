---
title: 'Single-zone deployment'
description: 'Run {{site.mesh_product_name}} in a single zone with a standalone Control Plane and interconnected Data Plane proxies.'
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
  - text: Get started with Red Hat OpenShift
    url: /mesh/openshift-quickstart/
min_version:
  mesh: '2.6'
---

This is the simplest deployment mode for {{site.mesh_product_name}}, and the default one.

* **Zone control plane**: There is one deployment of the control plane that can be scaled horizontally.
* **Data plane proxies**: The data plane proxies connect to the control plane regardless of where they are deployed.
* **Service Connectivity**: Every data plane proxy must be able to connect to every other data plane proxy regardless of where they are being deployed.

This mode implies that we can deploy {{site.mesh_product_name}} and its data plane proxies so that the service connectivity from every data plane proxy can be established directly to every other data plane proxy.

Single-zone mode is a great choice to start within the context of one zone (ie: within one Kubernetes cluster or one AWS VPC).
You can then [federate](/mesh/federate-zone/) it into a multi-zone deployment.

To install with this topology follow the [install {{site.mesh_product_name}}](/mesh/#install-kong-mesh) docs.

## Limitations

* All data plane proxies need to be able to communicate with every other dataplane proxy.
* A single-zone deployment cannot mix Universal and Kubernetes workloads.
* A deployment can connect to only one Kubernetes cluster at once.

If these limitations are problematic you should look at [Multi-zone deployments](/mesh/mesh-multizone-service-deployment/).

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
      * Accept creation and changes to [policies](/mesh/policies/) that will be applied to the data plane proxies.
      * Keep an inventory of all data plane proxies running.
      * Compute and send configurations using XDS to the data plane proxies.
  - component: Data plane proxies
    responsibilities: |
      * Connect to the zone control plane.
      * Receive configurations using XDS from the control plane.
      * Connect to other data plane proxies.
{% endtable %}

## Failure modes

The following table describes how {{site.mesh_product_name}} behaves when the zone control plane becomes unavailable:

{% table %}
columns:
  - title: Failure mode
    key: mode
  - title: Impact
    key: impact
  - title: What still works
    key: still_works
rows:
  - mode: Zone control plane offline
    impact: |
      * New data plane proxies can't join the mesh, including new instances (Pod/VM) created by automatic deployment mechanisms such as rolling updates — a control plane connection failure could block application updates.
      * On mTLS-enabled meshes, a data plane proxy may fail to refresh its client certificate before it expires (defaults to 24 hours), causing traffic failures.
      * Data plane proxy configuration won't be updated.
    still_works: |
      * Communication between data plane proxies.
{% endtable %}

{:.info}
> You can think of this failure case as "freezing" the zone mesh configuration.
> Communication still works, but changes are not reflected on existing data plane proxies.
