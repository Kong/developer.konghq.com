---
title: Migrate a self-managed zone control plane to {{site.konnect_short_name}}
content_type: how_to
permalink: /mesh/migrate-self-managed-zone-to-konnect/
breadcrumbs:
  - /mesh/
description: 'Move your existing {{site.mesh_product_name}} zone control planes from a self-managed global control plane to a {{site.konnect_short_name}}-managed global control plane.'
products:
  - mesh
works_on:
  - konnect
tags:
  - service-mesh
tldr:
  q: How do I migrate a self-managed {{site.mesh_product_name}} zone to {{site.konnect_short_name}}?
  a: Export your meshes, policies, and secrets from the self-managed global control plane, apply them to a {{site.konnect_short_name}}-managed global control plane, then reconnect each zone control plane to {{site.konnect_short_name}}.
prereqs:
  inline:
    - title: A {{site.konnect_short_name}} global control plane
      include_content: how-tos/mesh/create-global-control-plane-api
    - title: A self-managed zone control plane
      content: |
        Deploy a self-managed {{site.mesh_product_name}} global control plane and a zone control plane connected to it on Kubernetes. You'll migrate this zone to {{site.konnect_short_name}}.

        1. Export the names of the contexts to your environment:

           ```sh
           export GLOBAL_CONTEXT=global
           export ZONE_CONTEXT=zone
           ```

        1. Create separate clusters for the global and zone control planes. The global and zone control planes must run in separate clusters. These steps use minikube:

           ```sh
           minikube start -p $GLOBAL_CONTEXT
           minikube start -p $ZONE_CONTEXT
           ```

        1. Provision load balancer addresses on the global cluster so the zone can reach the control plane's KDS address:

           ```sh
           nohup minikube tunnel -p $GLOBAL_CONTEXT > /dev/null 2>&1 &
           ```


        1. Add the {{site.mesh_product_name}} Helm repository:

           ```sh
           helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
           helm repo update
           ```

        1. Deploy the global control plane:

           ```sh
           helm install --kube-context $GLOBAL_CONTEXT --create-namespace --namespace {{site.mesh_namespace}} \
             --set kuma.controlPlane.mode=global \
             {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
           ```

        1. Export the global control plane's KDS address:

           ```sh
           export KDS_ADDRESS=grpcs://$(kubectl --context $GLOBAL_CONTEXT get svc -n {{site.mesh_namespace}} kong-mesh-global-zone-sync -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):5685
           ```

        1. Deploy a zone control plane connected to the global control plane:

           ```sh
           helm install --kube-context $ZONE_CONTEXT --create-namespace --namespace {{site.mesh_namespace}} \
             --set kuma.controlPlane.mode=zone \
             --set kuma.controlPlane.zone=zone-1 \
             --set kuma.controlPlane.kdsGlobalAddress=$KDS_ADDRESS \
             --set kuma.controlPlane.tls.kdsZoneClient.skipVerify=true \
             --set kuma.ingress.enabled=true \
             {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
           ```
    - title: Install kumactl
      include_content: prereqs/tools/kumactl
related_resources:
  - text: "{{site.mesh_product_name}} in {{site.konnect_short_name}}"
    url: /mesh/konnect/
  - text: Federate a zone control plane to {{site.konnect_short_name}}
    url: /mesh/federate-zone-control-plane-to-konnect/
cleanup:
  inline:
    - title: Stop the background processes
      content: |
        Stop the `kubectl port-forward` and `minikube tunnel` processes started during this guide:

        ```sh
        pkill -f "kubectl port-forward.*5681"
        pkill -f "minikube tunnel"
        ```
    - title: Delete the self-managed clusters
      content: |
        Delete the global and zone clusters created for this guide:

        ```sh
        minikube delete -p $GLOBAL_CONTEXT
        minikube delete -p $ZONE_CONTEXT
        ```
    - title: Delete the {{site.konnect_short_name}} control plane
      include_content: cleanup/mesh/delete-konnect-control-plane-api
    - title: Remove the kumactl control plane configurations
      content: |
        Remove the control plane configurations added to `kumactl` during this guide:

        ```sh
        kumactl config control-planes remove --name global-cp
        kumactl config control-planes remove --name konnect
        ```
    - title: Remove the working directory
      include_content: cleanup/mesh/remove-working-directory
