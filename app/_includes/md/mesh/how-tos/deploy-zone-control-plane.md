Set the KDS address for the same region as the global control plane:

```sh
export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
export MESH_INSTALL_DIR=$(mktemp -d)
cd "$MESH_INSTALL_DIR"
umask 077
```

{% if include.platform == 'kubernetes' %}
Select an available {{site.mesh_product_name}} 3.x chart version approved for your {{site.konnect_short_name}} control plane. Helm chart
versions and application versions are different: check the `APP VERSION` column for 3.x.

```sh
helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
helm repo update
helm search repo kong-mesh/kong-mesh --versions --devel
export MESH_CHART_VERSION='REPLACE_WITH_CHART_VERSION_FOR_MESH_3'
kubectl create namespace kong-mesh-system
kubectl -n kong-mesh-system create secret generic cp-token \
  --from-literal=token="$CONTROL_PLANE_TOKEN"
```

Create `values.yaml`:

```sh
cat <<EOF > values.yaml
kuma:
  controlPlane:
    mode: zone
    zone: zone-1
    kdsGlobalAddress: $CONTROL_PLANE_URL
    konnect:
      cpId: $CONTROL_PLANE_ID
    secrets:
      - Env: KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_INLINE
        Secret: cp-token
        Key: token
EOF
helm upgrade --install kong-mesh kong-mesh/kong-mesh \
  --namespace kong-mesh-system --version "$MESH_CHART_VERSION" \
  --values values.yaml --wait --timeout 5m
```

This installs a zone, not a Kubernetes-native global control plane. It does not enable the
removed shared `kuma.ingress` or `kuma.egress` deployments. This single-zone test does not need
zone proxies; add [mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/) when connecting
zones or using `MeshExternalService`.
{% else %}
Download the {{site.mesh_product_name}} 3.x release approved for your {{site.konnect_short_name}} control plane. Set an explicit version
instead of relying on the installer's default:

```sh
export MESH_VERSION='REPLACE_WITH_MESH_3_RELEASE_VERSION'
curl --fail -L https://developer.konghq.com/mesh/installer.sh | VERSION="$MESH_VERSION" sh
printf '%s' "$CONTROL_PLANE_TOKEN" > cp-token
chmod 600 cp-token
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

Run the control plane in the foreground:

```sh
KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_PATH="$MESH_INSTALL_DIR/cp-token" \
  "$MESH_INSTALL_DIR/kong-mesh-$MESH_VERSION/bin/kuma-cp" run --config-file config.yaml
```

Keep this terminal open. Use another terminal or the {{site.konnect_short_name}} UI to check the connection.
{% endif %}
