1. Create and navigate to the working directory for this guide:

   ```sh
   mkdir -p ~/mesh-konnect && cd ~/mesh-konnect
   ```

{% if include.show_exports -%}
1. Export the KDS global address for your region:

   ```sh
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   ```

{% endif -%}
1. Create the `kong-mesh-system` namespace:

   ```sh
   kubectl create namespace kong-mesh-system
   ```

1. Add the {{site.mesh_product_name}} Helm repository:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   ```

1. Update your Helm repositories:

   ```sh
   helm repo update
   ```

1. Store the control plane token in a Kubernetes secret:

   ```sh
   echo "
   apiVersion: v1
   kind: Secret
   metadata:
     name: cp-token
     namespace: kong-mesh-system
   type: Opaque
   stringData:
     token: $CONTROL_PLANE_TOKEN
   " | kubectl apply -f -
   ```

1. Create the Helm values file:

   ```sh
   cat <<EOF > values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: {{ include.zone_name | default: 'zone-1' }}
       kdsGlobalAddress: $CONTROL_PLANE_URL
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

1. Install {{site.mesh_product_name}}:

   ```sh
   helm upgrade --install -n kong-mesh-system kong-mesh kong-mesh/kong-mesh -f values.yaml
   ```
