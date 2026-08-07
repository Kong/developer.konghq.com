---
title: Configure a {{site.mesh_product_name}} global control plane on Kubernetes with the {{site.konnect_short_name}} UI
content_type: how_to
permalink: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-ui/
breadcrumbs:
  - /mesh/
description: 'Use the {{site.konnect_short_name}} UI to create a global control plane, add a zone, deploy the Kubernetes demo app, and test your {{site.mesh_product_name}} mesh.'
products:
  - mesh
works_on:
  - konnect
tags:
  - service-mesh
tldr:
  q: How do I configure a {{site.mesh_product_name}} global control plane and zone with the {{site.konnect_short_name}} UI?
  a: In the {{site.konnect_short_name}} UI, navigate to **Service Mesh** create a global control plane, then create a zone and follow the wizard to deploy the zone control plane using the system account access token that {{site.konnect_short_name}} provisions for you. Create a default mesh and deploy workloads with `kubectl`.
prereqs:
  skip_product: true
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster-lb
    - title: kubectl
      content: |
        Install and configure [`kubectl`](https://kubernetes.io/docs/tasks/tools/) to connect to your cluster.
related_resources:
  - text: "{{site.mesh_product_name}} in {{site.konnect_short_name}}"
    url: /mesh/konnect/
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} API
    url: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} API
    url: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} UI
    url: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-ui/
  - text: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
    url: /mesh/deploy-mesh-using-terraform-and-konnect/
next_steps:
  - text: Enable traffic permissions with the MeshTrafficPermission policy
    url: /mesh/policies/meshtrafficpermission/
cleanup:
  inline:
    - title: Remove the demo application
      include_content: cleanup/mesh/remove-demo-app
    - title: Uninstall the zone control plane
      include_content: cleanup/mesh/uninstall-zone-cp
    - title: Delete the control plane in {{site.konnect_short_name}}
      include_content: cleanup/mesh/delete-konnect-control-plane-ui
faqs:
  - q: How does a zone authenticate to the global control plane?
    a: |
      {% include faqs/mesh-zone-authentication.md %}
  - q: How do I configure kumactl to connect to the global control plane?
    a: |
      {% include faqs/mesh-configure-kumactl.md %}
---

Using the {{site.konnect_short_name}} UI, you can create a global control plane, connect a Kubernetes zone, and manage your {{site.mesh_product_name}} mesh. This guide creates a global control plane, adds a zone, creates a mesh, deploys the demo application, and validates traffic through the mesh using the {{site.konnect_short_name}} UI.

To run your zone control plane on a VM or bare metal instead, see [Configure a {{site.mesh_product_name}} global control plane on Universal with the {{site.konnect_short_name}} UI](/mesh/configure-mesh-global-control-plane-on-universal-with-konnect-ui/).

## Create a global control plane in {{site.konnect_short_name}}

{% include how-tos/mesh/create-global-control-plane-ui.md %}

## Create a zone in the global control plane

{% include how-tos/mesh/create-zone-ui.md config_type="Kubernetes" deploy_instruction="Follow the Helm and token setup instructions shown in the UI to deploy the zone control plane on your Kubernetes cluster." %}

## Create a mesh

Workloads can only join the mesh once a mesh exists on the global control plane. Create the `default` mesh:

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**, then click **Meshes**.
1. Click **Create mesh**.
1. In the **Name** field, enter `default`.
1. Click **Create**.

## Deploy the demo application

{% include how-tos/mesh/deploy-demo-app.md %}

## Validate

{% include how-tos/mesh/validate-mesh-zone.md %}
