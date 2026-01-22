---
title: Service Discovery
description: Learn how data plane proxies connect to the control plane and discover Service endpoints for traffic routing.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.6'

related_resources:
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
  - text: DNS
    url: /mesh/dns/
---

This page explains how communication between the components of {{site.mesh_product_name}} handles Service traffic. Communication is handled between the data plane proxy (`kuma-dp`) and the control plane (`kuma-cp`), and between multiple instances of the data plane proxy.

When a data plane proxy connects to the control-plane, it initiates a gRPC streaming connection to the control plane. It retrieves the latest policy configuration from the control plane and sends diagnostic information to the control plane.

In [single-zone mode](/mesh/single-zone/) the `kuma-dp` process connects directly to the `kuma-cp` instances.

In a [multi-zone deployment](/mesh/mesh-multizone-service-deployment/) the `kuma-dp` processes will connect to the zone control plane, while the zone control planes will connect to the global control plane over an extension of the xDS API that we have built called "KDS" ({{site.mesh_product_name}} Discovery Service). In multi-zone mode, the data plane proxies never connect to the global control plane but only to the zone ones.

{:.info}
> The connection between the data-planes and the control-plane is not on the execution path of the Service requests, which means that if the data plane temporarily loses connection to the control-plane the Service traffic won't be affected.

While doing so, the data-planes also advertise the IP address of each Service. The IP address is retrieved:

* On Kubernetes by looking at the address of the Pod.
* On Universal by looking at the inbound listeners that have been configured in the [`inbound` property](/mesh/data-plane-universal/#dataplane-resource-configuration) of the data plane specification.

The IP address that's being advertised by every data plane to the control-plane is also being used to route Service traffic from one `kuma-dp` to another `kuma-dp`. This means that {{site.mesh_product_name}} knows at any given time what are all the IP addresses associated to every replica of every Service. Another use-case where the IP address of the data-planes is being used is for metrics scraping by Prometheus.

{{site.mesh_product_name}} already ships with its own [DNS](/mesh/dns/). 

Connectivity among the `kuma-dp` instances can happen in two ways:

* In single-zone mode `kuma-dp` processes communicate with each other in a flat networking topology. This means that every data plane must be able to consume another data plane by directly sending requests to its IP address. In this mode, every `kuma-dp` must be able to send requests to every other `kuma-dp` on the specific ports that govern Service traffic, as described in the `kuma-dp` [ports section](/mesh/data-plane-proxy/#data-plane-proxy-ports).
* In multi-zone mode connectivity is being automatically resolved by {{site.mesh_product_name}} to either a data plane running in the same zone, or through the address of a [zone egress proxy](/mesh/zone-egress/) (if present) and [zone ingress proxy](/mesh/zone-ingress/) in another zone for cross-zone connectivity. This means that multi-zone connectivity can be used to connect services running in different clusters, platforms or clouds in an automated way. {{site.mesh_product_name}} also creates a `.mesh` zone via its native DNS resolver. The automatically created `kuma.io/zone` tag can be used with {{site.mesh_product_name}} policies in order to determine how traffic flows across a multi-zone setup.

{:.info}
> By default cross-zone connectivity requires [mTLS](/mesh/policies/mutual-tls/) to be enabled on the [mesh](/mesh/mesh-multi-tenancy/) with the appropriate [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) to enable the flow of traffic. Otherwise, unsecured traffic won't be permitted outside each zone.
