---
title: 'How ingress works'
description: 'Overview of how ingress (north/south) traffic flows through delegated and built-in gateways in {{site.mesh_product_name}}, with visuals and key differences.'
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.6'

related_resources:
  - text: Built-in gateways
    url: '/mesh/built-in-gateway/'
  - text: Delegated gateways
    url: '/mesh/ingress-gateway-delegated/'
  - text: Data plane proxy
    url: '/mesh/data-plane-proxy/'
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'

---

{{site.mesh_product_name}} provides two features to manage ingress traffic, also known as north/south traffic.
Both take advantage of a piece of infrastructure called a _gateway proxy_, that
sits between external clients and your services in the mesh.

- [Delegated gateway](/mesh/ingress-gateway-delegated/): allows users to use any existing gateway proxy, like [Kong](https://github.com/Kong/kong).
- [Built-in gateway](/mesh/built-in-gateway/): configures instances of Envoy to act as a gateway.

{:.warning}
> Gateways exist within a `Mesh`.
> If you have multiple `Meshes`, each `Mesh` requires its own gateway. You can easily connect your `Meshes` together using [cross-mesh gateways](/mesh/gateway-listeners/#cross-mesh).

The below visualization shows the difference between delegated and built-in gateways. The blue lines represent traffic not managed by {{site.mesh_product_name}}.

Built-in, with Kong Gateway at the edge:

<center>
<img src="/assets/images/diagrams/builtin-gateway.webp" alt=""/>
</center>

Delegated Kong Gateway:

<center>
<img src="/assets/images/diagrams/delegated-gateway.webp" alt="" />
</center>
