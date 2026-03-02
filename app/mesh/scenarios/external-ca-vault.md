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
    Integrate Kong Mesh with **External CA providers** to:
    1. **Automate issuance** via HashiCorp Vault or cert-manager.
    2. **Root identity** in your existing corporate PKI.
    3. **Decouple trust** from the mesh management lifecycle.
next_steps:
  - text: "Multi-Zone Architecture"
    url: "/mesh/scenarios/multi-zone-architecture/"
---
Using an external CA ensures that Kong Air's service identities are governed by the same corporate PKI standards as their physical servers and employee devices.

{% tip %}
The `Mesh` resource used in this guide is **Global CP only**: it must be applied to the Global Control Plane. See the [Resource Scoping guide](/mesh/scenarios/resource-scoping/) for details on tab naming and which CP to target.
{% endtip %}

## 1. Why Use an External CA?

*   **Compliance**: Many organizations mandate that all certificates must be issued by a specific authority (e.g., HashiCorp Vault or a corporate Sub-CA).
*   **Hardened Security**: External CAs often live on hardware security modules (HSMs) or in highly restricted environments.
*   **Auditability**: Centralize all certificate issuance logs in a single location rather than having them scattered across local clusters.

## 2. Configuration Options

{{site.mesh_product_name}} supports multiple external CA backends.

### Option 1: HashiCorp Vault (Classic Mode)
Uses a Vault PKI role to sign mesh certificates. For Konnect-managed meshes, the `fromCp` block and `dpCert` rotation settings are required.

