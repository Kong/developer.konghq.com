---
title: Integrate an external CA
content_type: how_to
permalink: /mesh/integrate-an-external-ca/
description: Root Kong Air workload identities in an external certificate authority with the {{site.mesh_product_name}} cert-manager extension provider, so the CA private key never leaves cert-manager.
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
  position: 9
tldr:
  q: How do I integrate my mesh with an enterprise certificate authority?
  a: |
    Use a `MeshIdentity` with an extension provider, so the control plane sends each signing request to your CA and the CA private key never leaves it:
    1. Create a cert-manager `Issuer` backed by your CA, and store the CA certificate in a {{site.mesh_product_name}} Secret.
    2. Allow the workload's new SPIFFE ID in your `MeshTrafficPermission` rules.
    3. Create a `MeshIdentity` with the `certmanager` extension provider, which signs the workload certificates through the `Issuer`.
prereqs:
  inline:
    - title: Install cert-manager
      include_content: prereqs/cert-manager
      icon_url: /assets/icons/kubernetes.svg
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
  - q: How do I give the control plane my own CA certificate and key instead?
    a: |
      Use the `Bundled` provider.
      The control plane then holds the CA private key and signs every workload certificate itself, so use an extension provider when the key must stay in your PKI.

      The `Bundled` provider reads the CA certificate and key from {{site.mesh_product_name}} Secrets of type `system.kuma.io/secret` in the system namespace, with the `kuma.io/mesh` label.
      It can't read native Kubernetes TLS Secrets.
      Store the PEM files of your CA in two Secrets:

      ```bash
      kubectl create secret generic kong-air-external-ca-cert -n {{site.mesh_namespace}} \
        --type=system.kuma.io/secret --from-file=value=ca.crt
      kubectl create secret generic kong-air-external-ca-key -n {{site.mesh_namespace}} \
        --type=system.kuma.io/secret --from-file=value=ca.key
      kubectl label secret kong-air-external-ca-cert kong-air-external-ca-key \
        -n {{site.mesh_namespace}} kuma.io/mesh=kong-air-mesh
      ```

      Then reference the two Secrets from the `provider` block of the `MeshIdentity`.
      The rest of the `MeshIdentity` is the same as the cert-manager one in this guide:

      ```yaml
      provider:
        type: Bundled
        bundled:
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
      ```

      If your CA certificate is self-signed, also set `insecureAllowSelfSigned: true` under `bundled`.
      When the CA rotates, update the two Secrets, for example with the External Secrets Operator.
      For more information, see [Use your own CA](/mesh/policies/meshidentity/#use-your-own-ca).
related_resources:
  - text: Use your own CA
    url: /mesh/policies/meshidentity/#use-your-own-ca
  - text: Trust an external CA
    url: /mesh/policies/meshtrust/#trust-an-external-ca
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
---

Kong Air already runs a corporate public key infrastructure (PKI) for compliance, hardware-backed key storage, and issuance audits.
An external certificate authority (CA) lets Kong Air root the Secure Production Identity Framework for Everyone (SPIFFE) identities of its workloads in that PKI.

This guide uses the `certmanager` extension provider of `MeshIdentity`. For all the providers, see [Providers](/mesh/policies/meshidentity/#providers).

To learn more about what this guide does, read the following reference pages:

* [Use your own CA](/mesh/policies/meshidentity/#use-your-own-ca): how `MeshIdentity` gets certificates from an external CA
* [Trust an external CA](/mesh/policies/meshtrust/#trust-an-external-ca): how proxies trust the external CA

## Create the CA issuer

The `certmanager` extension provider needs an `Issuer` or `ClusterIssuer` for the mesh CA.
In this example, cert-manager creates a self-signed CA.
In production, back the `Issuer` with your corporate CA instead.

1. Create the `kong-air-mesh-ca-issuer` `Issuer`, backed by a CA certificate:

   ```bash
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

## Move flight-control to the external CA

The new `MeshIdentity` uses its own trust domain, `internal.kongair.com`, and selects only `flight-control`.
The new trust domain changes the SPIFFE ID of `flight-control`, and the switch takes effect in seconds.

1. Update the `MeshTrafficPermission` that matches `flight-control` by its SPIFFE ID.
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

   {:.warning}
   > Before you move workloads to a new trust domain, find every `MeshTrafficPermission` that references their SPIFFE IDs.
   > The receiving proxies deny any caller that no rule matches.
   > A `Prefix` match also needs an update when the trust domain changes.
   > See [Change an identity without losing access](/mesh/policies/meshidentity/#change-an-identity-without-losing-access).

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

   The selector has two `matchLabels`, so it's more specific than the mesh-wide `kong-air-identity`, and it issues the certificates of `flight-control`.

1. Confirm that `flight-control` gets its certificate from `kong-air-certmanager-identity` and not from the mesh-wide `kong-air-identity`:

   ```sh
   FLIGHT_POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
   kubectl get dataplaneinsight "$FLIGHT_POD" -n kong-air-production -o jsonpath='{.status.mTLS.issuedBackend}{"\n"}'
   ```

   Expected output:

   ```text
   kri_mid_kong-air-mesh_zone1_kong-mesh-system_kong-air-certmanager-identity_
   ```
   {:.no-copy-code}

1. Remove the old SPIFFE ID from the `MeshTrafficPermission`, so `check-in-api` accepts only the identity that your external CA issues to `flight-control`:

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
   EOF
   ```

## Validate

1. Confirm that the `kong-air-certmanager-identity` `MeshTrust` contains your CA.
   The extension creates this `MeshTrust` from the `caCert` Secret:

   ```sh
   kubectl get meshtrust kong-air-certmanager-identity -n {{site.mesh_namespace}} \
     -o jsonpath='{.spec.caBundles[0].pem.value}' | openssl x509 -noout -subject -issuer
   ```

   The output matches the `kong-air-certmanager-ca` certificate that the `Issuer` uses.
   This confirms that the mesh trusts your external CA:

   ```text
   subject=CN=kong-air-certmanager-ca
   issuer=CN=kong-air-certmanager-ca
   ```
   {:.no-copy-code}

1. Check that the `flight-control` `MeshService` lists the new trust domain:

   ```sh
   kubectl get meshservice flight-control -n kong-air-production -o yaml
   ```

   The control plane lists the identities that it computed for the service under `spec.identities`:

   ```yaml
   spec:
     identities:
     - type: SpiffeID
       value: spiffe://internal.kongair.com/ns/kong-air-production/sa/flight-control
     - type: SpiffeID
       value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
   ```
   {:.no-copy-code}

   `spec.identities` lists the SPIFFE ID of every `MeshIdentity` whose selector matches the workload, so the mesh-wide `kong-air-identity` entry stays next to the new one.
   Only `kong-air-certmanager-identity` issues the workload's certificates.

1. Send a request from `flight-control` to `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The response is the name of the `check-in-api` Pod that served the request.
   The `MeshTrafficPermission` now allows only the SPIFFE ID from your external CA, so the request succeeds only because `check-in-api` accepts the certificate that cert-manager signed.
