---
title: Integrate an external CA
content_type: how_to
permalink: /mesh/integrate-an-external-ca/
description: Move beyond the built-in CA. Learn how to integrate {{site.mesh_product_name}} with enterprise PKI solutions like HashiCorp Vault and cert-manager for automated certificate management.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I integrate my mesh with an enterprise certificate authority?
  a: |
    Root your mesh identity in an external CA through `MeshIdentity`, in one of two ways:
    1. Bundled provider: you supply the CA cert and key, and {{site.mesh_product_name}} signs from it.
    2. Extension providers: {{site.mesh_product_name}} delegates signing to cert-manager, HashiCorp Vault, or AWS Private CA, so the CA key never leaves that system.
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps in `kong-air-mesh`. See [Get started with your first policy](/mesh/get-started-with-your-first-policy/).
    - title: kongctl
      include_content: md/mesh/v3/prereqs/kongctl
cleanup:
  inline:
    - title: Remove the external CA configuration
      include_content: md/mesh/v3/cleanup/external-ca
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "Multi-zone architecture"
    url: "/mesh/multi-zone-architecture/"
related_resources:
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Manage secrets
    url: /mesh/manage-secrets/
---
Using an external CA ensures that Kong Air's service identities are governed by the same corporate PKI standards as their physical servers and employee devices.

{:.info}
> On Kubernetes, the `MeshIdentity` and `MeshTrust` resources in this guide can only be created in the system namespace (`{{site.mesh_namespace}}`). A zone control plane connected to a global control plane requires every resource created in that namespace to carry `kuma.io/origin: zone`, and rejects it otherwise, which is why every example in this guide sets the label. In an application namespace the control plane computes the label for you. See [Resource scoping](/mesh/resource-scoping/) for which control plane to target.

## Why use an external CA?

An external CA lets Kong Air govern service identities under the same corporate PKI it already uses for compliance, hardware-backed key storage, and centralized issuance auditing.

## Two ways to bring your own CA

Both approaches are configured through `MeshIdentity`. They place the resource in the system namespace and issue SPIFFE certificates using the same `spiffeID.path` and `trustDomain` fields, only the `provider` block differs.

<!-- vale off -->
{% table %}
columns:
  - title: Approach
    key: approach
  - title: How it works
    key: how_it_works
  - title: When to use
    key: when_to_use
rows:
  - approach: |
      Bundled provider
    how_it_works: |
      You hand {{site.mesh_product_name}} the CA certificate and private key. The control plane holds the key and signs every workload certificate from it.
    when_to_use: |
      The simplest path. Good when you already have CA material you can place in the cluster.
  - approach: |
      Extension providers
    how_it_works: |
      The control plane delegates signing to an external system (cert-manager, HashiCorp Vault, AWS Private CA) on each rotation. The CA private key never leaves that system.
    when_to_use: |
      Enterprise PKI, where the CA key must stay in your existing system. Requires {{site.mesh_product_name}} enterprise.
{% endtable %}
<!-- vale on -->

## Bundled provider

You provide an externally-managed CA certificate and private key as {{site.mesh_product_name}} Secrets, and the control plane signs all workload certificates from them.

{:.warning}
> The CA cert and key are referenced as {{site.mesh_product_name}} Secrets in the system namespace (`{{site.mesh_namespace}}`) with the `kuma.io/mesh` label, not native Kubernetes TLS Secrets. For how these Secrets are structured and created, see [Manage secrets](/mesh/manage-secrets/).

### Step 1: create the {{site.mesh_product_name}} Secrets containing your CA cert and key

This example uses cert-manager to mint a self-signed CA, but any CA material works, substitute your corporate Sub-CA cert and key instead.

{:.info}
> This is not the same as the cert-manager extension in the next section. Here, cert-manager only generates a CA certificate that you then hand to the `Bundled` provider. The extension delegates live signing to cert-manager on every rotation.

