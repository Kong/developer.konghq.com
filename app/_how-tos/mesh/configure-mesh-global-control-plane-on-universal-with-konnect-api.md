---
title: Connect a Universal zone to {{site.konnect_short_name}} with the API
content_type: how_to
permalink: "/mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a {{site.mesh_product_name}} 3.x global control plane in {{site.konnect_short_name}} and connect a Universal
  zone.
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
  q: How do I connect a universal zone to {{site.konnect_short_name}} for {{site.mesh_product_name}} 3.x?
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
        Stop this guide's foreground control plane with **Ctrl+C**. Do not stop other `kuma-cp` processes on the host.
    - title: Delete the {{site.konnect_short_name}} control plane
      content: |
        In {{site.konnect_short_name}}, delete only the `example-cp` control plane created for this test. This also removes its mesh configuration. Revoke the zone token and delete the system account created by this guide if they remain. Review the files in `MESH_INSTALL_DIR` and remove the credentials when no longer needed.
min_version:
  mesh: '3.0'
---

This guide creates a new {{site.konnect_short_name}}-managed global control plane and connects a Universal (VM or bare-metal) zone. {{site.konnect_short_name}} runs the global control plane; you run the zone in your own environment.

This guide ends with a connected zone. Registering application proxies and securing their traffic are separate next steps.

Set the region where you will create the global control plane:

```sh
export KONNECT_REGION='us'
```

This is a fresh installation, not an upgrade procedure. If the account does not offer {{site.mesh_product_name}} 3.x, stop and confirm availability rather than deploying a 3.x zone against a v2 control plane.

## Create a global control plane in {{site.konnect_short_name}}

{% include md/mesh/how-tos/create-global-control-plane.md %}

## Give the zone credentials to connect

{% include md/mesh/how-tos/give-zone-credentials.md %}

## Check the global control plane version

{% include md/mesh/how-tos/check-control-plane-version.md %}

## Deploy the zone control plane

{% include md/mesh/how-tos/deploy-zone-control-plane.md platform="universal" %}

## Verify the zone connection

{% include md/mesh/how-tos/verify-zone-connection.md %}
