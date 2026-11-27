---
title: Configure a {{site.mesh_product_name}} global control plane on Kubernetes with the {{site.konnect_short_name}} API
content_type: how_to
permalink: /mesh/v2/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/
breadcrumbs:
  - /mesh/v2/
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
      include_content: md/mesh/v2/prereqs/kubernetes-cluster-lb
    - title: kubectl
      content: |
        Install and configure [`kubectl`](https://kubernetes.io/docs/tasks/tools/) to connect to your cluster.
related_resources:
  - text: "{{site.mesh_product_name}} in {{site.konnect_short_name}}"
    url: /mesh/v2/konnect/
  - text: Configure a Mesh global control plane on Kubernetes with the {{site.konnect_short_name}} UI
    url: /mesh/v2/configure-mesh-global-control-plane-on-kubernetes-with-konnect-ui/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} API
    url: /mesh/v2/configure-mesh-global-control-plane-on-universal-with-konnect-api/
  - text: Configure a Mesh global control plane on Universal with the {{site.konnect_short_name}} UI
    url: /mesh/v2/configure-mesh-global-control-plane-on-universal-with-konnect-ui/
  - text: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
    url: /mesh/v2/deploy-mesh-using-terraform-and-konnect/
next_steps:
  - text: Enable traffic permissions with the MeshTrafficPermission policy
    url: /mesh/v2/policies/meshtrafficpermission/
cleanup:
  inline:
    - title: Remove the demo application
      include_content: md/mesh/v2/cleanup/remove-demo-app
    - title: Uninstall the zone control plane
      include_content: md/mesh/v2/cleanup/uninstall-zone-cp
    - title: Delete the {{site.konnect_short_name}} control plane
      include_content: md/mesh/v2/cleanup/delete-konnect-control-plane-api
    - title: Remove the working directory
      include_content: md/mesh/v2/cleanup/remove-working-directory
faqs:
  - q: How does a zone authenticate to the global control plane?
    a: |
      {% include md/mesh/v2/faqs/zone-authentication.md %}
  - q: How do I configure kumactl to connect to the global control plane?
    a: |
      {% include md/mesh/v2/faqs/configure-kumactl.md %}
major_version:
  mesh: 2

---

Using the {{site.konnect_short_name}} API, you can create a global control plane, connect a Kubernetes zone, and manage your {{site.mesh_product_name}} mesh. This guide creates a global control plane, provisions a zone token, deploys a zone control plane and the demo application, and validates traffic through the mesh.

To run your zone control plane on a VM or bare metal instead, see [Configure a {{site.mesh_product_name}} global control plane on Universal with the {{site.konnect_short_name}} API](/mesh/v2/configure-mesh-global-control-plane-on-universal-with-konnect-api/).

## Create a global control plane in {{site.konnect_short_name}}

{% include md/mesh/v2/how-tos/create-global-control-plane-api.md %}

## Generate a zone token

{% include md/mesh/v2/how-tos/generate-zone-token-api.md %}

## Create a zone in the global control plane

With the token created, deploy the zone control plane on your Kubernetes cluster:

{% include md/mesh/v2/how-tos/deploy-zone-cp-kubernetes.md zone_name="zone-1" show_exports=true %}

Once the zone control plane is running, it connects to the global control plane and appears in {{site.konnect_short_name}}.

## Deploy the demo application

{% include md/mesh/v2/how-tos/deploy-demo-app.md %}

## Validate

{% include md/mesh/v2/how-tos/validate-mesh-zone.md %}