1. Bootstrap a self-signed CA with cert-manager:

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

1. Bridge the cert-manager Secret to a {{site.mesh_product_name}} Secret. {{site.mesh_product_name}} reads `data.value` (raw PEM) from `system.kuma.io/secret` type Secrets:

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

   {:.info}
   > For production, automate this sync with an external-secrets operator or a cert-manager `ExternalSecret` so {{site.mesh_product_name}} Secrets stay up-to-date when cert-manager rotates the CA.

### Step 2: create the MeshIdentity

Point the `Bundled` provider at the two {{site.mesh_product_name}} Secrets from Step 1:

1. Apply the `MeshIdentity`:

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

1. Verify the MeshService picked up the new trust domain. The change reaches the sidecars over xDS within a few seconds, so no workload restart is needed:

   ```sh
   kongctl get mesh meshservices flight-control.kong-air-production \
     --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

   The control plane reports the identities it computed for the service. Look for the new trust domain under `spec.identities`:

   ```yaml
   spec:
       identities:
           - type: SpiffeID
             value: spiffe://internal.kongair.com/ns/kong-air-production/sa/flight-control
           - type: SpiffeID
             value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
   ```
   {:.no-copy-code}

   {:.info}
   > `spec.identities` lists the SPIFFE ID of *every* `MeshIdentity` whose selector matches the workload, so the mesh-wide `kong-air-identity` entry stays alongside the new one. Only one identity actually issues certificates. To see which one won, read `status.mTLS.issuedBackend` on the workload's `DataplaneInsight`, as shown in [Validate](#validate).

1. Update any `MeshTrafficPermission` that matches `flight-control` by its old SPIFFE ID. Changing `trustDomain` changes the workload's SPIFFE ID, so an `Exact` rule written against the old value silently stops matching and callers start getting `403 Forbidden`:

   ```bash
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: allow-flight-control-to-check-in
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
       kuma.io/origin: zone
   spec:
     targetRef:
       kind: Dataplane
       labels:
         app: check-in-api
     rules:
       - default:
           allow:
             - spiffeID:
                 type: Exact
                 value: spiffe://internal.kongair.com/ns/kong-air-production/sa/flight-control
   EOF
   ```

   {:.warning}
   > Plan a trust domain change the way you would a rename. Audit every policy that references a SPIFFE ID (`MeshTrafficPermission`, `MeshTLS`, external service configuration) before you apply the `MeshIdentity`, because the switch takes effect in seconds and traffic fails closed. Using a `Prefix` match instead of `Exact` narrows the blast radius but still needs updating when the trust domain changes.

## Extension providers

Instead of signing workload certs from a CA it holds, {{site.mesh_product_name}} delegates signing to an external system. The workload-facing `MeshIdentity` API stays unchanged, only `provider.type` and `extension.config` change. On each sidecar cert rotation, the control plane submits a signing request to the extension (cert-manager creates a `CertificateRequest`, Vault issues via its PKI engine), then delivers the signed cert to the sidecar via xDS. Kong Air can switch issuers by changing two fields, with no application restarts.

All three providers in this section share the same `spiffeID.path` and `trustDomain`. Only `extension.name` and the keys under `extension.config` change between them. The cert-manager example is the one to run through end to end; the Vault and ACM examples are reference material, since both need infrastructure outside the cluster. Adapt the provider-specific config values to your environment.

{:.warning}
> The `Bundled` and extension examples are alternatives, not a sequence. They select the same workloads, so applying more than one leaves two `MeshIdentity` resources competing for `flight-control`. The control plane picks the most specific selector, and breaks a tie on the number of `matchLabels` by choosing the lexicographically smallest name, which means `flight-operations-id` always wins over `kong-air-certmanager-identity`. Delete the `MeshIdentity` from the previous section before applying the next one.

### cert-manager

Prerequisites: cert-manager installed with a `ClusterIssuer` or `Issuer` for the mesh CA.

1. Install cert-manager and create a CA-backed `Issuer`:

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
     name: kong-air-certmanager-ca
     namespace: {{site.mesh_namespace}}
   spec:
     isCA: true
     commonName: kong-air-certmanager-ca
     duration: 87600h
     renewBefore: 720h
     secretName: kong-air-certmanager-ca-tls
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
       secretName: kong-air-certmanager-ca-tls
   EOF

   kubectl wait --for=condition=ready certificate/kong-air-certmanager-ca \
     -n {{site.mesh_namespace}} --timeout=30s
   ```

