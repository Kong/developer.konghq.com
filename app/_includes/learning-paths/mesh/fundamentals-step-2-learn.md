By default, {{site.mesh_product_name}} ships with mTLS **disabled** and an `allow-all` traffic permission. That's a permissive starting state designed to let you stand up a mesh without breaking anything — but it's not where you want to stay. Kong Air's security team requires every flight-critical request to be encrypted, mutually authenticated, and explicitly authorized.

This step covers the two policy concepts that get you there: enabling **mTLS** on the `Mesh` resource, and using **`MeshTrafficPermission`** to authorize traffic.

### What mTLS gives you, for free

When you enable mTLS on a `Mesh`, every Envoy sidecar in that mesh:

- Encrypts all service-to-service traffic with TLS 1.3.
- Receives a short-lived X.509 / SPIFFE certificate that identifies the service it fronts.
- Rotates that certificate automatically — no application changes, no cert-manager wiring.
- Refuses any inbound connection that doesn't present a valid mesh-issued cert.

The `builtin` mTLS backend used in this step issues certificates from {{site.mesh_product_name}}'s own CA. Step 9 of the broader curriculum covers swapping that for an enterprise root like HashiCorp Vault; for now, `builtin` is the right starting point.

### `MeshTrafficPermission`: explicit allow vs. default deny

mTLS encrypts traffic but doesn't decide who can talk to whom. That's what `MeshTrafficPermission` is for. The resource has a simple shape:

- `targetRef` — which workloads the permission applies to (the receivers).
- `from` — which sources are allowed (or denied) to reach them.
- `default.action` — `Allow` or `Deny`.

A fresh mesh comes with one of these named `allow-all`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-all
  namespace: kong-mesh-system
spec:
  targetRef: { kind: Mesh }
  from:
    - targetRef: { kind: Mesh }
      default: { action: Allow }
```

It says: _every_ workload may reach _every_ workload. Useful while you're getting set up; the opposite of zero-trust in production.

To move to zero-trust, you do two things:

1. Replace `allow-all` with a mesh-wide `default-deny`.
2. Add narrow `Allow` policies for the specific service-to-service flows your applications actually need.

### The "Allow wins" precedence rule

A subtle gotcha: when an `Allow` policy and a `Deny` policy both match the same workload, **Allow always wins**. So you can't enforce default-deny just by adding a deny policy on top of `allow-all` — you have to delete the `allow-all` first.

{% warning %}
This is the single most common mistake when first setting up zero-trust on {{site.mesh_product_name}}. If your default-deny seems to have no effect, double-check that `allow-all` is gone.
{% endwarning %}

### Where enforcement happens

`MeshTrafficPermission` is enforced on the **server side** — the receiver's inbound listener. Two consequences worth knowing:

- The RBAC decision is made by the destination service's sidecar, not the source's.
- Denied traffic from the client side either times out or returns an explicit `403`, depending on the Envoy configuration of the destination.

### Further reading

- [`Mesh` resource reference](/mesh/policies/mesh/)
- [`MeshTrafficPermission` reference](/mesh/policies/meshtrafficpermission/)
- [How mTLS works in {{site.mesh_product_name}}](/mesh/mtls/)
