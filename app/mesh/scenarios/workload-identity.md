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
  q: What is Workload Identity in {{site.mesh_product_name}}?
  a: |
    Workload Identity decouples identity from the `Mesh` resource. It allows you to:
    1. **Define granular identity** per workload via `MeshIdentity`.
    2. **Manage Trust** explicitly using `MeshTrust` CA bundles.
    3. **Customize SPIFFE IDs** while migrating safely from legacy mesh-wide identities.
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

{% tip %}
**Version guide.** `MeshIdentity` is available in 2.13 and works there today. The key difference is the **best-practice template**, not whether the feature exists:

- **2.13 best practice:** enable `meshServices.mode: Exclusive`, use `MeshIdentity` with the Kubernetes ServiceAccount SPIFFE path, and let the bundled provider auto-generate the CA and `MeshTrust`.
- **2.14+ / Kong Mesh 3 path:** move toward workload-label-based SPIFFE paths (`{% raw %}{{ label "kuma.io/workload" }}{% endraw %}`) and the newer policy model that matches directly on SPIFFE IDs more often.
{% endtip %}

| Feature | Mesh mTLS | Modern Workload Identity |
| :--- | :--- | :--- |
| **Scope** | Mesh-wide (single CA) | Granular (target specific workloads) |
| **Provider** | Built-in or provided certs | Bundled or SPIRE |
| **SPIFFE ID** | Fixed format | Fully customizable trust domain and paths |
| **Trust Model** | Implicit trust in Mesh CA | Explicit trust via `MeshTrust` bundles |

## 2. Prerequisite: MeshServices Mode

Before enabling Workload Identity, you must ensure your mesh is using the modern **MeshService** resource model.

{% warning %}
`MeshIdentity` becomes active only when `meshServices.mode: Exclusive` is set on the `Mesh`. On the validated 2.13 path, the control plane accepts the `MeshIdentity` resource before that point, but does not initialize it until MeshServices are enabled on the mesh.
{% endwarning %}

{% tip %}
**For 2.13 operators:** this is the point where the docs intentionally diverge. If you are not ready to enable `meshServices.mode: Exclusive`, stay on the legacy identity model for now and use this page as migration guidance. If you are ready to pilot workload identity on 2.13, enable `Exclusive` first and then continue with the `MeshIdentity` resources below.
{% endtip %}

{% navtabs "mesh-services-mode" %}
{% navtab "Kubernetes (Global CP)" %}

{% warning %}
`Mesh` is a **Global CP only** resource. Apply this against the kubeconfig of your **Global Control Plane**, not a Zone CP. See [Resource Scoping](/mesh/scenarios/resource-scoping/).
{% endwarning %}

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: kong-air-mesh
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
name: kong-air-mesh
meshServices:
  mode: Exclusive' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## 3. Defining Identity with `MeshIdentity`

For the validated 2.13 path, the simplest and most reliable pattern is:

1. Apply the `MeshIdentity` on the **Global CP**
2. Use the **Bundled** provider with `autogenerate.enabled: true`
3. Keep the SPIFFE path in the Kubernetes **ServiceAccount** form
4. Let Kuma automatically create the matching `MeshTrust`

{% warning %}
On Kubernetes, the **synced copy** of `MeshIdentity` lives in the **system namespace** on each Zone CP. If your Global CP is also Kubernetes-backed, create the resource in the system namespace there as well. If your Global CP is Konnect or Universal-backed, apply it with `kumactl` and let Kuma sync the generated copy down to each zone.
{% endwarning %}

{% tip %}
**2.13 vs 2.14+ SPIFFE templates.** The live 2.13 mesh validated the ServiceAccount template cleanly. A workload-label template also rendered, but with default Kubernetes runtime settings it resolved to `workload/default`, because the workload identifier falls back to the ServiceAccount when workload labels are not configured. That makes the ServiceAccount form the safer 2.13 default.
{% endtip %}

{% navtabs "mesh-identity" %}
{% navtab "Kubernetes / 2.13 best practice" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: passenger-portal-identity
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        app: passenger-portal
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
      meshTrustCreation: Enabled
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
    trustDomain: kong-air-mesh.mesh.local' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal / 2.13 best practice" %}
```bash
echo 'type: MeshIdentity
name: passenger-portal-identity
mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        app: passenger-portal
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
      meshTrustCreation: Enabled
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
    trustDomain: kong-air-mesh.mesh.local' | kumactl apply -f -
```
{% endnavtab %}
{% navtab "2.14+ / Kong Mesh 3 pattern" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: passenger-portal-identity
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        app: passenger-portal
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
      meshTrustCreation: Enabled
  spiffeID:
    trustDomain: kong-air-mesh.mesh.local
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/workload/{% raw %}{{ label "kuma.io/workload" }}{% endraw %}
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
On the validated 2.13 Konnect-backed mesh, applying `MeshIdentity` with `kumactl` created a **hashed synced copy** in the system namespace on the zone, for example `passenger-portal-identity-bf84b64z54xbcf8f`. Kuma also auto-created a matching `MeshTrust` in the zone.
{% endtip %}

{% warning %}
**Operational note for 2.13 migrations.** Applying `MeshIdentity` to an already-running workload is not always enough by itself. On the validated 2.13 mesh, older dataplanes continued serving their previous certificate until the workload was reconciled. After you apply or change a `MeshIdentity`, restart the selected workload so the dataplane comes up on the new identity before you validate cross-service traffic.
{% endwarning %}

For Kubernetes, the safest path is a normal rollout restart of the affected workload:

```bash
kubectl rollout restart deployment/<workload-name> -n kong-air-production
```

### Verify that the identity is active

The clearest 2.13 verification step is to inspect `DataplaneInsight`, not raw Envoy config:

```bash
kubectl get dataplaneinsights -n kong-air-production -o yaml | grep -A4 issuedBackend
```

When the identity is active, the selected workload's `status.mTLS.issuedBackend` changes from `builtin` to the KRI for your `MeshIdentity`, for example:

```yaml
status:
  mTLS:
    issuedBackend: kri_mid_kong-air-mesh___passenger-portal-identity_
```

On the validated 2.13 migration path, we also checked that `status.mTLS.certificateExpirationTime` moved forward after the restart. If `issuedBackend` changed but traffic still fails TLS verification, inspect the sidecar certificate and confirm the workload has actually rotated onto the new cert.

If you want to inspect the actual certificate SAN on a sidecar, you can still do that:

```bash
kubectl exec -n kong-air-production <pod> -c kuma-sidecar -- \
  wget -qO- http://127.0.0.1:9901/certs | grep -n 'spiffe://'
```

### Example: Using the SPIRE Provider
For higher-assurance environments, you can delegate identity to **SPIRE** (the SPIFFE Runtime Environment).

{% navtabs "spire-identity" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: spire-identity
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        env: prod
  spiffeID:
    trustDomain: kong-air-mesh.mesh.local
    path: "/ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}"
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
mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        env: prod
  spiffeID:
    trustDomain: kong-air-mesh.mesh.local
    path: "/ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}"
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

{% tip %}
For the bundled-provider path above, Kuma auto-generated the `MeshTrust` resource for us. In day-to-day 2.13 adoption, you usually create `MeshTrust` manually only when you are adding an extra trust domain, rotating trust deliberately, or integrating an external identity provider.
{% endtip %}

{% navtabs "mesh-trust" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  name: global-trust
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  trustDomain: kong-air-mesh.mesh.local
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
mesh: kong-air-mesh
spec:
  trustDomain: kong-air-mesh.mesh.local
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
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
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
mesh: kong-air-mesh
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
