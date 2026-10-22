---
title: Connect a Kubernetes zone to {{site.konnect_short_name}} with the UI
content_type: how_to
permalink: "/mesh/connect-kubernetes-zone-to-konnect-ui/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a {{site.mesh_product_name}} 3.x global control plane in {{site.konnect_short_name}} and connect a Kubernetes zone.
products:
- mesh
works_on:
- konnect
tools:
- kongctl
tags:
- service-mesh
tldr:
  q: How do I connect a Kubernetes zone to {{site.konnect_short_name}} for {{site.mesh_product_name}} 3.x?
  a: Create a new global control plane running v3, deploy a 3.x zone control plane
    with its {{site.konnect_short_name}} credentials, and verify that the zone connects. Then configure
    `MeshIdentity` and `MeshTrafficPermission` and test an application request.
prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
related_resources:
- text: Installation options
  url: "/mesh/konnect/"
- text: "{{site.mesh_product_name}} 3.x CLI"
  url: "/mesh/cli/"
- text: MeshIdentity
  url: "/mesh/policies/meshidentity/"
next_steps:
- text: Apply traffic policies
  url: "/mesh/policy-targeting/"
cleanup:
  inline:
    - title: Remove the Kubernetes zone
      include_content: cleanup/products/mesh/v3/kubernetes-zone
    - title: Delete the control plane
      include_content: cleanup/products/mesh/v3/control-plane-ui
    - title: Delete the system account
      include_content: cleanup/products/mesh/v3/system-account-ui
min_version:
  mesh: '3.0'
---

This guide creates a {{site.konnect_short_name}}-managed global control plane, connects a Kubernetes zone, and verifies that one application can call another only with the permitted identity.


## Create the global control plane

{% include md/mesh/v3/how-tos/create-global-control-plane-ui.md %}

## Add the zone

{% include md/mesh/v3/how-tos/add-zone-ui.md platform="kubernetes" %}

## Validate

{% include md/mesh/v3/how-tos/verify-zone-connection-ui.md %}
