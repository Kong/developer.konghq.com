The self-signed CA you stood up in Step 2 is fine for a development mesh, but Kong Air's compliance reviewers won't sign off on it for production. Production identities need to be issued by the corporate PKI — typically HashiCorp Vault, cert-manager, or AWS Private CA. {{site.mesh_product_name}} supports all three plus a "Bundled" mode where you provide raw cert + key material from any external CA.

This step covers _why_ each integration shape exists and _when_ to reach for which.

### The four backend shapes

| Backend | Where issuance happens | Best for |
| --- | --- | --- |
| **Built-in** | The Control Plane is itself the CA. | Dev meshes, sandboxes, anywhere a corporate Root CA isn't a constraint. |
| **cert-manager** | The CP requests certs via the Kubernetes API; cert-manager issues them. | Kubernetes-native shops already running cert-manager. |
| **Vault (`fromCp`)** | The CP authenticates to Vault and requests certs from a PKI role. | Enterprises standardized on Vault for all certs. |
| **ACM Private CA** | The CP calls AWS Private Certificate Authority. | AWS-heavy environments wanting AWS-native key custody. |
| **Bundled (external CA)** | You hand the CP a cert + key from any CA. | Air-gapped meshes, smartcard-issued enterprise roots, anywhere the CA itself can't be wired in directly. |

The first three plus ACM hook in via the legacy `Mesh.spec.mtls.backends` block. **Bundled** is the modern Workload Identity equivalent — it goes through `MeshIdentity` from Step 2.

### Why Vault needs `fromCp` and `dpCert` but cert-manager doesn't

This is the single most confusing thing about external CAs in {{site.mesh_product_name}}. It comes down to one architectural decision: **who talks to the CA?**

#### cert-manager: platform-native

cert-manager is a Kubernetes controller. The {{site.mesh_product_name}} Control Plane is _also_ a Kubernetes controller. They speak the same Kubernetes API, share the same RBAC model, and use the same `ServiceAccount` identity. The CP creates a `CertificateRequest`, cert-manager signs it using an `Issuer` you've defined, the CP gets the cert back. No extra config needed.

```yaml
mtls:
  enabledBackend: cert-manager-ca
  backends:
    - name: cert-manager-ca
      type: cert-manager
      certManager:
        issuerName: corporate-issuer
        issuerKind: ClusterIssuer
```

That's it. The Issuer holds the TTL, the CA material, the signing config.

#### Vault: external API

Vault lives outside Kubernetes — it has its own auth model (Vault tokens, AppRole, K8s auth), its own RBAC, its own API surface. Two implications:

1. **Someone has to authenticate to it.** Putting Vault tokens on every Data Plane proxy is exactly the kind of secret-distribution problem you're trying to avoid. {{site.mesh_product_name}}'s answer is `fromCp`: the **Control Plane** authenticates, requests certs on behalf of the data planes, and ships the cert material out via xDS. Data planes never see Vault.

2. **Vault's `pki/issue` API requires a TTL at request time** (unlike cert-manager, where the TTL lives on the Issuer). The `dpCert.rotation.expiration` field tells the CP what TTL to ask for on each cert issuance:

```yaml
mtls:
  enabledBackend: vault-ca
  backends:
    - name: vault-ca
      type: vault
      dpCert:
        rotation:
          expiration: 1d         # Required — TTL the CP requests from Vault
      conf:
        fromCp:                  # Required — CP, not DPs, talks to Vault
          address: https://vault.default:8200
          role: mesh-dp
          auth:
            token: { secret: vault-token }
```

If you forget `fromCp`, the CP doesn't know who's supposed to talk to Vault and the integration silently does nothing. If you forget `dpCert.rotation.expiration`, the CP's calls to Vault are missing a required field and they fail.

### Three architectures, side by side

#### Built-in (no external dependency)

{% mermaid %}
sequenceDiagram
    participant DP as Data Plane
    participant CP as Control Plane (acting as CA)
    DP->>CP: Request identity
    CP->>CP: Self-sign certificate
    CP->>DP: Push cert via xDS
{% endmermaid %}

#### cert-manager (Kubernetes-native)

{% mermaid %}
sequenceDiagram
    participant DP as Data Plane
    participant CP as Control Plane
    participant CM as cert-manager + Issuer
    DP->>CP: Request identity
    CP->>CM: Create CertificateRequest
    CM->>CM: Sign using ClusterIssuer
    CM-->>CP: Return signed cert
    CP->>DP: Push cert via xDS
{% endmermaid %}

#### Vault (`fromCp`)

{% mermaid %}
sequenceDiagram
    participant DP as Data Plane
    participant CP as Control Plane
    participant V as Vault PKI
    DP->>CP: Request identity
    CP->>CP: Generate private key + CSR
    CP->>V: Authenticate (token / K8s auth)
    CP->>V: POST /v1/pki/sign (CSR, TTL=dpCert.rotation.expiration)
    V-->>CP: Return signed cert
    CP->>DP: Push cert via xDS
{% endmermaid %}

The data plane's view is identical in all three cases: "I asked the CP for an identity, I got one back." Only the CP's _implementation_ of issuance changes.

### Migration path: built-in → external CA

Step 2 left Kong Air on a self-signed CA. To move to Vault (or cert-manager, or ACM) safely:

1. **Add the new CA to the trust bundle.** Update `MeshTrust` so sidecars trust _both_ the old and new CAs. Apply, wait for KDS sync.
2. **Re-issue identities under the new CA.** Update `MeshIdentity` (or `Mesh.spec.mtls`) to use the new backend. Sidecars start receiving certs from the new CA on their next rotation.
3. **Wait for the old certs to expire**, or force a rotation if you can't wait.
4. **Remove the old CA from the trust bundle.** Now only the new CA is trusted.

The whole sequence is incremental — at every step, the mesh has at least one valid identity-issuance path and at least one trusted CA. No window where mTLS is broken.

### Further reading

- [Built-in mTLS backends reference](/mesh/mtls/)
- [HashiCorp Vault integration](/mesh/mtls/vault/)
- [cert-manager integration](/mesh/mtls/cert-manager/)
- [AWS ACM Private CA integration](/mesh/mtls/acm/)
- [Migrating between CA backends](/mesh/mtls/migration/)
