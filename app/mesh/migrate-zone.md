---
title: Migrate a self-managed zone Control Plane to {{site.konnect_short_name}}
content_type: reference
description: 'Move your existing {{site.mesh_product_name}} zone Control Planes from a self-managed global Control Plane to a managed global Control Plane in {{site.konnect_short_name}}.'
layout: reference
breadcrumbs:
  - /mesh/
products:
  - mesh
tags:
  - service-mesh
---

If you already have zone Control Planes in {{site.mesh_product_name}}, you can migrate them to {{site.konnect_short_name}}.

Here are a few benefits of managing your service mesh in {{site.konnect_short_name}}:

* **Kong-managed global Control Plane:** {{site.konnect_short_name}} hosts and operates the global Control Plane for you.
* **Unified view:** Access all {{site.mesh_product_name}}, {{site.kic_product_name}}, and {{site.konnect_short_name}} entities from one place.
* **Setup wizard:** A UI-driven setup guides you through zone configuration.

This guide explains how to migrate a self-managed zone Control Plane to {{site.konnect_short_name}}.

![Before migration](/assets/images/konnect/diagram-mesh-migration-before.png)
> **Figure 1:** {{site.mesh_product_name}} services and data plane proxies connect to a self-managed global Control Plane.

![After migration](/assets/images/konnect/diagram-mesh-migration-after.png)
> **Figure 2:** After migration, the global Control Plane is hosted in {{site.konnect_short_name}}, while zones and services remain self-managed.

## Limitation

This process assumes you're migrating zones one by one. During migration, zone-to-zone communication may break temporarily because each zone's Zone Ingress must be registered with the new global Control Plane in {{site.konnect_short_name}}. Until both zones are migrated, cross-zone service discovery won't work.

## Prerequisites

* A Kubernetes or universal cluster with a zone Control Plane connected to a self-managed global Control Plane
* [`kumactl`](/mesh/#install-kong-mesh) installed and configured
* A [global Control Plane in {{site.konnect_short_name}}](/mesh/konnect-global-control-plane/)
* [`yq`](https://github.com/mikefarah/yq) installed

## Transfer resources from the self-managed global Control Plane

1. Make sure your self-managed global Control Plane is the active context:

   ```bash
   kumactl config control-planes list
   ```

   If using Kubernetes, you can port-forward for access:

   ```bash
   kubectl port-forward deployment/mesh-cp-name -n mesh-namespace 5681
   ```

1. Export mesh resources and policies using this script:

   ```bash
   #!/bin/bash

   outdir="policies"
   mkdir -p ${outdir}

   types="circuit-breakers external-services fault-injections healthchecks meshaccesslogs meshcircuitbreakers
   meshfaultinjections meshgateways meshgatewayroutes meshhealthchecks meshhttproutes meshloadbalancingstrategies
   meshproxypatches meshratelimits meshretries meshtcproutes meshtimeouts meshtraces meshtrafficpermissions
   proxytemplates rate-limits retries timeouts traffic-logs traffic-permissions traffic-routes traffic-traces
   virtual-outbounds access-role-bindings access-roles accessaudits meshglobalratelimits meshopas opa-policies"

   meshes=$(kumactl get meshes -oyaml | yq '.items[].name')

   for mesh in ${meshes}; do
     kumactl get mesh ${mesh} -oyaml | yq '(del(.creationTime,.modificationTime))' > "${outdir}/${mesh}.yaml"
     echo "---" >> "${outdir}/${mesh}.yaml"

     for type in ${types}; do
       kumactl get ${type} --mesh ${mesh} -oyaml | yq '.items[] |= (del(.creationTime,.modificationTime)) | .items[] | split_doc' | grep ^ >> "${outdir}/${mesh}.yaml" && echo "---" >> "${outdir}/${mesh}.yaml"
     done
   done
   ```

1. If mTLS is enabled, copy mesh secrets:

   * **Builtin CA:** Copy secrets named `{mesh}.ca-builtin-cert-{backend}` and `{mesh}.ca-builtin-key-{backend}`.
   * **Provided CA:** Copy the secrets listed in the mesh resource.
   See [mTLS secret storage](/mesh/policies/meshtls/#storage-of-secrets) for details.

1. Switch to the {{site.konnect_short_name}} global Control Plane:

   ```bash
   kumactl config control-planes switch --name {konnect-config-name}
   ```

1. Apply the exported resources:

   ```bash
   kumactl apply -f {file_name}
   ```

## Connect the zone Control Plane to {{site.konnect_short_name}}

1. [Create a new zone](/mesh/konnect-global-control-plane/#create-a-zone-in-the-global-control-plane) in {{site.konnect_short_name}}.


   Use the same name as the existing zone. Replace your current zone's `values.yaml` with the config provided by the UI wizard.

1. If [KDS TLS](/mesh/production/secure-deployment/certificates/#control-plane-to-control-plane-multizone) is enabled with self-signed certs, disable custom certs so the zone can use {{site.konnect_short_name}}'s default CA:


   ```bash
   kumactl install control-plane \
     --set "kuma.controlPlane.tls.kdsZoneClient.secretName=kds-ca-certs" \
     | kubectl apply -f -
   ```

1. Restart the zone Control Plane.

   {{site.konnect_short_name}} will automatically detect and display the new zone in the UI.
