---
title: "Enterprise PKI: External CA Integration"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Move beyond the built-in CA. Learn how to integrate {{site.mesh_product_name}} with enterprise PKI solutions like HashiCorp Vault and cert-manager for automated certificate management.
products:
  - mesh
tldr:
  q: How do I integrate my mesh with an enterprise Certificate Authority?
  a: |
    Root your mesh identity in an external CA through `MeshIdentity`, in one of two ways:
    1. **Bundled provider**: you supply the CA cert and key, and {{site.mesh_product_name}} signs from it.
    2. **Extension providers**: {{site.mesh_product_name}} delegates signing to cert-manager, HashiCorp Vault, or AWS Private CA, so the CA key never leaves that system.
next_steps:
  - text: "Multi-Zone Architecture"
    url: "/mesh/scenarios/multi-zone-architecture/"
---
Using an external CA ensures that Kong Air's service identities are governed by the same corporate PKI standards as their physical servers and employee devices.

{% tip %}
The `MeshIdentity` and `MeshTrust` resources in this guide are **system-namespace** resources. On a Zone CP federated to a Global CP, create them in `{{site.mesh_namespace}}` with the `kuma.io/origin: zone` label (shown in every example below). See the [Resource Scoping guide](/mesh/scenarios/resource-scoping/) for which control plane to target.
{% endtip %}

## 1. Why Use an External CA?

*   **Compliance**: Many organizations mandate that all certificates must be issued by a specific authority (for example HashiCorp Vault or a corporate Sub-CA).
*   **Hardened Security**: External CAs often live on hardware security modules or in highly restricted environments.
*   **Auditability**: Centralize all certificate issuance logs in a single location rather than having them scattered across local clusters.

## 2. Two Ways to Bring Your Own CA

Both approaches are configured through `MeshIdentity`. They place the resource in the system namespace and issue SPIFFE certificates using the same `spiffeID.path` and `trustDomain` fields, only the `provider` block differs.

| Approach | How it works | When to use |
| :--- | :--- | :--- |
| **Bundled provider** | You hand {{site.mesh_product_name}} the CA certificate and private key. The control plane holds the key and signs every workload certificate from it. | The simplest path. Good when you already have CA material you can place in the cluster. |
| **Extension providers** | The control plane delegates signing to an external system (cert-manager, HashiCorp Vault, AWS Private CA) on each rotation. The CA private key never leaves that system. | Enterprise PKI, where the CA key must stay in your existing system. Requires {{site.mesh_product_name}} enterprise. |

## 3. Bundled Provider

You provide an externally-managed CA certificate and private key as {{site.mesh_product_name}} Secrets, and the control plane signs all workload certificates from them.

{% warning %}
The CA cert and key are referenced as **{{site.mesh_product_name}} Secrets**, not native Kubernetes TLS Secrets. A {{site.mesh_product_name}} Secret is a standard Kubernetes `Secret` with `type: system.kuma.io/secret` and a single `value` key holding the raw PEM (it is **not** a `kubernetes.io/tls` Secret). Create them in the system namespace (`{{site.mesh_namespace}}`) with the `kuma.io/mesh` label, the same namespace the `MeshIdentity` lives in.
{% endwarning %}

### Step 1: Create the {{site.mesh_product_name}} Secrets containing your CA cert and key

This example uses cert-manager to mint a self-signed CA, but any CA material works, substitute your corporate Sub-CA cert and key instead.

{% tip %}
This is **not** the same as the cert-manager *extension* in the next section. Here, cert-manager only generates a CA certificate that you then hand to the `Bundled` provider. The extension delegates live signing to cert-manager on every rotation.
{% endtip %}

```bash
# Bootstrap a self-signed root issuer
kubectl apply -f - <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
# Generate the CA cert, cert-manager stores it in a kubernetes.io/tls Secret
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kong-air-mesh-ca
  namespace: {{site.mesh_namespace}}
spec:
  isCA: true
  commonName: kong-air-mesh-ca
  duration: 87600h   # 10-year CA
  renewBefore: 720h  # cert-manager renews 30 days before expiry
  secretName: kong-air-mesh-ca-tls
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
EOF

kubectl wait --for=condition=ready certificate/kong-air-mesh-ca \
  -n {{site.mesh_namespace}} --timeout=30s
```

