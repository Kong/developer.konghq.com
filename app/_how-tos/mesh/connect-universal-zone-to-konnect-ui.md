---
title: Connect a Universal zone to {{site.konnect_short_name}} with the UI
content_type: how_to
permalink: "/mesh/connect-universal-zone-to-konnect-ui/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a {{site.mesh_product_name}} 3.x global control plane in {{site.konnect_short_name}} and connect a Universal
  zone.
products:
- mesh
works_on:
- konnect
tags:
- service-mesh
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
      content: |
        Stop the control plane this guide started:

        ```sh
        kill "$(cat "$MESH_INSTALL_DIR/kuma-cp.pid")"
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

This guide creates a {{site.konnect_short_name}}-managed global control plane and connects a Universal (VM or bare-metal) zone.

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

If the UI doesn't offer a {{site.mesh_product_name}} 3.x control plane, use the [API guide](/mesh/connect-universal-zone-to-konnect-api/) instead, which sets `version: v3`.

## Add the zone

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Click **Create zone**.
1. Select **Universal**.
1. In the **Name** field, enter `zone-1`.
1. Follow the generated credential and deployment instructions for a {{site.mesh_product_name}} 3.x zone.

Copy the generated zone token:

```sh
export CONTROL_PLANE_TOKEN='YOUR_GENERATED_ZONE_ACCESS_TOKEN'
```

## Deploy the zone control plane

{% include md/mesh/v3/how-tos/deploy-zone-control-plane.md platform="universal" %}

## Validate

{% include md/mesh/v3/how-tos/verify-zone-connection.md %}
