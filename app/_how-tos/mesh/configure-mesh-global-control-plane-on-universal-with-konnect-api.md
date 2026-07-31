---
title: Configure a {{site.mesh_product_name}} global control plane on Universal with the {{site.konnect_short_name}} API
content_type: how_to
permalink: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/
breadcrumbs:
  - /mesh/
description: 'Use the Konnect API to create a global control plane and zone token, then deploy a Universal zone control plane that connects to Konnect.'
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
  q: How do I configure a {{site.mesh_product_name}} global control plane and a Universal zone with the {{site.konnect_short_name}} API?
  a: Create a global control plane and a system account zone token with the {{site.konnect_short_name}} API, then deploy a Universal (VM or bare metal) zone control plane that connects to the {{site.konnect_short_name}}-managed global control plane.
related_resources:
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} UI
    url: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-ui/
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} API
    url: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} UI
    url: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-ui/
  - text: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
    url: /mesh/deploy-mesh-using-terraform-and-konnect/
next_steps:
  - text: Explore {{site.mesh_product_name}} policies
    url: /mesh/policies/
cleanup:
  inline:
    - title: Stop the zone control plane
      content: |
        Stop the background zone control plane started in this guide:

        ```sh
        pkill -f kuma-cp
        ```
    - title: Delete the {{site.konnect_short_name}} control plane
      include_content: cleanup/mesh/delete-konnect-control-plane-api
    - title: Remove the working directory
      include_content: cleanup/mesh/remove-working-directory
faqs:
  - q: How does a zone authenticate to the global control plane?
    a: |
      {% include faqs/mesh-zone-authentication.md %}
---

Using the {{site.konnect_short_name}} API, you can create a global control plane that {{site.konnect_short_name}} manages while you run your zone control planes on Universal (VMs or bare metal). This guide creates a global control plane, provisions a zone token, and deploys a Universal zone control plane that connects to {{site.konnect_short_name}}.

To deploy services and test traffic across the mesh, see [Configure a {{site.mesh_product_name}} global control plane on Kubernetes with the {{site.konnect_short_name}} API](/mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/).

## Create a global control plane in {{site.konnect_short_name}}

{% include how-tos/mesh/create-global-control-plane-api.md %}

## Generate a zone token

{% include how-tos/mesh/generate-zone-token-api.md %}

## Create a zone in the global control plane

With the token created, deploy the zone control plane on your machine:

{% include how-tos/mesh/deploy-zone-cp-universal.md zone_name="zone-1" show_exports=true %}

## Validate

{% include how-tos/mesh/validate-zone-online.md %}
