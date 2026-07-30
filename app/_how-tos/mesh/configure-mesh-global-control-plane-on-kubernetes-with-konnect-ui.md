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
  inline:
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster-lb
    - title: kubectl
      content: |
        Install and configure [`kubectl`](https://kubernetes.io/docs/tasks/tools/) to connect to your cluster.
related_resources:
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} API
    url: /mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} API
    url: /mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/
  - text: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
    url: /mesh/deploy-kong-mesh-using-terraform-and-konnect/
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

## Create a global control plane in {{site.konnect_short_name}}

Before you can add services or apply configurations, you must create a global control plane.

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **Create a service mesh**.
1. In the **Name** field, enter `example-cp`.
1. Click **Save**.

The global control plane is now created but has no functionality until you connect a zone.

## Create a zone in the global control plane

Add a zone to connect services and receive configuration updates.

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Click **Create zone**.
1. Select **Kubernetes** as the configuration type.
1. In the **Name** field, enter `zone-1`.

   {:.info}
   > The zone name must use lowercase alphanumeric characters or hyphens, and start and end with an alphanumeric character.

1. In the **Token** field, enter your {{site.konnect_short_name}} personal access token.
1. Follow the Helm and token setup instructions shown in the UI to deploy the zone control plane on your Kubernetes cluster.

   {{site.konnect_short_name}} automatically provisions a [system account access token](#how-does-a-zone-authenticate-to-the-global-control-plane) for the zone and injects it, along with the control plane ID and address, into the deployment instructions. You don't need to create a token manually.
1. Once the zone is connected, click **Continue**.

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
