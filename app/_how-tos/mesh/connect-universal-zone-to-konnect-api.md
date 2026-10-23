---
title: Connect a Universal zone to {{site.konnect_short_name}} with the API
content_type: how_to
permalink: "/mesh/connect-universal-zone-to-konnect-api/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a {{site.mesh_product_name}} 3.x global control plane in {{site.konnect_short_name}} and connect a Universal
  zone.
products:
- mesh
works_on:
- konnect
tools:
- konnect-api
tags:
- service-mesh
search_aliases:
- quickstart
tldr:
  q: How do I connect a Universal zone to {{site.konnect_short_name}} for {{site.mesh_product_name}} 3.x?
  a: Create a new global control plane running v3, deploy a 3.x zone control plane
    with its {{site.konnect_short_name}} credentials, and verify that the zone connects.
prereqs:
  inline:
    - title: A VM or bare-metal host
      content: |
        A supported VM or bare-metal host.
related_resources:
- text: Installation options
  url: "/mesh/konnect/"
- text: "{{site.mesh_product_name}} 3.x CLI"
  url: "/mesh/cli/"
- text: MeshIdentity
  url: "/mesh/policies/meshidentity/"
next_steps:
- text: Register Universal application proxies
  url: "/mesh/universal-data-plane/"
cleanup:
  inline:
    - title: Stop the zone control plane
      include_content: cleanup/products/mesh/v3/universal-zone
    - title: Delete the control plane
      include_content: cleanup/products/mesh/v3/control-plane-api
    - title: Delete the system account
      include_content: cleanup/products/mesh/v3/system-account-api
min_version:
  mesh: '3.0'
---

This guide creates a {{site.konnect_short_name}}-managed global control plane and connects a Universal (VM or bare-metal) zone.


## Create a global control plane in {{site.konnect_short_name}}

{% include md/mesh/v3/how-tos/create-global-control-plane.md %}

## Give the zone credentials to connect

{% include md/mesh/v3/how-tos/give-zone-credentials.md %}

## Deploy the zone control plane

{% include md/mesh/v3/how-tos/deploy-zone-control-plane.md platform="universal" %}

## Validate

{% include md/mesh/v3/how-tos/verify-zone-connection-kongctl.md %}
