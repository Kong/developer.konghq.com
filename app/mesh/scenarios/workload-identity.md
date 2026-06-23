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

| Feature | Mesh mTLS | Workload Identity |
| :--- | :--- | :--- |
| **Scope** | Mesh-wide (single CA) | Granular (target specific workloads) |
| **Provider** | Built-in or provided certs | Bundled or SPIRE |
| **SPIFFE ID** | Fixed format | Fully customizable trust domain and paths |
| **Trust Model** | Implicit trust in Mesh CA | Explicit trust via `MeshTrust` bundles |

## 2. Prerequisite: MeshServices Mode

Before enabling Workload Identity, you must ensure your mesh is using the **MeshService** resource model.

{% warning %}
`MeshIdentity` becomes active only when `meshServices.mode: Exclusive` is set on the `Mesh`. The control plane accepts the `MeshIdentity` resource before that point, but does not initialize it until MeshServices are enabled on the mesh.
{% endwarning %}

{% navtabs "mesh-services-mode" %}
{% navtab "Kubernetes Global CP (self-managed)" %}

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
{% navtab "Konnect / Universal Global CP" %}

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

The recommended production pattern is:

1. Apply the `MeshIdentity` on the **Global CP**
2. Use the **Bundled** provider with `autogenerate.enabled: true`
3. Use a workload-oriented SPIFFE path
4. Let {{site.mesh_product_name}} automatically create the matching `MeshTrust`

{% warning %}
On Kubernetes, the **synced copy** of `MeshIdentity` lives in the **system namespace** on each Zone CP. If your Global CP is also Kubernetes-backed, create the resource in the system namespace there as well. If your Global CP is Konnect or Universal-backed, apply it with `kumactl` and let {{site.mesh_product_name}} sync the generated copy down to each zone.
{% endwarning %}

{% tip %}
The examples below are **targeted** identities, layered on top of the mesh-wide `kong-air-identity` from [Getting Started](/mesh/scenarios/getting-started-policy/). The control plane gives each workload its single *most-specific* `MeshIdentity` (the selector with the most `matchLabels` wins), so a targeted selector must be **more specific** than the mesh-wide default, that's why each one includes `kuma.io/mesh: kong-air-mesh` **plus** its workload label. The mesh-wide identity keeps covering everything else, including the zone proxies.
{% endtip %}