Then bridge the cert-manager Secret to a {{site.mesh_product_name}} Secret. {{site.mesh_product_name}} reads `data.value` (raw PEM) from `system.kuma.io/secret` type Secrets:

```bash
# Extract PEM values from the cert-manager TLS Secret
CERT_PEM=$(kubectl get secret kong-air-mesh-ca-tls \
  -n {{site.mesh_namespace}} -o jsonpath='{.data.tls\.crt}' | base64 -d)
KEY_PEM=$(kubectl get secret kong-air-mesh-ca-tls \
  -n {{site.mesh_namespace}} -o jsonpath='{.data.tls\.key}' | base64 -d)

# Create {{site.mesh_product_name}} Secrets, note type: system.kuma.io/secret and the value key
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: kong-air-external-ca-cert
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
type: system.kuma.io/secret
stringData:
  value: |
$(echo "$CERT_PEM" | sed 's/^/    /')
---
apiVersion: v1
kind: Secret
metadata:
  name: kong-air-external-ca-key
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
type: system.kuma.io/secret
stringData:
  value: |
$(echo "$KEY_PEM" | sed 's/^/    /')
EOF
```

{% tip %}
For production, automate this sync with an external-secrets operator or a cert-manager `ExternalSecret` so {{site.mesh_product_name}} Secrets stay up-to-date when cert-manager rotates the CA.
{% endtip %}

### Step 2: Create the MeshIdentity

Point the `Bundled` provider at the two {{site.mesh_product_name}} Secrets from Step 1:

