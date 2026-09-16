---
title: Connect a Kubernetes zone to {{site.konnect_short_name}} with the UI
content_type: how_to
permalink: "/mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-ui/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a Mesh 3 global control plane in Konnect and connect a Kubernetes
  zone, then verify identity-based service access.
products:
- mesh
works_on:
- konnect
tags:
- service-mesh
tldr:
  q: How do I connect a kubernetes zone to Konnect for Mesh 3?
  a: Create a new global control plane running v3, deploy a 3.x zone control plane
    with its Konnect credentials, and verify that the zone connects. Then configure
    MeshIdentity and MeshTrafficPermission and test an application request.
related_resources:
- text: Installation options
  url: "/mesh/konnect/"
- text: Mesh 3 CLI
  url: "/mesh/cli/"
- text: MeshIdentity
  url: "/mesh/policies/meshidentity/"
next_steps:
- text: Apply traffic policies
  url: "/mesh/policy-targeting/"
min_version:
  mesh: '3.0'
---

This guide creates a new Konnect-managed global control plane and connects a Kubernetes zone. Konnect runs the global control plane; you run the zone in your own environment.

You will also configure workload identities and verify that one application can call another only with the permitted identity.

## Prerequisites

- A Konnect organization with Mesh 3 enabled and permission to create Mesh control planes.
- A Konnect personal access token in `KONNECT_TOKEN`, plus `curl` and `jq` for the version check.
- A Kubernetes cluster, `kubectl`, and Helm. Use a fresh evaluation namespace and a Mesh 3 chart approved for your control plane.
- Outbound network access from the zone to your regional Konnect KDS endpoint on port 443.
- A kongctl build with Mesh 3 commands; see the [CLI reference](/mesh/cli/).

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

The exact Mesh 3 version-selection UI still needs confirmation. If the UI does not offer a Mesh 3 creation path, use the [API installation guide](/mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/), which explicitly sets `version: v3`. Do not create a v2 control plane and assume the zone installer upgrades it.

## Add the zone

Open the new control plane, choose **Create zone**, select **Kubernetes**, and name it `zone-1`. Follow the generated credential and deployment instructions for a Mesh 3 zone.

The wizard provisions a system account access token for the zone. Keep it separate from the personal token used to manage Konnect. To use the explicit deployment example below, copy the generated zone token into:

```sh
export CONTROL_PLANE_TOKEN='YOUR_GENERATED_ZONE_ACCESS_TOKEN'
```

Deploy the zone only once: use either the generated Mesh 3 deployment instructions or the equivalent example below. Do not reuse generated 2.x values that enable shared `ingress` and `egress` deployments.

{% include md/mesh/how-tos/deploy-konnect-zone.md platform="kubernetes" %}

{% include md/mesh/how-tos/konnect-kubernetes-secure-test.md %}

## Clean up

For this disposable installation, delete the test namespace and uninstall the zone release:

```sh
kubectl delete namespace kong-mesh-demo
helm uninstall kong-mesh --namespace kong-mesh-system
```

Delete the `cp-token` Secret and `kong-mesh-system` namespace only if they were created exclusively for this test.

In Konnect, delete only the `example-cp` control plane created for this test. This also removes its mesh configuration. Revoke the zone token if they remain. Review the files in `MESH_INSTALL_DIR` and remove the credentials when no longer needed.
