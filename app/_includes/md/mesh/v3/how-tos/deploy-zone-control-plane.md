{% if include.platform == 'kubernetes' %}
1. Set the KDS address for the same region as the global control plane, and create a working directory:

   ```sh
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   export MESH_INSTALL_DIR=$(mktemp -d)
   cd "$MESH_INSTALL_DIR"
   ```

1. Add the {{site.mesh_product_name}} Helm repository:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   ```

1. Create the zone namespace:

   ```sh
   kubectl create namespace kong-mesh-system
   ```

1. Store the zone token in a Secret:

   ```sh
   kubectl -n kong-mesh-system create secret generic cp-token \
     --from-literal=token="$CONTROL_PLANE_TOKEN"
   ```

1. Create `values.yaml`:

   ```sh
   cat <<EOF > values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone-1
       kdsGlobalAddress: $CONTROL_PLANE_URL
       konnect:
         cpId: $CONTROL_PLANE_ID
       zoneToken:
         secretName: cp-token
         key: token
   EOF
   ```

1. Install the zone control plane:

   ```sh
   helm upgrade --install kong-mesh kong-mesh/kong-mesh \
     --namespace kong-mesh-system --version "{{page.latest_release.version}}" \
     --values values.yaml --wait --timeout 5m
   ```

   {% unless include.zone_proxies %} This single-zone test doesn't need zone proxies; add [mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/) when connecting
   zones or using `MeshExternalService`.{% endunless %}
{% else %}
1. Set the KDS address for the same region as the global control plane, and create a working directory:

   ```sh
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   export MESH_INSTALL_DIR=$(mktemp -d)
   cd "$MESH_INSTALL_DIR"
   ```

1. Download and run the installer:

   ```sh
   curl --fail -L https://developer.konghq.com/mesh/installer.sh | VERSION="{{page.latest_release.version}}" sh
   ```

1. Write the zone token to a file:

   ```sh
   printf '%s' "$CONTROL_PLANE_TOKEN" > cp-token
   ```

1. Create `config.yaml`:

   ```sh
   cat <<EOF > config.yaml
   environment: universal
   mode: zone
   store:
     type: memory
   multizone:
     zone:
       name: zone-1
       globalAddress: $CONTROL_PLANE_URL
   kmesh:
     multizone:
       zone:
         konnect:
           cpId: $CONTROL_PLANE_ID
   EOF
   ```

   Use `store.type: memory` for testing purposes only. In a production environment, use PostgreSQL and plan
   persistence and availability. For more information, see the [Universal control plane reference](/mesh/universal-control-plane/).

1. Start the control plane in the background and write its output to `kuma-cp.log`:

   ```sh
   KUMA_MULTIZONE_ZONE_KDS_AUTH_TOKEN_PATH="$MESH_INSTALL_DIR/cp-token" \
     nohup "$MESH_INSTALL_DIR/kong-mesh-$MESH_VERSION/bin/kuma-cp" run --config-file config.yaml \
     > kuma-cp.log 2>&1 &
   echo $! > kuma-cp.pid
   ```

1. Wait for the control plane to report that it's ready:

   ```sh
   curl --fail --silent --retry 30 --retry-delay 2 --retry-connrefused http://localhost:5680/ready
   ```

   If the command fails, check `kuma-cp.log` for the startup error.
{% endif %}
