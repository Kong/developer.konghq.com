The Fundamentals path enabled mTLS by flipping a single switch on the `Mesh` resource. That's the right starting point — every sidecar gets a cert from the built-in CA, traffic is encrypted, mutual auth works. But once Kong Air's security team starts asking compliance questions ("which CA issued the cert for the booking service in EU-West?", "can we use SPIRE for production but a self-signed CA in dev?"), the mesh-wide model runs out of expressiveness.

That's the gap **Workload Identity** fills.

### One mesh-wide CA, vs. three distinct resources

| Concern | Mesh-wide mTLS (Fundamentals) | Workload Identity |
| --- | --- | --- |
| Who issues certs? | The `Mesh.spec.mtls.backends[0]` block. One backend per mesh. | `MeshIdentity` — _multiple_ per mesh, each targeting a selector. |
| Who trusts which CAs? | Implicit: the mesh trusts its own CA. | `MeshTrust` — explicit, multi-CA bundles per trust domain. |
| How is mTLS enforced on the wire? | Implicit in the `Mesh.spec.mtls` block. | `MeshTLS` — separate policy, can vary per `targetRef`. |
| SPIFFE ID format? | Fixed: `spiffe://<mesh>/<service-tag>`. | Fully customizable trust domain + path template. |

The model decomposes one knob into three orthogonal resources. The payoff is that each can vary independently:

- Use SPIRE for the production trust domain, the built-in `Bundled` provider for staging — both in the same mesh.
- Distribute a new Root CA via `MeshTrust` weeks before you start re-issuing certs from it, so the cutover is incremental.
- Apply `MeshTLS: Strict` only to namespaces that have completed migration.

### `MeshIdentity` — who you are

`MeshIdentity` answers the question "how does this workload obtain its identity?" It pairs a **selector** (which sidecars this policy applies to) with a **provider** (where the certs come from) and a **SPIFFE ID template** (what the cert says).

```yaml
spec:
  selector:
    dataplane:
      matchLabels:
        app: flight-control      # Which workloads
  provider:
    type: Spire                  # Where certs come from
    spire:
      agent:
        timeout: 5s
  spiffeID:
    trustDomain: internal.kongair.com
    path: /{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}            # What the cert says
```

Three providers are supported:

| Provider | Use when |
| --- | --- |
| `Bundled` | The CP holds the CA cert + private key as Kubernetes Secrets (or files in Universal). Simplest, works everywhere. |
| `Spire` | Production environments that need node attestation, hardware-backed keys (TPM), or federation with non-mesh SPIRE workloads. |
| `External` providers (Vault, cert-manager, ACM) | Covered in Step 3 — the CP delegates issuance to your enterprise PKI. |

{% warning %}
On **Kubernetes**, `MeshIdentity` resources must live in the **system namespace** (typically `kong-mesh-system`). They're infrastructure-level — the CA configuration for a whole class of workloads — and the system-namespace requirement keeps that authority with platform engineers, not application teams. Apply `MeshIdentity` in an application namespace and the resource is silently ignored.
{% endwarning %}

### `MeshTrust` — who you trust

`MeshIdentity` is about _obtaining_ a certificate. `MeshTrust` is about _trusting_ certificates. A `MeshTrust` resource declares one or more CA bundles for a trust domain — and any sidecar whose `MeshTLS` policy points at that trust domain will accept certs signed by any of those CAs.

The decoupling unlocks two operations that are painful in monolithic mTLS:

1. **CA rotation without re-issuance.** Add a new CA to the bundle, wait for it to propagate, _then_ flip `MeshIdentity` to use it. Old certs keep working until they expire naturally.
2. **Cross-mesh / cross-cloud trust.** Add a partner organisation's root CA to the bundle; sidecars on both sides now mutually authenticate, no shared CP required.

### `MeshTLS` — what's enforced on the wire

`MeshTLS` is the third leg of the tripod and controls the actual TLS behaviour at the sidecar.

```yaml
spec:
  targetRef:
    kind: Mesh
  default:
    mode: Strict   # Reject non-mTLS traffic outright
```

The modes are:

| Mode | Behaviour |
| --- | --- |
| `Permissive` | Accept both plain and mTLS traffic. Useful during migration — old non-mesh callers still work. |
| `Strict` | Reject anything that isn't a valid mesh-issued mTLS connection. |

A typical migration path is to start `Permissive`, let every workload pick up its `MeshIdentity`, then flip the mesh to `Strict` once you've verified there's no plaintext traffic left in the access logs.

### Prerequisite: Exclusive mode

`MeshIdentity` requires the mesh to be in `meshServices.mode: Exclusive`. This disables the legacy `kuma.io/service`-tag-based identity model and tells the CP that every service has a first-class `MeshService` resource (which you already covered in Step 4 of Fundamentals). If your mesh is still in the default `Compatibility` mode, switching to `Exclusive` is the first thing to do.

### Further reading

- [`MeshIdentity` reference](/mesh/policies/meshidentity/)
- [`MeshTrust` reference](/mesh/policies/meshtrust/)
- [`MeshTLS` reference](/mesh/policies/meshtls/)
- [SPIFFE/SPIRE integration](/mesh/spire/)
