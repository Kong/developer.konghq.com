---
title: Connect a Kubernetes zone to {{site.konnect_short_name}} with the API
content_type: how_to
permalink: "/mesh/configure-mesh-global-control-plane-on-kubernetes-with-konnect-api/"
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
- konnect-api
- kongctl
tags:
- service-mesh
tldr:
  q: How do I connect a kubernetes zone to {{site.konnect_short_name}} for {{site.mesh_product_name}} 3.x?
  a: Create a new global control plane running v3, deploy a 3.x zone control plane
    with its {{site.konnect_short_name}} credentials, and verify that the zone connects. Then configure
    MeshIdentity and MeshTrafficPermission and test an application request.
prereqs:
  inline:
    - title: kubectl and Helm
      content: |
        A Kubernetes cluster, `kubectl`, and Helm. Use a fresh evaluation namespace and a {{site.mesh_product_name}} 3.x chart approved for your control plane.
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
- text: Apply traffic policies
  url: "/mesh/policy-targeting/"
cleanup:
  inline:
    - title: Remove the Kubernetes zone
      content: |
        Delete the test namespace and uninstall the zone release:

        ```sh
        kubectl delete namespace kong-mesh-demo
        helm uninstall kong-mesh --namespace kong-mesh-system
        ```

        Delete the `cp-token` Secret and `kong-mesh-system` namespace only if they were created exclusively for this test.
    - title: Delete the {{site.konnect_short_name}} control plane
      content: |
        In {{site.konnect_short_name}}, delete only the `example-cp` control plane created for this test. This also removes its mesh configuration. Revoke the zone token and delete the system account created by this guide if they remain. Review the files in `MESH_INSTALL_DIR` and remove the credentials when no longer needed.
min_version:
  mesh: '3.0'
---

This guide creates a new {{site.konnect_short_name}}-managed global control plane and connects a Kubernetes zone. {{site.konnect_short_name}} runs the global control plane; you run the zone in your own environment.

You will also configure workload identities and verify that one application can call another only with the permitted identity.

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

{% include md/mesh/how-tos/deploy-zone-control-plane.md platform="kubernetes" %}

## Verify the zone connection

{% include md/mesh/how-tos/verify-zone-connection.md %}

## Create a mesh and secure the test traffic

{% include md/mesh/how-tos/create-mesh-and-permission.md %}

## Deploy the test applications

{% include md/mesh/how-tos/deploy-test-applications.md %}

## Verify an allowed and a denied call

{% include md/mesh/how-tos/verify-allowed-and-denied-request.md %}
