---
title: Configure a {{site.mesh_product_name}} global control plane on Universal with the {{site.konnect_short_name}} UI
content_type: how_to
permalink: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-ui/
breadcrumbs:
  - /mesh/
description: 'Use the {{site.konnect_short_name}} UI to create a global control plane and connect a Universal zone control plane.'
products:
  - mesh
works_on:
  - konnect
tags:
  - service-mesh
tldr:
  q: How do I configure a {{site.mesh_product_name}} global control plane and a Universal zone with the {{site.konnect_short_name}} UI?
  a: In the {{site.konnect_short_name}} UI, create a global control plane from **Service Mesh**, then create a zone with the **Universal** configuration type and follow the steps shown in the UI to deploy the zone control plane on your VM or bare metal machine.
related_resources:
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} UI
    url: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-ui/
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} API
    url: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} API
    url: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/
  - text: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
    url: /mesh/deploy-mesh-using-terraform-and-konnect/
next_steps:
  - text: Explore {{site.mesh_product_name}} policies
    url: /mesh/policies/
cleanup:
  inline:
    - title: Stop the zone control plane
      content: |
        Stop the zone control plane running on your machine:

        ```sh
        pkill -f kuma-cp
        ```
    - title: Delete the control plane in {{site.konnect_short_name}}
      include_content: cleanup/mesh/delete-konnect-control-plane-ui
    - title: Remove local files
      content: |
        Remove the files and binaries created during setup:

        ```sh
        rm -rf ~/kuma-cp kong-mesh-*
        ```
faqs:
  - q: How does a zone authenticate to the global control plane?
    a: |
      {% include faqs/mesh-zone-authentication.md %}
---

Using {{site.konnect_short_name}} UI, you can create a global control plane and connect a Universal (VM or bare metal) zone. This guide creates a global control plane and connects a Universal zone control plane using the {{site.konnect_short_name}} UI.

To deploy services and test traffic across the mesh, see [Configure a {{site.mesh_product_name}} global control plane on Kubernetes with the {{site.konnect_short_name}} UI](/mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-ui/).

## Create a global control plane in {{site.konnect_short_name}}

{% include how-tos/mesh/create-global-control-plane-ui.md %}

## Create a zone in the global control plane

{% include how-tos/mesh/create-zone-ui.md config_type="Universal" deploy_instruction="Follow the steps shown in the UI to deploy the zone control plane on your machine." %}

## Validate

{% include how-tos/mesh/validate-zone-online.md %}