1. Publish the issuer's CA certificate as a {{site.mesh_product_name}} Secret. The extension uses it to build the `MeshTrust` that tells every other proxy in the mesh to trust certificates signed by this issuer:

   ```bash
   CA_PEM=$(kubectl get secret kong-air-certmanager-ca-tls \
     -n {{site.mesh_namespace}} -o jsonpath='{.data.ca\.crt}' | base64 -d)

   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Secret
   metadata:
     name: kong-air-certmanager-trust
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
   type: system.kuma.io/secret
   stringData:
     value: |
   $(echo "$CA_PEM" | sed 's/^/    /')
   EOF
   ```

1. Apply the `MeshIdentity`:

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
           caCert:                       # Trust anchor published as a MeshTrust
             type: Secret
             secretRef:
               kind: Secret
               name: kong-air-certmanager-trust
   EOF
   ```

   How it works: {{site.mesh_product_name}} creates a `CertificateRequest` in `{{site.mesh_namespace}}` for each sidecar that needs a new identity cert. cert-manager approves and signs it using the configured `Issuer`, and the signed cert is delivered to the sidecar via xDS. CertificateRequests are cleaned up after use.

   {:.warning}
   > `caCert` is optional in the schema but required in practice. cert-manager returns only the signed leaf certificate, so unlike the Vault and ACM providers, {{site.mesh_product_name}} has no way to discover the issuing CA on its own. Without `caCert` the `MeshIdentity` still reports `Ready` and workloads still get certificates, but no `MeshTrust` is created, no peer trusts the new certificates, and mTLS fails with no obvious error. If you leave `caCert` out, you must create the `MeshTrust` yourself.
   >
   > Keep `caCert` in sync with the issuer. If the CA is rotated and this Secret is not updated, {{site.mesh_product_name}} advertises a stale trust anchor while signing with the new CA, which breaks mTLS the same way.

1. Verify:

   Watch for `CertificateRequests` being created and signed as workloads connect:

   ```sh
   kubectl get certificaterequests -n {{site.mesh_namespace}} -w
   ```

   Confirm the `MeshTrust` was created from `caCert`, and check the SPIFFE IDs the control plane computed:

   ```sh
   kubectl get meshtrust kong-air-certmanager-identity -n {{site.mesh_namespace}}

   kongctl get mesh meshservices flight-control.kong-air-production \
     --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

### HashiCorp Vault

Delegates signing to a Vault PKI secrets engine. {{site.mesh_product_name}} authenticates to Vault and requests a certificate on each rotation. Vault returns the issuing CA along with the signed certificate, so the provider builds the `MeshTrust` without a `caCert` field:

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
        connection:
          type: Server
          server:
            address: https://vault.example.com
            auth:
              type: Token           # Token, TLS, or AWS
              token:
                type: Secret
                secretRef:
                  kind: Secret
                  name: kong-air-vault-token
        pki:
          mount: kong-mesh-pki-kong-air-mesh   # Vault PKI secrets engine mount path
          role: dataplanes                     # Vault PKI role that issues workload certs
```

The Vault token is read from a {{site.mesh_product_name}} Secret in the system namespace, the same `system.kuma.io/secret` format used for the `Bundled` CA material. `auth.type` accepts `Token`, `TLS` for client certificate authentication, and `AWS` for IAM or EC2 authentication. There is no Kubernetes auth method.

### AWS Private CA

Delegates signing to AWS Private Certificate Authority (ACM PCA). Like Vault, ACM PCA returns the CA chain with each issued certificate, so no `caCert` field is needed:

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
        arn: arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/example
```

