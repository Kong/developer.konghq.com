---
title: Integrate an external CA
content_type: how_to
permalink: /mesh/integrate-an-external-ca/
description: Root Kong Air workload identities in an external certificate authority with {{site.mesh_product_name}}, using the Bundled provider or an extension provider such as cert-manager, HashiCorp Vault, or AWS Private CA.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
tools:
  - kongctl
products:
  - mesh
works_on:
  - on-prem
  - konnect
series:
  id: mesh-kong-air-scenario
  position: 8
tldr:
  q: How do I integrate my mesh with an enterprise certificate authority?
  a: |
    Root your mesh identity in an external CA through `MeshIdentity`, in one of two ways:
    1. `Bundled` provider: You supply the CA certificate and key, and the control plane signs workload certificates with them.
    2. Extension providers: The control plane delegates signing to cert-manager, HashiCorp Vault, or AWS Private CA, so the CA key never leaves that system.
prereqs:
  inline:
    - title: cert-manager
      content: |
        Both examples on this page use [cert-manager](https://cert-manager.io/) to create CA material.
        Install cert-manager in the cluster and wait for its Pods to be ready:

        ```bash
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml
        kubectl wait --for=condition=ready pod -n cert-manager \
          -l app.kubernetes.io/instance=cert-manager --timeout=90s
        ```
cleanup:
  inline:
    - title: Remove the external CA configuration
      include_content: md/mesh/v3/cleanup/external-ca
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
faqs:
  - q: How do I delegate signing to HashiCorp Vault instead?
    a: |
      The `vault` extension provider delegates signing to a Vault PKI secrets engine.
      The control plane authenticates to Vault and requests a certificate on each rotation.
      The provider reads the CA chain from the PKI mount to build the `MeshTrust`, so the config has no `caCert` field:

      ```yaml
      apiVersion: kuma.io/v1alpha1
      kind: MeshIdentity
      metadata:
        name: vault-identity
        namespace: {{site.mesh_namespace}}
        labels:
          kuma.io/mesh: kong-air-mesh
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

      The control plane reads the Vault token from a {{site.mesh_product_name}} Secret in the system namespace.
      This Secret uses the same `system.kuma.io/secret` format as the `Bundled` CA material.
      `auth.type` accepts `Token`, `TLS` for client certificate authentication, and `AWS` for IAM or EC2 authentication.
      The `vault` provider doesn't support Kubernetes authentication.

      The Vault example needs a Vault deployment outside the cluster.
      Adapt the connection and PKI values to your environment before you apply it.
  - q: How do I delegate signing to AWS Private CA instead?
    a: |
      The `acmpca` extension provider delegates signing to AWS Private Certificate Authority (ACM PCA).
      Like the `vault` provider, it reads the CA certificate from AWS Private CA to build the `MeshTrust`, so the config has no `caCert` field:

      ```yaml
      apiVersion: kuma.io/v1alpha1
      kind: MeshIdentity
      metadata:
        name: acm-pca-identity
        namespace: {{site.mesh_namespace}}
        labels:
          kuma.io/mesh: kong-air-mesh
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

      The provider reads the AWS region from the ARN, so the config has no `region` field.
      The control plane gets AWS credentials from the default AWS credential chain, such as IRSA, an instance profile, or environment variables.
      The config has no field for credentials.

      The AWS Private CA example needs an AWS Private CA deployment outside the cluster.
      Adapt the ARN and credentials to your environment before you apply it.
next_steps:
  - text: "Reference: Multi-zone architecture"
    url: "/mesh/multi-zone-architecture/"
  - text: "How-to: Configure mesh-scoped zone proxies"
    url: "/mesh/configure-mesh-scoped-zone-proxies/"
related_resources:
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Use your own CA with MeshIdentity
    url: /mesh/policies/meshidentity/#use-your-own-ca
---

Kong Air already runs a corporate public key infrastructure (PKI) for compliance, hardware-backed key storage, and issuance audits.
An external certificate authority (CA) lets Kong Air root the Secure Production Identity Framework for Everyone (SPIFFE) identities of its workloads in that PKI.

`MeshIdentity` supports two ways to bring your own CA, and only the `provider` block differs between them:
* **`Bundled` provider**: You give the control plane the CA certificate and private key, and the control plane signs workload certificates.
  See [Use your own CA](/mesh/policies/meshidentity/#use-your-own-ca).
* **Extension providers**: The control plane sends each signing request to cert-manager, HashiCorp Vault, or AWS Private CA, so the CA private key stays in that system.
  See [Providers](/mesh/policies/meshidentity/#providers).

## Bundled provider

With the `Bundled` provider, you store an external CA certificate and private key as {{site.mesh_product_name}} Secrets.
The control plane signs every workload certificate with them.

{:.warning}
> The `Bundled` provider reads the CA certificate and key from {{site.mesh_product_name}} Secrets of type `system.kuma.io/secret` in the system namespace (`{{site.mesh_namespace}}`), with the `kuma.io/mesh` label.
> It cannot read native Kubernetes TLS Secrets.
> See [Use your own CA](/mesh/policies/meshidentity/#use-your-own-ca).

### Step 1: create the {{site.mesh_product_name}} Secrets containing your CA cert and key

In this example, cert-manager creates a self-signed CA.
Any CA material works, so you can use your corporate subordinate CA certificate and key instead.

{:.info}
> In this step, cert-manager only generates a CA certificate that you then give to the `Bundled` provider.
> The [cert-manager extension provider](#cert-manager) works differently: the control plane sends every signing request to cert-manager.

1. Create a self-signed CA certificate named `kong-air-mesh-ca` with cert-manager:

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

1. Copy the certificate and key from the cert-manager Secret into two {{site.mesh_product_name}} Secrets.
   The control plane reads raw PEM from the `data.value` field of Secrets of type `system.kuma.io/secret`:

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
   > For production, we recommend that you automate this copy, for example with the External Secrets Operator.
   > With automation, the {{site.mesh_product_name}} Secrets stay current when cert-manager rotates the CA.

### Step 2: create the MeshIdentity

The `flight-operations-id` `MeshIdentity` uses the `Bundled` provider with the two {{site.mesh_product_name}} Secrets from Step 1.
It's a second `MeshIdentity` with its own name and the `internal.kongair.com` trust domain, and it selects only `flight-control`.

1. Create the `flight-operations-id` `MeshIdentity`:

   ```bash
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshIdentity
   metadata:
     name: flight-operations-id
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
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

1. Check that the `flight-control` `MeshService` lists the new trust domain.
   The control plane sends the change to the sidecars over xDS within a few seconds, so you don't need to restart the workloads:

   ```sh
   kubectl get meshservice flight-control -n kong-air-production -o yaml
   ```

   The control plane lists the identities that it computed for the service under `spec.identities`.
   The list includes the new `internal.kongair.com` trust domain:

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
   > `spec.identities` lists the SPIFFE ID of *every* `MeshIdentity` whose selector matches the workload, so the mesh-wide `kong-air-identity` entry stays next to the new one.
   > Only one `MeshIdentity` issues the workload's certificates.
   > To find which one, read `status.mTLS.issuedBackend` on the workload's `DataplaneInsight`, as shown in [Validate](#validate).

1. Update every `MeshTrafficPermission` that matches `flight-control` by its old SPIFFE ID.
   The new trust domain changes the SPIFFE ID of `flight-control`, so an `Exact` rule with only the old value no longer matches.
   Allow both SPIFFE IDs, so `flight-control` keeps access whichever identity its certificate carries during the move:

   ```bash
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: allow-flight-control-to-check-in
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
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
             - spiffeID:
                 type: Exact
                 value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
   EOF
   ```

   After every `flight-control` Pod uses the new identity, remove the old SPIFFE ID from the rule.

   {:.warning}
   > Before you move workloads to a new trust domain, find every `MeshTrafficPermission` that references their SPIFFE IDs.
   > The switch takes effect in seconds, and the receiving proxies deny any caller that no rule matches.
   > To keep access during the move, allow both the old and the new SPIFFE IDs until every workload uses the new identity.
   > A `Prefix` match also needs an update when the trust domain changes.
   > See [Change an identity without losing access](/mesh/policies/meshidentity/#change-an-identity-without-losing-access).

## Extension providers

With an extension provider, the control plane delegates signing to an external system instead of signing with a CA that it holds.
The rest of the `MeshIdentity` stays the same: only `provider.type` and `extension.config` differ.
When a sidecar certificate needs rotation, the control plane sends a signing request to the extension.
For example, the control plane creates a cert-manager `CertificateRequest`, or asks Vault to issue the certificate from its PKI engine.
The control plane then sends the signed certificate to the sidecar over xDS.

The extension examples use the same `spiffeID.path` and `trustDomain`.
Only `extension.name` and the keys under `extension.config` differ between them.
You run the cert-manager example end to end.
The Vault and AWS Private CA examples in the FAQs need infrastructure outside the cluster, so adapt their values to your environment.

{:.warning}
> The `Bundled` and extension examples select the same workloads, so two `MeshIdentity` resources compete for `flight-control` while both exist.
> The control plane picks the most specific selector.
> When two selectors have the same number of `matchLabels`, the control plane picks the name that comes first alphabetically.
> As a result, `flight-operations-id` keeps issuing certificates until you delete it.
> Do not delete it before the cert-manager identity exists, because the switch is safe only when the new `MeshTrust` is already in place.

### cert-manager

The `certmanager` extension provider needs cert-manager, which you installed in the prerequisites, and an `Issuer` or `ClusterIssuer` for the mesh CA.

1. Create the `kong-air-mesh-ca-issuer` `Issuer`, backed by a CA certificate:

   ```bash
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

1. Store the issuer's CA certificate in a {{site.mesh_product_name}} Secret.
   The extension uses this certificate to build a `MeshTrust`, so the other proxies in the mesh trust certificates from this issuer:

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

1. Create the `kong-air-certmanager-identity` `MeshIdentity`, which sends signing requests to the `kong-air-mesh-ca-issuer` `Issuer`:

   ```bash
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshIdentity
   metadata:
     name: kong-air-certmanager-identity
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
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

   For each sidecar that needs a new certificate, the control plane creates a `CertificateRequest` in `{{site.mesh_namespace}}`.
   cert-manager approves and signs the request with the configured `Issuer`.
   The control plane sends the signed certificate to the sidecar over xDS, then deletes the `CertificateRequest`.

1. Delete the `flight-operations-id` `MeshIdentity` from the `Bundled` section, so `kong-air-certmanager-identity` starts issuing certificates to `flight-control`.
   The cert-manager identity already published its `MeshTrust`, so the other proxies trust the new certificates as soon as `flight-control` receives them:

   ```sh
   kubectl delete meshidentity flight-operations-id -n {{site.mesh_namespace}}
   ```

1. Watch cert-manager sign a `CertificateRequest` for each workload that connects:

   ```sh
   kubectl get certificaterequests -n {{site.mesh_namespace}} -w
   ```

   Confirm that the extension created a `MeshTrust` from `caCert`, and check the SPIFFE IDs that the control plane computed:

   ```sh
   kubectl get meshtrust kong-air-certmanager-identity -n {{site.mesh_namespace}}
   kubectl get meshservice flight-control -n kong-air-production -o yaml
   ```

{:.info}
> Every extension provider uses the same `spiffeID.path` and `trustDomain` fields.
> A Vault `MeshIdentity` for Kong Air differs from the cert-manager one only in `extension.name` and `extension.config`.
> To move workloads to another provider without losing access, create the new `MeshIdentity` under a new name, and move workloads to it gradually.
> See [Change an identity without losing access](/mesh/policies/meshidentity/#change-an-identity-without-losing-access).
> For the HashiCorp Vault and AWS Private CA configurations, see the FAQs.

## Validate

1. Confirm that the `flight-operations-id` `MeshTrust` contains your external CA.
   `meshTrustCreation` defaults to `Enabled`, so the control plane creates a `MeshTrust` named `flight-operations-id` when you apply the `MeshIdentity`:

   ```sh
   kubectl get meshtrust flight-operations-id -n {{site.mesh_namespace}} \
     -o jsonpath='{.spec.caBundles[0].pem.value}' | openssl x509 -noout -subject -issuer
   ```

   The output matches the `kong-air-mesh-ca` certificate that you created in Step 1.
   This confirms that the mesh trusts your external CA:

   ```text
   subject=CN=kong-air-mesh-ca
   issuer=CN=kong-air-mesh-ca
   ```
   {:.no-copy-code}

1. Confirm that `flight-control` gets its certificate from `flight-operations-id` and not from the mesh-wide `kong-air-identity`:

   ```sh
   FLIGHT_POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
   kubectl get dataplaneinsight "$FLIGHT_POD" -n kong-air-production -o jsonpath='{.status.mTLS.issuedBackend}{"\n"}'
   ```

   Expected output:

   ```text
   kri_mid_kong-air-mesh_zone1_kong-mesh-system_flight-operations-id_
   ```
   {:.no-copy-code}

   The value is a {{site.mesh_product_name}} Resource Identifier (KRI) in the format `kri_mid_<mesh>_<zone>_<namespace>_<name>_`.
   If your zone isn't named `zone1`, the output contains your zone name.
   If the output shows `kri_mid_kong-air-mesh_zone1_kong-mesh-system_kong-air-identity_`, the mesh-wide identity still wins, because your `MeshIdentity` selector doesn't match the workload.

These two checks confirm that the external CA roots the identity of `flight-control`.
The generated `MeshTrust` contains your CA certificate, and `flight-operations-id` issues the workload's certificate.