faqs:
  - q: How does a zone authenticate to the global control plane?
    a: |
      {% include faqs/mesh-zone-authentication.md %}
---

If you already run {{site.mesh_product_name}} with a self-managed global control plane, you can migrate your zones to a {{site.konnect_short_name}}-managed global control plane so that {{site.konnect_short_name}} hosts and operates the global control plane for you. To learn more, see [{{site.mesh_product_name}} in {{site.konnect_short_name}}](/mesh/konnect/).

This guide migrates a self-managed zone control plane to {{site.konnect_short_name}} by transferring your meshes and policies to the {{site.konnect_short_name}}-managed global control plane and reconnecting the zone.

{:.warning}
> This process assumes you're migrating zones one by one. During migration, zone-to-zone communication may break temporarily because each zone's zone ingress must be registered with the new global control plane in {{site.konnect_short_name}}. Until both zones are migrated, cross-zone service discovery won't work.

## Transfer resources from the self-managed global control plane

1. Create and enter a working directory for this guide:

   ```bash
   mkdir -p ~/mesh-konnect && cd ~/mesh-konnect
   ```

1. Forward port `5681` from the self-managed global control plane:

   ```bash
   kubectl port-forward --context $GLOBAL_CONTEXT svc/kong-mesh-control-plane -n {{site.mesh_namespace}} 5681:5681 > /dev/null 2>&1 &
   ```

1. Configure `kumactl` to access the self-managed global control plane. Requests over the port-forward reach the control plane from `localhost`, which {{site.mesh_product_name}} authenticates as an administrator by default, so no token is required:

   ```bash
   kumactl config control-planes add \
     --address http://localhost:5681 \
     --name "global-cp" \
     --overwrite
   ```

1. Export the meshes, policies, and secrets from the self-managed global control plane. The `federation-with-policies` profile includes the mesh definitions, all policies, and the signing keys and secrets (including mTLS CA secrets) that the zone needs to keep working after it moves:

   ```bash
   kumactl export --profile=federation-with-policies --format=universal > resources.yaml
   ```

1. Configure `kumactl` to target the {{site.konnect_short_name}}-managed global control plane. This points `kumactl` at your control plane's Mesh API and authenticates with your {{site.konnect_short_name}} token:

   ```bash
   kumactl config control-planes add \
     --name konnect \
     --address https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes/$CONTROL_PLANE_ID/api \
     --headers "authorization=Bearer $KONNECT_TOKEN" \
     --overwrite
   ```

1. Apply the exported resources to the {{site.konnect_short_name}} global control plane:

   ```bash
   kumactl apply -f resources.yaml
   ```

## Connect the zone control plane to {{site.konnect_short_name}}

Generate a zone token from the {{site.konnect_short_name}}-managed global control plane, then reconfigure your existing zone control plane to connect to {{site.konnect_short_name}} instead of the self-managed global control plane.

{% include how-tos/mesh/generate-zone-token-api.md %}

1. Store the zone token in a Kubernetes secret on the zone cluster:

   ```sh
   echo "
   apiVersion: v1
   kind: Secret
   metadata:
     name: cp-token
     namespace: {{site.mesh_namespace}}
   type: Opaque
   stringData:
     token: $CONTROL_PLANE_TOKEN
   " | kubectl --context $ZONE_CONTEXT apply -f -
   ```

1. Create a Helm values file that connects the zone to {{site.konnect_short_name}}. Use the same zone name as the existing zone:

   ```sh
   cat <<EOF > values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone-1
       kdsGlobalAddress: grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443
       konnect:
         cpId: $CONTROL_PLANE_ID
       secrets:
         - Env: KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_INLINE
           Secret: cp-token
           Key: token
     ingress:
       enabled: true
     egress:
       enabled: true
   EOF
   ```

1. Apply the new configuration to the existing zone control plane:

   ```sh
   helm upgrade --kube-context $ZONE_CONTEXT --namespace {{site.mesh_namespace}} {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}} -f values.yaml
   ```

   {{site.konnect_short_name}} automatically detects and displays the zone once it reconnects.

## Validate

In {{site.konnect_short_name}}, confirm the migrated zone is connected:

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Confirm that the migrated zone appears with an **Online** status.
1. Confirm that the meshes, policies, and data plane proxies you transferred are present.
