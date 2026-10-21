---
title: Connect a Kubernetes zone to {{site.konnect_short_name}} with the API
content_type: how_to
permalink: "/mesh/connect-kubernetes-zone-to-konnect-api/"
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

        Delete the `mesh-zone-1` system account:

        ```sh
        curl --fail-with-body -sS -X DELETE \
          "https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        ```
min_version:
  mesh: '3.0'
---

This guide creates a {{site.konnect_short_name}}-managed global control plane, connects a Kubernetes zone, and verifies that one application can call another only with the permitted identity.

Set the region where you will create the global control plane:

```sh
export KONNECT_REGION='us'
```

## Create a global control plane in {{site.konnect_short_name}}

{% include md/mesh/v3/how-tos/create-global-control-plane.md %}

## Give the zone credentials to connect

{% include md/mesh/v3/how-tos/give-zone-credentials.md %}

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
