Install a [kongctl build with {{site.mesh_product_name}} 3.x support](/mesh/cli/) and log in to the same {{site.konnect_short_name}} organization:

```sh
kongctl login
```

Confirm that `kongctl` can reach the global control plane:

```sh
kongctl get mesh resource-types --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```

Create a new `konnect-demo` mesh and a demo identity provider on the **global** control plane.
You can only create a mesh there, and an identity created on the global control plane reaches
every zone. Setting `trustDomain` explicitly gives all zones one trust domain; the default trust
domain includes the zone name:

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
EOF
```

`MeshIdentity` issues certificates and publishes their CA in `MeshTrust`. This example accepts
a generated self-signed CA for the demo; review your production PKI requirements before reusing
it. The identity's trust domain plus the Kubernetes namespace and ServiceAccount determine
the caller ID. You can't change `spiffeID.trustDomain` or `spiffeID.path` after creation; to use
a different trust domain, create a new `MeshIdentity` with a different name.

Wait for the identity's readiness conditions and generated trust before deploying workloads.
Check the identity:

```sh
kongctl get mesh meshidentities demo-identity --mesh konnect-demo -o yaml \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```

Check the generated trust:

```sh
kongctl get mesh meshtrusts --mesh konnect-demo \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```

You manage most policies at the zone level. Confirm that the new mesh has synced to the
Kubernetes zone:

```sh
kubectl get mesh konnect-demo
```

Then allow the `client` ServiceAccount to call the `server` workload by applying a
`MeshTrafficPermission` directly to the zone. A policy created in `{{site.mesh_namespace}}` on a
zone control plane applies to the whole zone. The zone adds the `kuma.io/origin: zone` label if
you omit it:

```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: client-to-server
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: konnect-demo
    kuma.io/origin: zone
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

Only that caller can reach proxies labeled `app: server`.
