---
title: Connect a Universal zone to {{site.konnect_short_name}} with the API
content_type: how_to
permalink: "/mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a Mesh 3 global control plane in Konnect and connect a Universal
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
  q: How do I connect a universal zone to Konnect for Mesh 3?
  a: Create a new global control plane running v3, deploy a 3.x zone control plane
    with its Konnect credentials, and verify that the zone connects.
related_resources:
- text: Installation options
  url: "/mesh/konnect/"
- text: Mesh 3 CLI
  url: "/mesh/cli/"
- text: MeshIdentity
  url: "/mesh/policies/meshidentity/"
next_steps:
- text: Register Universal application proxies
  url: "/mesh/universal-data-plane/"
min_version:
  mesh: '3.0'
---

This guide creates a new Konnect-managed global control plane and connects a Universal (VM or bare-metal) zone. Konnect runs the global control plane; you run the zone in your own environment.

This guide ends with a connected zone. Registering application proxies and securing their traffic are separate next steps.

## Prerequisites

- A Konnect organization with Mesh 3 enabled and permission to create Mesh control planes and system accounts.
- A Konnect personal access token in `KONNECT_TOKEN`, plus `curl` and `jq` for the version check and API requests.
- A supported VM or bare-metal host and a Mesh 3 release approved for your control plane. The example uses an in-memory store for evaluation.
- Outbound network access from the zone to your regional Konnect KDS endpoint on port 443.


Set the region where you will create the global control plane:

```sh
export KONNECT_REGION='us'
```

This is a fresh installation, not an upgrade procedure. If the account does not offer Mesh 3, stop and confirm availability rather than deploying a 3.x zone against a v2 control plane.

{% include md/mesh/how-tos/provision-konnect.md create_control_plane=true %}

{% include md/mesh/how-tos/deploy-konnect-zone.md platform="universal" %}

## Clean up

Stop this guide's foreground control plane with **Ctrl+C**. Do not stop other `kuma-cp` processes on the host.

In Konnect, delete only the `example-cp` control plane created for this test. This also removes its mesh configuration. Revoke the zone token and delete the system account created by this guide if they remain. Review the files in `MESH_INSTALL_DIR` and remove the credentials when no longer needed.