The AWS region is parsed from the ARN, so there is no separate `region` field. Credentials come from the control plane's ambient AWS configuration (IRSA, instance profile, or environment), or from an optional `credentials` block in the same config.

{:.info}
> Every extension provider honors the same `spiffeID.path` and `trustDomain` fields. Only `extension.name` and the provider-specific `extension.config` keys change, so Kong Air can switch from cert-manager to Vault by editing two fields, without touching any application or policy config.

## How issuance works

Each CA model integrates with the control plane differently. Knowing the flow helps you choose a provider and reason about where the CA private key lives.

In every model the control plane is the client that requests certificates from the CA, never the individual proxies. Workloads in private zones therefore need no direct network access to the CA, and no CA credentials are distributed to the data plane.

<!-- vale off -->
{% table %}
columns:
  - title: Feature
    key: feature
  - title: cert-manager
    key: cert_manager
  - title: HashiCorp Vault
    key: hashicorp_vault
rows:
  - feature: |
      Platform
    cert_manager: |
      Kubernetes-native
    hashicorp_vault: |
      External API
  - feature: |
      Authentication
    cert_manager: |
      Kubernetes RBAC
    hashicorp_vault: |
      Vault token, TLS client cert, or AWS IAM
  - feature: |
      Client
    cert_manager: |
      Control Plane (via K8s API)
    hashicorp_vault: |
      Control Plane (via REST API)
{% endtable %}
<!-- vale on -->

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
    CP->>V: 3. Authenticate (Token/TLS/AWS)
    CP->>V: 4. Request Certificate (CSR + TTL)
    V-->>CP: 5. Return Signed Certificate
    CP->>DP: 6. Push Identity via xDS
{% endmermaid %}

## Validate

1. Confirm the `MeshTrust` auto-created for `flight-operations-id` carries your external CA, not a self-signed autogenerated one. `meshTrustCreation` defaults to `Enabled`, so a `MeshTrust` named `flight-operations-id` exists as soon as the `MeshIdentity` is applied:

   ```sh
   kubectl get meshtrust flight-operations-id -n {{site.mesh_namespace}} \
     -o jsonpath='{.spec.caBundles[0].pem.value}' | openssl x509 -noout -subject -issuer
   ```

   Expected output matches the `kong-air-mesh-ca` certificate you created in Step 1, confirming the mesh trusts your external CA rather than an autogenerated one:

   ```text
   subject=CN=kong-air-mesh-ca
   issuer=CN=kong-air-mesh-ca
   ```
   {:.no-copy-code}

1. Confirm `flight-control` is actually issuing certificates from that identity, not the mesh-wide `kong-air-identity`:

   ```sh
   FLIGHT_POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
   kubectl get dataplaneinsight "$FLIGHT_POD" -n kong-air-production -o jsonpath='{.status.mTLS.issuedBackend}{"\n"}'
   ```

   Expected output:

   ```text
   kri_mid_kong-air-mesh_zone1_kong-mesh-system_flight-operations-id_
   ```
   {:.no-copy-code}

   The value is a {{site.mesh_product_name}} Resource Identifier: `kri_mid_<mesh>_<zone>_<namespace>_<name>_`. Substitute your own zone name if it is not `zone1`. If you see `kri_mid_kong-air-mesh_zone1_kong-mesh-system_kong-air-identity_` instead, the mesh-wide identity is still winning and your `MeshIdentity` selector is not matching the workload.

Together, these two checks confirm the external CA is actually rooting `flight-control`'s identity: the auto-generated `MeshTrust` carries your CA's certificate, and the workload's issued certificate is backed by the `MeshIdentity` you pointed at it.