{% navtabs "mesh-identity" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: passenger-portal-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
        app: passenger-portal
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
      meshTrustCreation: Enabled
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/workload/{% raw %}{{ label "kuma.io/workload" }}{% endraw %}
    trustDomain: kong-air-mesh.mesh.local' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```bash
echo 'type: MeshIdentity
name: passenger-portal-identity
mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
        app: passenger-portal
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
      meshTrustCreation: Enabled
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/workload/{% raw %}{{ label "kuma.io/workload" }}{% endraw %}
    trustDomain: kong-air-mesh.mesh.local' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
On Kubernetes, make sure the dataplane carries a stable `kuma.io/workload` label before you standardize on the workload-based SPIFFE path. That is the identifier this example resolves against.
{% endtip %}

{% warning %}
Applying `MeshIdentity` to an already-running workload is not always enough by itself. After you apply or change a `MeshIdentity`, restart the selected workload so the dataplane comes up on the new identity before you validate cross-service traffic.
{% endwarning %}

For Kubernetes, the safest path is a normal rollout restart of the affected workload:

```bash
kubectl rollout restart deployment/<workload-name> -n kong-air-production
```

### Verify that the identity is active

The clearest verification step is to inspect `DataplaneInsight`, not raw Envoy config:

```bash
kubectl get dataplaneinsights -n kong-air-production -o yaml | grep -A4 issuedBackend
```

When the identity is active, the selected workload's `status.mTLS.issuedBackend` changes from `builtin` to the KRI for your `MeshIdentity`, for example:

```yaml
status:
  mTLS:
    issuedBackend: kri_mid_kong-air-mesh___passenger-portal-identity_
```

You can also check that `status.mTLS.certificateExpirationTime` moved forward after the restart. If `issuedBackend` changed but traffic still fails TLS verification, inspect the sidecar certificate and confirm the workload has actually rotated onto the new cert.

If you want to inspect the actual certificate SAN on a sidecar, you can still do that:

```bash
kubectl exec -n kong-air-production <pod> -c kuma-sidecar -- \
  wget -qO- http://127.0.0.1:9901/certs | grep -n 'spiffe://'
```

### Example: Using the SPIRE Provider
For higher-assurance environments, you can delegate identity to **SPIRE** (the SPIFFE Runtime Environment).

{% navtabs "spire-identity" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: spire-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
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
{% navtab "Konnect / Universal Global CP" %}
```yaml
type: MeshIdentity
name: spire-identity
mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
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

### Cross-zone trust with autogenerated CAs

{% warning %}
Multi-zone deployments with `autogenerate: enabled: true` require a manual cross-zone trust step. When each Zone CP generates its own CA, the two zones' `MeshTrust` resources share the same base name after KDS syncs them back. One overwrites the other, leaving each zone trusting only its own CA. Cross-zone mTLS then fails at the ZoneIngress TLS handshake (`cx_connect_fail` on every attempt).
{% endwarning %}

To establish mutual trust, create a combined `MeshTrust` on **each zone** that includes every zone's CA bundle.

**Step 1: Find the auto-generated `MeshTrust` name on each zone**

The `Bundled` provider creates one `MeshTrust` per zone. List them to get the name:

```bash
kubectl --kubeconfig=<zone1-config> get meshtrusts -n {{site.mesh_namespace}}
```

**Step 2: Extract each zone's CA bundle**

Fill in `<zone-n-config>` and the `<meshtrust-name>` from Step 1:

```bash
ZONE1_CA=$(kubectl --kubeconfig=<zone1-config> \
  get meshtrusts -n {{site.mesh_namespace}} <meshtrust-name> \
  -o jsonpath='{.spec.caBundles[0].pem.value}')
ZONE2_CA=$(kubectl --kubeconfig=<zone2-config> \
  get meshtrusts -n {{site.mesh_namespace}} <meshtrust-name> \
  -o jsonpath='{.spec.caBundles[0].pem.value}')
```

**Step 3: Apply a combined `MeshTrust` to every zone**

Run this once per zone, swapping `--kubeconfig` for each. The `$(... | sed ...)` substitution indents each PEM line to sit under `value: |`:

```bash
kubectl apply -f - <<EOF
apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  name: kong-air-cross-zone-trust
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  trustDomain: kong-air-mesh.mesh.local
  caBundles:
    - type: Pem
      pem:
        value: |
$(echo "$ZONE1_CA" | sed 's/^/          /')
    - type: Pem
      pem:
        value: |
$(echo "$ZONE2_CA" | sed 's/^/          /')
EOF
```

Once the combined `MeshTrust` is applied on every zone, cross-zone mTLS connections succeed.

{% tip %}
For production multi-zone deployments, avoid this manual step entirely by using a **shared CA** (provide the same cert/key to every zone in the `Bundled` provider configuration rather than using `autogenerate`), or by using **SPIRE**, which manages cross-zone trust natively.
{% endtip %}

This separation allows you to:
- Rotate CAs without re-issuing identity certificates immediately.
- Establish trust across different identity providers.
- Manage cross-mesh or cross-cloud trust explicitly.

{% tip %}
For the bundled-provider path above, {{site.mesh_product_name}} auto-generates the `MeshTrust` resource. In day-to-day operations, you usually create `MeshTrust` manually only when you are adding an extra trust domain, rotating trust deliberately, or integrating an external identity provider.
{% endtip %}

{% navtabs "mesh-trust" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  name: global-trust
  namespace: {{site.mesh_namespace}}
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
{% navtab "Konnect / Universal Global CP" %}
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

Once workloads have an identity, you use the `MeshTLS` policy to enforce how that identity is used during communication. Apply it at the **Global CP**, like the `MeshIdentity` and `MeshTrust` above, so it syncs to every zone.

{% navtabs "mesh-tls" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: strict-mtls
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        mode: Strict
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```yaml
type: MeshTLS
name: strict-mtls
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        mode: Strict
```
{% endnavtab %}
{% endnavtabs %}

## Benefits of the Mesh Identity

1.  **Identity as a First-Class Citizen**: Identity is no longer an implementation detail of the mesh; it is a resource you can audit, version, and manage independently.
2.  **SPIRE Native**: Direct integration with SPIRE allows you to use hardware-backed identity (like TPMs) and complex node attestation strategies.
3.  **Customizable SPIFFE IDs**: Align your service identities with your organizational taxonomy (e.g., `spiffe://acme.com/billing-dept/payment-service`) rather than being forced into a flat structure.
4.  **Granular Migration**: Move from the legacy model to the new model one service at a time by using specific `selectors` in your `MeshIdentity` policies.

## Business Value

The evolution to Workload Identity transforms your service mesh into a true **Zero-Trust Identity Provider**:
- **Compliance**: Meet strict federal or industry-specific identity standards (like FIPS or NIST 800-207).
- **Flexibility**: Use different identity providers for different parts of your business (e.g., SPIRE for production, Bundled for DEV).
- **Resilience**: Decoupled trust enables safer certificate rotations and more reliable disaster recovery for your PKI infrastructure.
