---
title: Federate a zone Control Plane to {{site.konnect_short_name}}
content_type: reference
description: 'Migrate a single-zone {{site.mesh_product_name}} Control Plane to {{site.konnect_short_name}} and enable multi-zone service mesh federation.'
layout: reference
breadcrumbs:
  - /mesh/
products:
  - mesh
works_on:
  - konnect
tags:
  - service-mesh
---

If you already have a zone Control Plane that's not connected to any global Control Plane, you can federate it to {{site.konnect_short_name}}.

By federating a zone Control Plane, you move {{site.mesh_product_name}} from a single-zone setup to a [multi-zone](/mesh/multi-zone-authentication/) setup. This enables automatic service failover if a specific zone becomes unavailable.

This guide explains how to federate a zone Control Plane to {{site.konnect_short_name}} by migrating an existing {{site.mesh_product_name}} zone and adding a new one.

## Prerequisites

* A universal or Kubernetes cluster with a running zone Control Plane that's not yet connected to a global Control Plane
* The latest version of [`kumactl`](/mesh/#install-kong-mesh) installed and configured
* A [{{site.mesh_product_name}} global Control Plane in {{site.konnect_short_name}}](/mesh-manager/service-mesh/#create-a-zone-in-the-global-control-plane)

## Transfer resources from the zone Control Plane to {{site.konnect_short_name}}

1. In the {{site.konnect_short_name}} menu, navigate to [**Service Mesh**](https://cloud.konghq.com/mesh-manager).

1. Click **Global Control Plane Actions**.

1. Select **Configure kumactl**.

1. Configure `kumactl` to access the zone Control Plane.

   * **Kubernetes only**: If your zone is deployed on Kubernetes, forward port `5681` for access:

     ```bash
     kubectl port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681
     ```

   * Use the admin token to configure `kumactl`:

     ```bash
     export ZONE_USER_ADMIN_TOKEN=$(kubectl get secrets -n kong-mesh-system admin-user-token -ojson | jq -r .data.value | base64 -d)

     kumactl config control-planes add \
       --address http://localhost:5681 \
       --headers "authorization=Bearer $ZONE_USER_ADMIN_TOKEN" \
       --name "zone-cp" \
       --overwrite
     ```

   * **Universal/VM only**: Follow the [API server authentication guide](/mesh/authentication-with-the-api-server/) to configure `kumactl`.

1. Export federation-ready resources:

   ```bash
   kumactl export --profile=federation --format=universal > resources.yaml
   ```

1. Switch `kumactl` to target the {{site.konnect_short_name}} global Control Plane:

   ```bash
   kumactl config control-planes list
   kumactl config control-planes switch --name {konnect-config-name}
   ```

1. Apply the exported resources:

   ```bash
   kumactl apply -f resources.yaml
   ```

## Connect the zone Control Plane to {{site.konnect_short_name}}

1. Create a new zone in {{site.konnect_short_name}}.

   Replace your existing zone Control Plane's `values.yaml` configuration with the values provided by the {{site.konnect_short_name}} UI wizard.

1. Restart the zone Control Plane with the new configuration.

   Once restarted, {{site.konnect_short_name}} will automatically detect and display the new zone in the UI.

## Verify federation

Navigate to [**Service Mesh**](https://cloud.konghq.com/mesh-manager) and confirm:

* The new zone appears as **Online**
* Existing policies from the zone Control Plane are visible
* Data plane proxies from the federated zone appear as expected
