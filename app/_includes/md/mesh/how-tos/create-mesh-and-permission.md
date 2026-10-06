Install a [kongctl build with {{site.mesh_product_name}} 3.x support](/mesh/cli/) and log in to the same {{site.konnect_short_name}} organization:

```sh
kongctl login
kongctl get mesh resource-types --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```

Create a new `konnect-demo` mesh, a demo identity provider, and permission for the `client`
ServiceAccount to call the `server` workload. Apply these resources to the **global** control
plane, not directly to the Kubernetes zone:

```sh
cat <<'EOF' | kongctl create mesh -f - --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
type: Mesh
name: konnect-demo
---
type: MeshIdentity
mesh: konnect-demo
name: demo-identity
spec:
  selector:
    dataplane: {}
  spiffeID:
    trustDomain: konnect-demo.mesh.local
  provider:
    type: Bundled
    bundled:
      autogenerate:
        enabled: true
      insecureAllowSelfSigned: true
      meshTrustCreation: Enabled
---
type: MeshTrafficPermission
mesh: konnect-demo
name: client-to-server
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: server
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://konnect-demo.mesh.local/ns/kong-mesh-demo/sa/client
EOF
```

`MeshIdentity` issues certificates and publishes their CA in `MeshTrust`. This example accepts
a generated self-signed CA for the demo; review your production PKI requirements before reusing
it. The identity's trust domain plus the Kubernetes namespace and ServiceAccount determine
the caller ID. Only that caller is allowed to reach proxies labelled `app: server`.

Wait for the identity's readiness conditions and generated trust before deploying workloads:

```sh
kongctl get mesh meshidentities demo-identity --mesh konnect-demo -o yaml \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
kongctl get mesh meshtrusts --mesh konnect-demo \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```