{% navtabs "meshidentity-ca" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: flight-operations-id
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true # Required when CA is self-signed; omit for a corporate sub-CA
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-external-ca-cert  # Name of the {{site.mesh_product_name}} Secret (system.kuma.io/secret)
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-external-ca-key
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
        app: flight-control
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
    trustDomain: internal.kongair.com
EOF
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
kumactl apply -f - <<'EOF'
type: MeshIdentity
name: flight-operations-id
mesh: kong-air-mesh
spec:
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-external-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-external-ca-key
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
        app: flight-control
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
    trustDomain: internal.kongair.com
EOF
```
{% endnavtab %}
{% endnavtabs %}

**Verify:** After restarting the targeted workloads, check that the MeshService shows the new trust domain:

```bash
kubectl get meshservice flight-control -n kong-air-production \
  -o jsonpath='{.spec.identities}' | jq .
# Expected: includes "spiffe://internal.kongair.com/ns/kong-air-production/sa/flight-control"
```

## 4. Extension Providers

Instead of signing workload certs from a CA it holds, {{site.mesh_product_name}} delegates signing to an external system. The workload-facing `MeshIdentity` API stays unchanged, only `provider.type` and `extension.config` change. On each sidecar cert rotation, the control plane submits a signing request to the extension (cert-manager creates a `CertificateRequest`, Vault issues via its PKI engine), then delivers the signed cert to the sidecar via xDS. Kong Air can switch issuers by changing two fields, with no application restarts.

All three providers below share the same `spiffeID.path` and `trustDomain`, so the cert-manager example is shown end-to-end and the Vault and ACM examples show only the `provider` block that differs. Adapt the provider-specific config values to your environment.

### cert-manager

**Prerequisites:** cert-manager installed with a `ClusterIssuer` or `Issuer` for the mesh CA.

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml
kubectl wait --for=condition=ready pod -n cert-manager \
  -l app.kubernetes.io/instance=cert-manager --timeout=90s

# Create a SelfSigned bootstrap issuer, a CA Certificate, and the CA-backed Issuer
kubectl apply -f - <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kong-air-mesh-ca
  namespace: {{site.mesh_namespace}}
spec:
  isCA: true
  commonName: kong-air-mesh-ca
  duration: 87600h
  renewBefore: 720h
  secretName: kong-air-mesh-ca-secret
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: kong-air-mesh-ca-issuer
  namespace: {{site.mesh_namespace}}
spec:
  ca:
    secretName: kong-air-mesh-ca-secret
EOF

kubectl wait --for=condition=ready certificate/kong-air-mesh-ca \
  -n {{site.mesh_namespace}} --timeout=30s
```

Apply the `MeshIdentity`:

```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: kong-air-certmanager-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
        app: flight-control
  spiffeID:
    trustDomain: internal.kongair.com
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
  provider:
    type: Extension
    extension:
      name: certmanager
      config:
        issuerRef:
          name: kong-air-mesh-ca-issuer
          kind: Issuer
          group: cert-manager.io
EOF
```

**How it works:** {{site.mesh_product_name}} creates a `CertificateRequest` in `{{site.mesh_namespace}}` for each sidecar that needs a new identity cert. cert-manager approves and signs it using the configured `Issuer`, and the signed cert is delivered to the sidecar via xDS. CertificateRequests are cleaned up after use.

**Verify:**

```bash
# Watch for CertificateRequests being created and signed as workloads connect
kubectl get certificaterequests -n {{site.mesh_namespace}} -w

# After workloads restart, check SPIFFE IDs
kubectl get meshservice flight-control -n kong-air-production \
  -o jsonpath='{.spec.identities}' | jq .
```

### HashiCorp Vault

Delegates signing to a Vault PKI secrets engine. {{site.mesh_product_name}} authenticates to Vault and requests a certificate on each rotation. Only the `provider` block changes from the cert-manager example:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: vault-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
        app: flight-control
  spiffeID:
    trustDomain: internal.kongair.com
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
  provider:
    type: Extension
    extension:
      name: vault
      config:
        address: https://vault.example.com
        mountPath: pki
        role: kong-mesh-workload
```

### AWS Private CA

Delegates signing to AWS Private Certificate Authority (ACM PCA). Again, only the `provider` block differs:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: acm-pca-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
        app: flight-control
  spiffeID:
    trustDomain: internal.kongair.com
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
  provider:
    type: Extension
    extension:
      name: acmpca
      config:
        certificateAuthorityArn: arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/example
        region: us-east-1
```

{% tip %}
Every extension provider honors the same `spiffeID.path` and `trustDomain` fields. Only `extension.name` and the provider-specific `extension.config` keys change, so Kong Air can switch from cert-manager to Vault by editing two fields, without touching any application or policy config.
{% endtip %}

## 5. How Issuance Works

Each CA model integrates with the control plane differently. Knowing the flow helps you choose a provider and reason about where the CA private key lives.

In every model the **control plane** is the client that requests certificates from the CA, never the individual proxies. Workloads in private zones therefore need no direct network access to the CA, and no CA credentials are distributed to the data plane.

| Feature | cert-manager | HashiCorp Vault |
| :--- | :--- | :--- |
| **Platform** | Kubernetes-native | External API |
| **Authentication** | Kubernetes RBAC | Vault token / Kubernetes auth |
| **Client** | Control Plane (via K8s API) | Control Plane (via REST API) |

### Built-in CA (for contrast)

The control plane acts as the Certificate Authority. No external dependencies.

{% mermaid %}
sequenceDiagram
    participant DP as Data Plane (Proxy)
    participant CP as Control Plane (Manager)
    
    Note over DP, CP: In-mesh CA
    DP->>CP: 1. Request Identity
    CP->>CP: 2. CP acts as CA (Self-Signs)
    CP->>DP: 3. Push Identity via xDS
{% endmermaid %}

### cert-manager (platform-native)

The control plane uses Kubernetes-native cert-manager APIs.

{% mermaid %}
sequenceDiagram
    participant DP as Data Plane (Proxy)
    participant CP as Control Plane (Manager)
    participant CM as cert-manager (K8s API)
    
    Note over DP, CM: Platform Native Flow
    DP->>CP: 1. Start & Discover
    CP->>CM: 2. Create CertificateRequest
    CM->>CM: 3. Sign using ClusterIssuer
    CM-->>CP: 4. Return Signed Cert
    CP->>DP: 5. Push Identity via xDS
{% endmermaid %}

### HashiCorp Vault (external API)

The control plane authenticates to an external Vault API to request certificates.

{% mermaid %}
sequenceDiagram
    participant DP as Data Plane (Proxy)
    participant CP as Control Plane (Manager)
    participant V as HashiCorp Vault API
    
    Note over DP, V: Centralized Request flow
    DP->>CP: 1. Start & Discover
    CP->>CP: 2. Generate Private Key & CSR
    CP->>V: 3. Authentication (Token/K8s)
    CP->>V: 4. Request Certificate (CSR + TTL)
    V-->>CP: 5. Return Signed Certificate
    CP->>DP: 6. Push Identity via xDS
{% endmermaid %}

