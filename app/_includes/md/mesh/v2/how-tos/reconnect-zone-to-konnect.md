1. Store the zone token in a Kubernetes secret:

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
   " | kubectl {% if include.zone_context %}--context {{ include.zone_context }} {% endif %}apply -f -
   ```

1. Create a Helm values file that connects the zone to {{site.konnect_short_name}}. Use the same zone name as your existing zone:

   ```sh
   cat <<EOF > values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: {{ include.zone_name | default: 'zone-1' }}
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
   helm upgrade {% if include.zone_context %}--kube-context {{ include.zone_context }} {% endif %}--namespace {{site.mesh_namespace}} {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}} -f values.yaml
   ```

   {{site.konnect_short_name}} automatically detects and displays the zone once it reconnects.
