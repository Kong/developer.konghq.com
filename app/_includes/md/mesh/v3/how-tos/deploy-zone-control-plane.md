{% if include.platform == 'kubernetes' %}
1. Set the KDS address for the same region as the global control plane, and create a working directory:

   ```sh
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   export MESH_INSTALL_DIR=$(mktemp -d)
   ```

1. Change to the working directory:

   ```sh
   cd "$MESH_INSTALL_DIR"
   ```

1. Make the files you create from now on readable only by you:

   ```sh
   umask 077
   ```

1. Add the {{site.mesh_product_name}} Helm repository:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   ```

1. Update the repository index:

   ```sh
   helm repo update
   ```

1. List the available chart versions:

   ```sh
   helm search repo kong-mesh/kong-mesh --versions --devel
   ```

   Select an available {{site.mesh_product_name}} 3.x chart version approved for your {{site.konnect_short_name}} control plane. Helm chart
   versions and application versions are different: check the `APP VERSION` column for 3.x.

1. Export the chart version you selected:

   ```sh
   export MESH_CHART_VERSION='REPLACE_WITH_CHART_VERSION_FOR_MESH_3'
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
     --namespace kong-mesh-system --version "$MESH_CHART_VERSION" \
     --values values.yaml --wait --timeout 5m
   ```

   This installs a zone, not a Kubernetes-native global control plane. It does not enable the
   removed shared `kuma.ingress` or `kuma.egress` deployments.{% unless include.zone_proxies %} This single-zone test does not need
   zone proxies; add [mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/) when connecting
   zones or using `MeshExternalService`.{% endunless %}
{% else %}
1. Set the KDS address for the same region as the global control plane, and create a working directory:

   ```sh
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   export MESH_INSTALL_DIR=$(mktemp -d)
   ```

1. Change to the working directory:

   ```sh
   cd "$MESH_INSTALL_DIR"
   ```

1. Make the files you create from now on readable only by you:

   ```sh
   umask 077
   ```

1. Set the {{site.mesh_product_name}} 3.x release approved for your {{site.konnect_short_name}} control plane. Set an explicit version
   instead of relying on the installer's default:

   ```sh
   export MESH_VERSION='{{page.latest_release.version}}'
   ```

1. Download and run the installer:

   ```sh
   curl --fail -L https://developer.konghq.com/mesh/installer.sh | VERSION="$MESH_VERSION" sh
   ```

1. Write the zone token to a file:

   ```sh
   printf '%s' "$CONTROL_PLANE_TOKEN" > cp-token
   ```

1. Make the token file readable only by you:

   ```sh
   chmod 600 cp-token
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

   The in-memory store is for this single-process evaluation only. Use PostgreSQL and plan
   persistence and availability for production; see the [Universal control plane reference](/mesh/universal-control-plane/).

1. Run the control plane in the foreground:

   ```sh
   KUMA_MULTIZONE_ZONE_KDS_AUTH_TOKEN_PATH="$MESH_INSTALL_DIR/cp-token" \
     "$MESH_INSTALL_DIR/kong-mesh-$MESH_VERSION/bin/kuma-cp" run --config-file config.yaml
   ```

   Keep this terminal open. Use another terminal or the {{site.konnect_short_name}} UI to check the connection.
{% endif %}