{% navtabs "vault-ca" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    mode: Exclusive
  mtls:
    enabledBackend: vault-ca
    backends:
    - name: vault-ca
      type: vault
      dpCert:
        rotation:
          expiration: 1d # Required by Konnect
      conf:
        fromCp: # Required: control plane requests the cert
          address: http://vault.default:8200
          role: mesh-dp
          auth:
            token:
              secret: vault-token
          tls:
            caCert:
              secret: vault-ca-cert' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive
mtls:
  enabledBackend: vault-ca
  backends:
  - name: vault-ca
    type: vault
    dpCert:
      rotation:
        expiration: 1d # Required by Konnect
    conf:
      fromCp: # Required: control plane requests the cert
        address: http://vault.default:8200
        role: mesh-dp
        auth:
          token:
            secret: vault-token
        tls:
          caCert:
            secret: vault-ca-cert' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Option 2: cert-manager (Classic Mode)
Bridges {{site.mesh_product_name}} with the cert-manager ecosystem.

{% navtabs "certmanager-ca" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: cert-manager-ca
    backends:
      - name: cert-manager-ca
        type: cert-manager
        certManager:
          issuerName: corporate-issuer
          issuerKind: ClusterIssuer' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
spec:
  mtls:
    enabledBackend: cert-manager-ca
    backends:
      - name: cert-manager-ca
        type: cert-manager
        certManager:
          issuerName: corporate-issuer
          issuerKind: ClusterIssuer' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Option 3: Amazon ACM (AWS Private CA)
Integrates with AWS Private Certificate Authority for industrial-strength security.

{% navtabs "acm-ca" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: aws-acm-ca
    backends:
      - name: aws-acm-ca
        type: acm
        acm:
          arn: arn:aws:acm-pca:region:account:certificate-authority/uuid
          auth:
            awsCredentials:
              accessKey: { secret: aws-access-key }
              accessKeySecret: { secret: aws-secret-key }' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
mtls:
  enabledBackend: aws-acm-ca
  backends:
    - name: aws-acm-ca
      type: acm
      acm:
        arn: arn:aws:acm-pca:region:account:certificate-authority/uuid
        auth:
          awsCredentials:
            accessKey: { secret: aws-access-key }
            accessKeySecret: { secret: aws-secret-key }' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Option 4: Provided (Modern Identity Mode)
In the modern **Workload Identity** model, you use `MeshIdentity` to provide an external CA. If the CA is self-signed, `insecureAllowSelfSigned: true` must be specified.

{% warning %}
`MeshIdentity` must be in the **system namespace** (`kong-mesh-system`) on Kubernetes. See [Resource Scoping](/mesh/scenarios/resource-scoping/).
{% endwarning %}

{% navtabs "meshidentity-ca" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: flight-operations-id
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true # Required for self-signed CAs
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: flight-ops-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: flight-ops-ca-key
  selector:
    dataplane:
      matchLabels:
        app: flight-control
  spiffeID:
    path: /{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}
    trustDomain: internal.kongair.com' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshIdentity
name: flight-operations-id
mesh: default
spec:
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true # Required for self-signed CAs
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: flight-ops-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: flight-ops-ca-key
  selector:
    dataplane:
      matchLabels:
        app: flight-control
  spiffeID:
    path: /{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}
    trustDomain: internal.kongair.com' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

---

## 3. Understanding the Architectures

Why does **Vault** require more configuration than **cert-manager**? It comes down to how {{site.mesh_product_name}} interacts with the certificate authority.

### Centralized vs. Native Integration

| Feature | cert-manager | HashiCorp Vault |
| :--- | :--- | :--- |
| **Platform** | Kubernetes-Native | External API |
| **Authentication** | Kubernetes RBAC | Vault Token / Kubernetes Auth |
| **Client** | Control Plane (via K8s API) | Control Plane (via REST API) |
| **Requirements** | `IssuerRef` | `fromCp` + `dpCert` |

#### Why `fromCp` for Vault?

In a security-first environment like **Kong Air**, we avoid distributing sensitive Vault tokens to every Data Plane proxy. 

*   **Native Integration (cert-manager)**: The Control Plane is already a Kubernetes controller. It uses its built-in Service Account to talk to the cert-manager APIs. No extra "authentication" block is needed because it's part of the same platform.
*   **External Integration (Vault)**: Vault is an external service. The `fromCp` block explicitly tells {{site.mesh_product_name}} that the **Control Plane** (rather than the individual proxies) is responsible for requesting certificates. This is mandatory in Konnect to ensure that proxies in private zones don't need direct network access to Vault.

#### Why `dpCert` for Vault?

When using `fromCp`, the Control Plane acts as the requester. It must explicitly tell Vault how long the issued certificate should live. 

*   **cert-manager** uses the TTL defined on the `Issuer`.
*   **Vault** requires a TTL provided at the time of the `sign` or `issue` request. The `dpCert.rotation.expiration` field provides this value. Without it, the Control Plane cannot make a valid request to the Vault API.

#### Comparison of Architectures

The following diagrams illustrate the differences in how {{site.mesh_product_name}} manages identities across different CA providers.

#### Built-in CA (Simplest)
The Control Plane acts as the Certificate Authority. No external dependencies.

{% mermaid %}
sequenceDiagram
    participant DP as Data Plane (Proxy)
    participant CP as Control Plane (Manager)
    
    Note over DP, CP: In-mesh CA
    DP->>CP: 1. Request Identity
    CP->>CP: 2. CP acts as CA (Self-Signs)
    CP->>DP: 3. Push Identity via xDS
{% endmermaid %}

#### cert-manager (Platform Native)
The Control Plane leverages Kubernetes-native cert-manager APIs.

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

#### HashiCorp Vault (External / fromCp)
The Control Plane authenticates to an external Vault API to request certificates.

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

## 4. The Migration Path

If you are currently using the "Built-in" CA and want to move to Vault:

1.  **Assign Identity**: Define a `MeshIdentity` policy and targeted workloads.
2.  **Add Trusted CA**: Distribute the new Root CA via a `MeshTrust` resource. sidecars will now trust both old and new CAs.
3.  **Enforce TLS**: Apply a `MeshTLS` policy to move workloads to the new identity model.
4.  **Rotate**: The control plane re-issues certificates using the new provider.
