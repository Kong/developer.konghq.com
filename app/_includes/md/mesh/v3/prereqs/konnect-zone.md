{% assign zone_name = include.zone_name | default: 'zone1' %}
{% assign mesh_name = include.mesh_name | default: 'kong-air-mesh' %}
A `Mesh` is a global resource, so you create it on the {{site.konnect_short_name}}-hosted global control plane with kongctl. Your Kubernetes cluster then joins that control plane as a zone and receives the mesh over KDS.

1. Create the `{{ mesh_name }}` mesh on the global control plane:

   ```sh
   kongctl apply mesh --control-plane-name "$MESH_CP" -f - <<'EOF'
   type: Mesh
   name: {{ mesh_name }}
   EOF
   ```

   kongctl reports `created`. Re-running the command reports `updated`, because a mesh write is an upsert.

1. Export your {{site.konnect_short_name}} geographic region and the KDS address your zone connects to:

   ```sh
   export KONNECT_REGION='us'
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   ```

1. Export the identifier of your control plane. To print identifiers in full, run `kongctl get mesh control-planes --text-id-format full`:

   ```sh
   export CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
   ```

1. Issue a zone token, which is how the zone control plane proves its identity when it joins:

   ```sh
   kongctl create mesh zone-token \
     --control-plane-name "$MESH_CP" \
     --zone {{ zone_name }} \
     --valid-for 720h > zone-token
   ```

1. Store the token in a Kubernetes secret:

   ```sh
   kubectl create namespace kong-mesh-system
   kubectl create secret generic cp-token \
     -n kong-mesh-system \
     --from-file=token=zone-token
   ```

1. Create the Helm values file. The `meshes` list tells the zone control plane which meshes to deploy zone ingress and egress listeners for:

   ```sh
   cat <<EOF > values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: {{ zone_name }}
       kdsGlobalAddress: $CONTROL_PLANE_URL
       konnect:
         cpId: $CONTROL_PLANE_ID
       secrets:
         - Env: KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_INLINE
           Secret: cp-token
           Key: token
     meshes:
       - name: {{ mesh_name }}
         ingress:
           enabled: true
         egress:
           enabled: true
   EOF
   ```

1. Install {{site.mesh_product_name}}:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   helm upgrade --install \
     --namespace kong-mesh-system \
     kong-mesh kong-mesh/kong-mesh -f values.yaml
   kubectl wait -n kong-mesh-system --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=90s
   ```

1. Confirm the zone joined the global control plane and that the mesh synced down:

   ```sh
   kubectl get meshes
   ```

   `{{ mesh_name }}` appears in the output once KDS has delivered it, which proves the zone is connected.
