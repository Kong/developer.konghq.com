---
title: Connect a Universal zone to {{site.konnect_short_name}} with the UI
content_type: how_to
permalink: "/mesh/configure-mesh-global-control-plane-on-universal-with-konnect-ui/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a Mesh 3 global control plane in Konnect and connect a Universal
  zone.
products:
- mesh
works_on:
- konnect
tags:
- service-mesh
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

- A Konnect organization with Mesh 3 enabled and permission to create Mesh control planes.
- A Konnect personal access token in `KONNECT_TOKEN`, plus `curl` and `jq` for the version check.
- A supported VM or bare-metal host and a Mesh 3 release approved for your control plane. The example uses an in-memory store for evaluation.
- Outbound network access from the zone to your regional Konnect KDS endpoint on port 443.


Set the region where you will create the global control plane:

```sh
export KONNECT_REGION='us'
```

This is a fresh installation, not an upgrade procedure. If the account does not offer Mesh 3, stop and confirm availability rather than deploying a 3.x zone against a v2 control plane.

## Create the global control plane

In [Service Mesh](https://cloud.konghq.com/mesh-manager), create a new control plane named `example-cp` using the Mesh 3 creation option available to your organization. Copy its ID:

```sh
export CONTROL_PLANE_ID='YOUR_CONTROL_PLANE_ID'
```

The exact Mesh 3 version-selection UI still needs confirmation. If the UI does not offer a Mesh 3 creation path, use the [API installation guide](/mesh/configure-mesh-global-control-plane-on-universal-with-konnect-api/), which explicitly sets `version: v3`. Do not create a v2 control plane and assume the zone installer upgrades it.

## Add the zone

Open the new control plane, choose **Create zone**, select **Universal**, and name it `zone-1`. Follow the generated credential and deployment instructions for a Mesh 3 zone.

The wizard provisions a system account access token for the zone. Keep it separate from the personal token used to manage Konnect. To use the explicit deployment example below, copy the generated zone token into:

```sh
export CONTROL_PLANE_TOKEN='YOUR_GENERATED_ZONE_ACCESS_TOKEN'
```

Deploy the zone only once: use either the generated Mesh 3 deployment instructions or the equivalent example below. Do not reuse generated 2.x values that enable shared `ingress` and `egress` deployments.

{% include md/mesh/how-tos/deploy-konnect-zone.md platform="universal" %}

## Clean up

Stop this guide's foreground control plane with **Ctrl+C**. Do not stop other `kuma-cp` processes on the host.

In Konnect, delete only the `example-cp` control plane created for this test. This also removes its mesh configuration. Revoke the zone token if they remain. Review the files in `MESH_INSTALL_DIR` and remove the credentials when no longer needed.
