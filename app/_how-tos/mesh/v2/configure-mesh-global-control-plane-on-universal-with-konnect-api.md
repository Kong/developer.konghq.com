---
title: Configure a {{site.mesh_product_name}} global control plane on Universal with the {{site.konnect_short_name}} API
content_type: how_to
permalink: /mesh/v2/configure-mesh-global-control-plane-on-universal-with-konnect-api/
breadcrumbs:
  - /mesh/v2/
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
  - text: "{{site.mesh_product_name}} in {{site.konnect_short_name}}"
    url: /mesh/v2/konnect/
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} UI
    url: /mesh/v2/configure-mesh-global-control-plane-on-kubernetes-with-konnect-ui/
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} API
    url: /mesh/v2/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} UI
    url: /mesh/v2/configure-mesh-global-control-plane-on-universal-with-konnect-ui/
  - text: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
    url: /mesh/v2/deploy-mesh-using-terraform-and-konnect/
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
      include_content: md/mesh/v2/cleanup/delete-konnect-control-plane-api
    - title: Remove the working directory
      include_content: md/mesh/v2/cleanup/remove-working-directory
faqs:
  - q: How does a zone authenticate to the global control plane?
    a: |
      {% include md/mesh/v2/faqs/zone-authentication.md %}
major_version:
  mesh: 2

---

Using the {{site.konnect_short_name}} API, you can create a global control plane that {{site.konnect_short_name}} manages while you run your zone control planes on Universal (VMs or bare metal). This guide creates a global control plane, provisions a zone token, and deploys a Universal zone control plane that connects to {{site.konnect_short_name}}.

To deploy services and test traffic across the mesh, see [Configure a {{site.mesh_product_name}} global control plane on Kubernetes with the {{site.konnect_short_name}} API](/mesh/v2/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/).

## Create a global control plane in {{site.konnect_short_name}}

{% include md/mesh/v2/how-tos/create-global-control-plane-api.md %}

## Generate a zone token

{% include md/mesh/v2/how-tos/generate-zone-token-api.md %}

## Create a zone in the global control plane

With the token created, deploy the zone control plane on your machine:

{% include md/mesh/v2/how-tos/deploy-zone-cp-universal.md zone_name="zone-1" show_exports=true %}

## Validate

{% include md/mesh/v2/how-tos/validate-zone-online.md %}
