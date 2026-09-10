Create a `MeshTrafficPermission`:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: mtp
  namespace: kong-mesh-demo
  labels:
    kuma.io/mesh: default
spec:
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/kong-mesh-demo" | kubectl apply -f -
```

This `MeshTrafficPermission` uses SPIFFE ID matching to allow traffic from workloads whose SPIFFE ID starts with `spiffe://default.default.mesh.local/ns/kong-mesh-demo`.

Based on the template in the `MeshIdentity`, every workload has a SPIFFE ID with this prefix in:

- The `default` mesh
- The `kong-mesh-demo` namespace.

You can also allow only workloads matching their exact SPIFFE ID for more fine-grained control.
