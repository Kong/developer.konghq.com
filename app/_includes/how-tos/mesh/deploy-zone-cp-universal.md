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
1. Save the control plane token to a file:

   ```sh
   echo $CONTROL_PLANE_TOKEN > cpTokenFile && chmod 600 cpTokenFile
   ```

1. Create the zone configuration file:

   ```sh
   cat <<EOF > config.yaml
   environment: universal
   mode: zone
   multizone:
     zone:
       name: {{ include.zone_name | default: 'zone-1' }}
       globalAddress: $CONTROL_PLANE_URL
   kmesh:
     multizone:
       zone:
         konnect:
           cpId: $CONTROL_PLANE_ID
   experimental:
     kdsDeltaEnabled: true
   EOF
   ```

1. Download and install {{site.mesh_product_name}}:

   ```sh
   curl -L http://developer.konghq.com/mesh/installer.sh | sh -
   ```

1. Start the zone control plane in the background, so you can keep using the same terminal (and its exported variables) for the following steps:

   ```sh
   KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_PATH=cpTokenFile kong-mesh-*/bin/kuma-cp run --config-file config.yaml > kuma-cp.log 2>&1 &
   ```

   {:.info}
   > The control plane keeps running in the background and its output goes to `kuma-cp.log`. Check that file if the zone doesn't connect. To stop it later, run `pkill -f kuma-cp`.
