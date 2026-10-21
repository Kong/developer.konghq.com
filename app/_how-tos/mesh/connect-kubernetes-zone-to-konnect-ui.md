---
title: Connect a Kubernetes zone to {{site.konnect_short_name}} with the UI
content_type: how_to
permalink: "/mesh/connect-kubernetes-zone-to-konnect-ui/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a {{site.mesh_product_name}} 3.x global control plane in {{site.konnect_short_name}} and connect a Kubernetes
  zone, then verify identity-based service access.
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
      content: |
        Delete the zone traffic permission:

        ```sh
        kubectl delete meshtrafficpermission client-to-server --namespace kong-mesh-system
        ```

        Delete the test namespace:

        ```sh
        kubectl delete namespace kong-mesh-demo
        ```

        Uninstall the zone release:

        ```sh
        helm uninstall kong-mesh --namespace kong-mesh-system
        ```

        Delete the zone namespace and the `cp-token` Secret in it:

        ```sh
        kubectl delete namespace kong-mesh-system
        ```
    - title: Delete the {{site.konnect_short_name}} resources
      content: |
        Delete the `example-cp` control plane. This also removes its mesh configuration:

        ```sh
        curl --fail-with-body -sS -X DELETE \
          "https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes/$CONTROL_PLANE_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        ```

        In {{site.konnect_short_name}}, delete the system account that the zone wizard created for `zone-1`.
min_version:
  mesh: '3.0'
---

This guide creates a {{site.konnect_short_name}}-managed global control plane, connects a Kubernetes zone, and verifies that one application can call another only with the permitted identity.

Set the region where you will create the global control plane:

```sh
export KONNECT_REGION='us'
```

## Create the global control plane

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Create a new control plane named `example-cp` using the {{site.mesh_product_name}} 3.x creation option available to your organization.
1. Copy the control plane ID and export it:

   ```sh
   export CONTROL_PLANE_ID='YOUR_CONTROL_PLANE_ID'
   ```

If the UI doesn't offer a {{site.mesh_product_name}} 3.x control plane, use the [API guide](/mesh/connect-kubernetes-zone-to-konnect-api/) instead, which sets `version: v3`.

## Add the zone

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Click **Create zone**.
1. Select **Kubernetes**.
1. In the **Name** field, enter `zone-1`.
1. Follow the generated credential and deployment instructions for a {{site.mesh_product_name}} 3.x zone.

Copy the generated zone token:

```sh
export CONTROL_PLANE_TOKEN='YOUR_GENERATED_ZONE_ACCESS_TOKEN'
```

## Deploy the zone control plane

{% include md/mesh/v3/how-tos/deploy-zone-control-plane.md platform="kubernetes" %}

## Verify the zone connection

{% include md/mesh/v3/how-tos/verify-zone-connection.md %}

## Create a mesh and secure the test traffic

{% include md/mesh/v3/how-tos/create-mesh-and-permission.md %}

## Deploy the test applications

{% include md/mesh/v3/how-tos/deploy-test-applications.md %}

## Validate

{% include md/mesh/v3/how-tos/verify-allowed-and-denied-request.md %}
