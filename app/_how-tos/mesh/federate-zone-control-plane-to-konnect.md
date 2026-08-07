---
title: Federate a zone control plane to {{site.konnect_short_name}}
content_type: how_to
permalink: /mesh/federate-zone-control-plane-to-konnect/
breadcrumbs:
  - /mesh/
description: 'Federate a single-zone {{site.mesh_product_name}} control plane to {{site.konnect_short_name}} and enable a multi-zone service mesh.'
products:
  - mesh
works_on:
  - konnect
tags:
  - service-mesh
tldr:
  q: How do I federate a single-zone {{site.mesh_product_name}} control plane to {{site.konnect_short_name}}?
  a: Export federation-ready resources from your existing zone control plane, apply them to a {{site.konnect_short_name}}-managed global control plane, then reconnect the zone to {{site.konnect_short_name}} to move from a single-zone to a multi-zone mesh.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} global control plane"
      include_content: how-tos/mesh/create-global-control-plane-api
    - title: Install kumactl
      include_content: prereqs/tools/kumactl
    - title: Zone control plane
      content: |
        Deploy a standalone {{site.mesh_product_name}} control plane on Kubernetes. This is the single-zone control plane that you'll federate to {{site.konnect_short_name}}; it isn't connected to any global control plane yet.

        1. Add the {{site.mesh_product_name}} Helm repository:

           ```sh
           helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
           helm repo update
           ```

        1. Install the control plane:

           ```sh
           helm install --create-namespace --namespace {{site.mesh_namespace}} {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
           ```

        1. Wait for the control plane to be ready:

           ```sh
           kubectl wait -n {{site.mesh_namespace}} --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=90s
           ```
related_resources:
  - text: "{{site.mesh_product_name}} in {{site.konnect_short_name}}"
    url: /mesh/konnect/
  - text: Migrate a self-managed zone control plane to {{site.konnect_short_name}}
    url: /mesh/migrate-self-managed-zone-to-konnect/
cleanup:
  inline:
    - title: Stop the port-forward
      content: |
        Stop the `kubectl port-forward` process used to reach the zone control plane:

        ```sh
        pkill -f "kubectl port-forward.*5681"
        ```
    - title: Uninstall the zone control plane
      include_content: cleanup/mesh/uninstall-zone-cp
    - title: Delete the {{site.konnect_short_name}} control plane
      include_content: cleanup/mesh/delete-konnect-control-plane-api
    - title: Remove the kumactl control plane configurations
      content: |
        Remove the control plane configurations added to `kumactl` during this guide:

        ```sh
        kumactl config control-planes remove --name zone-cp
        kumactl config control-planes remove --name konnect
        ```
    - title: Remove the working directory
      include_content: cleanup/mesh/remove-working-directory
faqs:
  - q: How does a zone authenticate to the global control plane?
    a: |
      {% include faqs/mesh-zone-authentication.md %}
---

If you already have a zone control plane that isn't connected to any global control plane, you can federate it to {{site.konnect_short_name}}.

Federating a zone control plane moves {{site.mesh_product_name}} from a single-zone setup to a [multi-zone](/mesh/multi-zone-authentication/) setup, which enables automatic service failover if a specific zone becomes unavailable. This guide federates a zone control plane to {{site.konnect_short_name}} by transferring an existing {{site.mesh_product_name}} zone and reconnecting it. To learn more, see [{{site.mesh_product_name}} in {{site.konnect_short_name}}](/mesh/konnect/).

## Configure kumactl to access your zone control plane

{:.info}
> This example uses a zone control plane deployed on Kubernetes. If you have a Universal zone control plane, see the [API server authentication guide](/mesh/authentication-with-the-api-server/) to configure `kumactl`.

1. Forward port `5681`:

   ```bash
   kubectl port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681 > /dev/null 2>&1 &
   ```

1. Configure `kumactl` to access the zone control plane. Requests over the port-forward reach the control plane from `localhost`, which {{site.mesh_product_name}} authenticates as an administrator by default, so no token is required:

   ```bash
   kumactl config control-planes add \
     --address http://localhost:5681 \
     --name "zone-cp" \
     --overwrite
   ```


## Transfer resources from the zone control plane to {{site.konnect_short_name}}

1. Create and navigate to the working directory:

   ```bash
   mkdir -p ~/mesh-konnect && cd ~/mesh-konnect
   ```

1. Export federation-ready resources from the zone control plane:

   ```bash
   kumactl export --profile=federation --format=universal > resources.yaml
   ```

{% include how-tos/mesh/apply-resources-to-konnect.md %}

## Connect the zone control plane to {{site.konnect_short_name}}

Generate a zone token from the {{site.konnect_short_name}}-managed global control plane, then reconfigure your existing zone control plane to connect to {{site.konnect_short_name}}.

{% include how-tos/mesh/generate-zone-token-api.md %}

{% include how-tos/mesh/reconnect-zone-to-konnect.md %}

## Validate

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp** and confirm that:
   * The new zone appears as **Online**.
   * Existing policies from the zone control plane are visible.
   * Data plane proxies from the federated zone appear as expected.

{:.info}
> It may take a few minutes for the zone to appear in {{site.konnect_short_name}}.
