---
title: Configure a {{site.mesh_product_name}} global control plane on Kubernetes with the {{site.konnect_short_name}} API
content_type: how_to
permalink: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/
breadcrumbs:
  - /mesh/
description: 'Use the {{site.konnect_short_name}} API to create a global control plane, provision a zone token, deploy the Kubernetes demo app, and test your {{site.mesh_product_name}} mesh.'
products:
  - mesh
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - service-mesh
tldr:
  q: How do I configure a {{site.mesh_product_name}} global control plane and zone with the {{site.konnect_short_name}} API?
  a: Create a global control plane with a request to the Mesh control planes API, then provision a zone by creating a system account access token with the `Connector` role and deploying a zone control plane with it. Deploy workloads with `kubectl` and use `kumactl` for read-only visibility.
prereqs:
  inline:
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster-lb
    - title: kubectl
      content: |
        Install and configure [`kubectl`](https://kubernetes.io/docs/tasks/tools/) to connect to your cluster.
related_resources:
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} UI
    url: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-ui/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} API
    url: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} UI
    url: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-ui/
  - text: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
    url: /mesh/deploy-with-terraform-konnect/
next_steps:
  - text: Enable traffic permissions with the MeshTrafficPermission policy
    url: /mesh/policies/meshtrafficpermission/
cleanup:
  inline:
    - title: Remove the demo application
      include_content: cleanup/mesh/remove-demo-app
    - title: Uninstall the zone control plane
      include_content: cleanup/mesh/uninstall-zone-cp
    - title: Delete the {{site.konnect_short_name}} control plane
      include_content: cleanup/mesh/delete-konnect-control-plane-api
faqs:
  - q: How does a zone authenticate to the global control plane?
    a: |
      {% include faqs/mesh-zone-authentication.md %}
  - q: How do I configure kumactl to connect to the global control plane?
    a: |
      {% include faqs/mesh-configure-kumactl.md %}
---

Using the {{site.konnect_short_name}} API, you can create a global control plane, connect a Kubernetes zone, and manage your {{site.mesh_product_name}} mesh. This guide creates a global control plane, provisions a zone token, deploys a zone control plane and the demo application, and validates traffic through the mesh.

To run your zone control plane on a VM or bare metal instead, see [Configure a {{site.mesh_product_name}} global control plane on Universal with the {{site.konnect_short_name}} API](/mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/).

## Create a global control plane in {{site.konnect_short_name}}

{% include how-tos/mesh/create-global-control-plane-api.md %}

## Generate a zone token

{% include how-tos/mesh/generate-zone-token-api.md %}

## Create a zone in the global control plane

With the token created, deploy the zone control plane on your Kubernetes cluster:

{% include how-tos/mesh/deploy-zone-cp-kubernetes.md zone_name="zone-1" show_exports=true %}

Once the zone control plane is running, it connects to the global control plane and appears in {{site.konnect_short_name}}.

## Deploy the demo application

{% include how-tos/mesh/deploy-demo-app.md %}

## Validate

{% include how-tos/mesh/validate-mesh-zone.md %}
