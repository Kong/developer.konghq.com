---
title: Workload Identity & mTLS Evolution
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Discover the new Workload Identity model in {{site.mesh_product_name}}. Learn how to move beyond mesh-wide mTLS to a granular identity system supporting SPIRE, custom SPIFFE IDs, and decoupled trust management.
products:
  - mesh
tldr:
  q: What is Workload Identity in Kong Mesh?
  a: |
    Workload Identity decouples identity from the `Mesh` resource. It allows you to:
    1. **Define granular identity** per workload via `MeshIdentity`.
    2. **Manage Trust** explicitly using `MeshTrust` CA bundles.
    3. **Customize SPIFFE IDs** to align with your organization's taxonomy.
prereqs:
  inline:
    - title: Architecture
      content: |
        A running {{site.mesh_product_name}} deployment. If you are new to the multi-tier control plane model, read the [Resource Scoping guide](/mesh/scenarios/resource-scoping/) first.
    - title: Mesh Mode
      content: |
        A Mesh configured in **Exclusive** mode (required for `MeshIdentity` support).
next_steps:
  - text: "Enterprise PKI: External CA Integration"
    url: "/mesh/scenarios/external-ca-vault/"
---
## 1. The Core Shift: From Mesh to Workload

In the previous model, the `Mesh` object was the source of all authority. In the new model, identity is a distinct lifecycle managed by two primary resources: `MeshIdentity` and `MeshTrust`.

| Feature | Mesh mTLS | Modern Workload Identity |
| :--- | :--- | :--- |
| **Scope** | Mesh-wide (single CA) | Granular (target specific workloads) |
| **Provider** | Built-in or provided certs | Bundled or SPIRE |
| **SPIFFE ID** | Fixed format | Fully customizable trust domain and paths |
| **Trust Model** | Implicit trust in Mesh CA | Explicit trust via `MeshTrust` bundles |

## 2. Prerequisite: MeshServices Mode

Before enabling Workload Identity, you must ensure your mesh is using the modern **MeshService** resource model.

{% warning %}
`MeshIdentity` requires `meshServices.mode: Exclusive` to be set on your `Mesh` resource. This disables the legacy `kuma.io/service` tags and moves your mesh to a first-class resource-based identity system.
{% endwarning %}

{% navtabs "mesh-services-mode" %}
{% navtab "Kubernetes (Global CP)" %}

{% warning %}
`Mesh` is a **Global CP only** resource. Apply this against the kubeconfig of your **Global Control Plane**, not a Zone CP. See [Resource Scoping](/mesh/scenarios/resource-scoping/).
{% endwarning %}

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    mode: Exclusive' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}

{% warning %}
Run this against your **Global CP**. Use `kumactl config control-planes use <global-cp>` first.
{% endwarning %}

```bash
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## 3. Defining Identity with `MeshIdentity`

This is the closest to the classic model but with the added flexibility of targeting specific workloads.

{% warning %}
On **Kubernetes**, `MeshIdentity` must be applied to the **system namespace** (e.g., `kong-mesh-system`). This is because `MeshIdentity` is an identity authority for all workloads in the mesh, rather than a per-application resource. Restricting it to the system namespace ensures only platform engineers can modify the CA configuration. See [Resource Scoping](/mesh/scenarios/resource-scoping/).
{% endwarning %}

{% navtabs "mesh-identity" %}
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
  selector:
    dataplane:
      matchLabels:
        app: flight-control
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-ca-key
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
  selector:
    dataplane:
      matchLabels:
        app: flight-control
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-ca-key
  spiffeID:
    path: /{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}
    trustDomain: internal.kongair.com' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Example: Using the SPIRE Provider
For high-security environments, you can delegate identity to **SPIRE** (the SPIFFE Runtime Environment).

{% navtabs "spire-identity" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: spire-identity
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        env: prod
  spiffeID:
    trustDomain: internal.kongair.com
    path: "/{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}"
  provider:
    type: Spire
    spire:
      agent:
        timeout: 5s
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: MeshIdentity
name: spire-identity
mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        env: prod
  spiffeID:
    trustDomain: internal.kongair.com
    path: "/{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}"
  provider:
    type: Spire
    spire:
      agent:
        timeout: 5s
```
{% endnavtab %}
{% endnavtabs %}

## 4. Managing Trust with `MeshTrust`

While `MeshIdentity` is about **obtaining** a certificate, `MeshTrust` is about **trusting** certificates. It defines a set of CA bundles that are considered valid for a given trust domain.

This separation allows you to:
- Rotate CAs without re-issuing identity certificates immediately.
- Establish trust across different identity providers.
- Manage cross-mesh or cross-cloud trust explicitly.

{% navtabs "mesh-trust" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  name: global-trust
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  trustDomain: internal.kongair.com
  caBundles:
    - type: Pem
      pem:
        value: |
          -----BEGIN CERTIFICATE-----
          ... (Primary CA)
          -----END CERTIFICATE-----
    - type: Pem
      pem:
        value: |
          -----BEGIN CERTIFICATE-----
          ... (Secondary/Backup CA)
          -----END CERTIFICATE-----
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: MeshTrust
name: global-trust
mesh: default
spec:
  trustDomain: internal.kongair.com
  caBundles:
    - type: Pem
      pem:
        value: |
          -----BEGIN CERTIFICATE-----
          ... (Primary CA)
          -----END CERTIFICATE-----
    - type: Pem
      pem:
        value: |
          -----BEGIN CERTIFICATE-----
          ... (Secondary/Backup CA)
          -----END CERTIFICATE-----
```
{% endnavtab %}
{% endnavtabs %}

## 5. Enforcing Security with `MeshTLS`

Once workloads have an identity, you use the `MeshTLS` policy to enforce how that identity is used during communication.

{% navtabs "mesh-tls" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: strict-mtls
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    mode: Strict
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: MeshTLS
name: strict-mtls
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    mode: Strict # Reject any unencrypted or non-mTLS traffic
```
{% endnavtab %}
{% endnavtabs %}

## Benefits of the New Model

1.  **Identity as a First-Class Citizen**: Identity is no longer an implementation detail of the mesh; it is a resource you can audit, version, and manage independently.
2.  **SPIRE Native**: Direct integration with SPIRE allows you to leverage hardware-backed identity (like TPMs) and complex node attestation strategies.
3.  **Customizable SPIFFE IDs**: Align your service identities with your organizational taxonomy (e.g., `spiffe://acme.com/billing-dept/payment-service`) rather than being forced into a flat structure.
4.  **Granular Migration**: Move from the legacy model to the new model one service at a time by using specific `selectors` in your `MeshIdentity` policies.

## Business Value

The evolution to Workload Identity transforms your service mesh into a true **Zero-Trust Identity Provider**:
- **Compliance**: Meet strict federal or industry-specific identity standards (like FIPS or NIST 800-207).
- **Flexibility**: Use different identity providers for different parts of your business (e.g., SPIRE for production, Bundled for DEV).
- **Resilience**: Decoupled trust enables safer certificate rotations and more robust disaster recovery for your PKI infrastructure.
