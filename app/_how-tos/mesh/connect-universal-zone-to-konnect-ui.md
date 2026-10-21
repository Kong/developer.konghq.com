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
        A supported host and a {{site.mesh_product_name}} 3.x release approved for your control plane. The example uses an in-memory store for evaluation.
    - title: Network access
      content: |
        Confirm your zone's network allows outbound access on port 443 to your regional {{site.konnect_short_name}} KDS endpoint, `$KONNECT_REGION.mesh.sync.konghq.com`.
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
    - title: Delete the {{site.konnect_short_name}} control plane
      content: |
        In {{site.konnect_short_name}}, delete only the `example-cp` control plane created for this test. Deleting the control plane also removes its mesh configuration. Revoke the zone token if it remains. Review the files in `MESH_INSTALL_DIR` and remove the credentials when no longer needed.
min_version:
  mesh: '3.0'
---

This guide creates a new {{site.konnect_short_name}}-managed global control plane and connects a Universal (VM or bare-metal) zone. {{site.konnect_short_name}} runs the global control plane; you run the zone in your own environment.

This guide ends with a connected zone. Registering application proxies and securing their traffic are separate next steps.

Set the region where you will create the global control plane:

```sh
export KONNECT_REGION='us'
```

This is a fresh installation, not an upgrade procedure. If the account doesn't offer {{site.mesh_product_name}} 3.x, stop and confirm availability rather than deploying a 3.x zone against a v2 control plane.

## Create the global control plane

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Create a new control plane named `example-cp` using the {{site.mesh_product_name}} 3.x creation option available to your organization.
1. Copy the control plane ID and export it:

   ```sh
   export CONTROL_PLANE_ID='YOUR_CONTROL_PLANE_ID'
   ```

The exact {{site.mesh_product_name}} 3.x version-selection UI still needs confirmation. If the UI doesn't offer a {{site.mesh_product_name}} 3.x creation path, use the [API installation guide](/mesh/connect-universal-zone-to-konnect-api/), which explicitly sets `version: v3`. Don't create a v2 control plane and assume the zone installer upgrades it.

## Add the zone

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Click **Create zone**.
1. Select **Universal**.
1. In the **Name** field, enter `zone-1`.
1. Follow the generated credential and deployment instructions for a {{site.mesh_product_name}} 3.x zone.

The wizard provisions a system account access token for the zone. Keep it separate from the personal token used to manage {{site.konnect_short_name}}. To use the explicit deployment example that follows, copy the generated zone token into:

```sh
export CONTROL_PLANE_TOKEN='YOUR_GENERATED_ZONE_ACCESS_TOKEN'
```

Deploy the zone only once: use either the generated {{site.mesh_product_name}} 3.x deployment instructions or the equivalent example that follows. Don't reuse generated 2.x values that enable shared `ingress` and `egress` deployments.

## Check the global control plane version

{% include md/mesh/v3/how-tos/check-control-plane-version.md %}

## Deploy the zone control plane

{% include md/mesh/v3/how-tos/deploy-zone-control-plane.md platform="universal" %}

## Verify the zone connection

{% include md/mesh/v3/how-tos/verify-zone-connection.md %}
