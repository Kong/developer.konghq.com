---
title: Mesh Identity
name: MeshIdentities
description: Define how workloads obtain cryptographic identity with MeshIdentity, supporting SPIFFE IDs and multiple certificate providers.
products:
  - mesh
content_type: plugin
type: policy
icon: policy.svg
tags:
  - certificates
  - security
  - mtls

min_version:
  mesh: '2.12'

related_resources:
  - text: Issue identity with MeshIdentity bundled provider
    url: /mesh/issue-identity-with-meshidentity/
  - text: Issue identity with MeshIdentity Spire provider
    url: /mesh/issue-identity-with-meshidentity-spire/
  - text: MeshService
    url: /mesh/meshservice/
  - text: MeshTLS
    url: /mesh/policies/meshtls/
  - text: MeshTrafficPermission with SPIFFE ID matchers
    url: /mesh/policies/meshtrafficpermission_experimental/
---

{:.warning}
> This resource is experimental.
> It requires [MeshService](/mesh/meshservice/) to be enabled.
> It works on Kubernetes since version 2.12, and on Universal since version 2.13.

`MeshIdentity` is a resource that defines how workloads in a mesh obtain their cryptographic identity.
It separates the responsibility of issuing identities from establishing trust,
enabling {{site.mesh_product_name}} to adopt [SPIFFE](https://spiffe.io/docs/latest/spiffe-about/overview/) compliant practices
while remaining flexible and easy to use.

With `MeshIdentity`, users can:

* Enable secure mTLS between services, using trusted certificate authorities.
* Switch identity providers without downtime, for example when migrating from built-in certificates to [Spire](https://spiffe.io/docs/latest/spire-about/).
* Assign different identity providers to subsets of workloads, allowing more granular control.

The following example shows the full structure:

{% navtabs "meshidentity-structure" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: "{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}"
    path: "{% raw %}/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}{% endraw %}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true
```
{% endnavtab %}
{% navtab "Universal (2.13+)" %}
{% raw %}
```yaml
type: MeshIdentity
name: identity
mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/workload/{{ .Workload }}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true
```
{% endraw %}
{% endnavtab %}
{% endnavtabs %}

## Configuration

`MeshIdentity` controls how data plane proxies receive identity certificates.
The following key fields define how identities are issued and applied:

* [`selector`](#selector): Which data plane proxies this identity applies to.
* [`spiffeID`](#spiffeid): How the SPIFFE ID is constructed (trust domain and path).
* [`provider`](#provider): Which system issues the certificates (`Bundled`, `Spire`, or an external CA through the `Extension` provider).

### Selector

The selector field controls which data plane proxies a `MeshIdentity` applies to.
It uses `matchLabels` selectors on data plane proxy tags.
You can scope an identity to all workloads, a subset of workloads, or none at all.

When multiple `MeshIdentity` resources apply to the same data plane proxy,
the one with the most specific selector (the greatest number of matching labels) takes precedence.
If two policies have selectors with the same number of labels, {{site.mesh_product_name}} compares their names lexicographically.
The policy whose name comes first in alphabetical order takes precedence.

#### Examples

The following table contains examples of the selector field with different scopes:

{% table %}
columns:
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - description: Apply to all data plane proxies
    example: |
      ```yaml
      spec:
        selector:
          dataplane:
            matchLabels: {}
      ```
  - description: Apply to a group of data plane proxies
    example: |
      ```yaml
      spec:
        selector:
          dataplane:
            matchLabels:
              app: my-app
      ```
  - description: Apply to nothing
    example: |
      ```yaml
      spec:
        selector: {}
      ```
{% endtable %}

### SPIFFE ID

The `spiffeID` field lets you override how SPIFFE IDs are constructed for the data plane proxies selected by this `MeshIdentity`.
By default, {{site.mesh_product_name}} generates a SPIFFE ID based on the mesh and zone.
With `spiffeID`, you can customize the `trustDomain` and the `path` template.
The default `path` template depends on the environment:

{% navtabs "spiffeid-default-path" %}
{% navtab "Kubernetes" %}

{% raw %}

```yaml
spec:
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}"
```

{% endraw %}

{% endnavtab %}
{% navtab "Universal (2.13+)" %}

{% raw %}

```yaml
spec:
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/workload/{{ .Workload }}"
```

{% endraw %}

{% endnavtab %}
{% endnavtabs %}

Supported variables in the `trustDomain` field are:

* `.Mesh`
* `.Zone`

Supported variables in the `path` field are:

* `.Namespace` - The Kubernetes namespace
* `.ServiceAccount` - The Kubernetes service account
* `.Workload` - The workload identifier

You can also use resource `labels` in both `trustDomain` and `path`, for example:

{% raw %}

```yaml
spec:
  spiffeID:
    trustDomain: '{{ label "kuma.io/mesh" }}.{{ label "kuma.io/zone" }}.mesh.local'
    path: '/ns/{{ label "k8s.kuma.io/namespace" }}/sa/{{ label "k8s.kuma.io/service-account" }}'
```

{% endraw %}

#### Workload label requirement {% new_in 2.13 %}

When using {% raw %}`{{ label "kuma.io/workload" }}`{% endraw %} or {% raw %}`{{ .Workload }}`{% endraw %} in the `path` template, data plane proxies selected by this `MeshIdentity` must have the `kuma.io/workload` label. This label can be provided either:

* Via a [data plane proxy token](/mesh/data-plane-proxy-authentication/#workload-label-in-tokens) generated with the `--workload` parameter
* Directly on the data plane proxy resource

Connections from data plane proxies lacking the required label will be rejected.

Here's an example using the workload identifier in the path:

{% raw %}

```yaml
spec:
  spiffeID:
    trustDomain: '{{ .Mesh }}.{{ .Zone }}.mesh.local'
    path: '/workload/{{ label "kuma.io/workload" }}'
```

{% endraw %}


### Provider

The `provider` field defines how identity certificates are issued.
This field is required and must specify one of the supported provider types:

* `Bundled`: Certificates are issued by {{site.mesh_product_name}}'s control plane, either autogenerated or supplied by the user.
* `Spire`: Certificates are issued directly by a SPIRE Agent through SDS.
* `Extension`: Certificates are issued by an external certificate authority. {{site.mesh_product_name}} ships the following extension providers: [HashiCorp Vault](#hashicorp-vault), [cert-manager](#cert-manager), and [AWS Private CA](#aws-private-ca).

When using an `Extension` provider, set `provider.type` to `Extension`, choose the provider with `provider.extension.name`, and configure it under `provider.extension.config`.
All extension providers are SPIFFE compliant: {{site.mesh_product_name}} generates a certificate signing request for the workload's SPIFFE ID and the external CA signs it.
The control plane can also create the matching [`MeshTrust`](/mesh/policies/meshtrust/) from the provider's CA chain. Set `meshTrustCreation: Disabled` to manage `MeshTrust` resources yourself.

{:.note}
> Secrets referenced through `secretRef` are {{site.mesh_product_name}} [`Secret`](/mesh/secure-deployment/secrets/) resources stored in the control plane namespace and labeled with `kuma.io/mesh`. Every secure data source field also accepts `file`, `envVar`, or `insecureInline` (development only) instead of `secretRef`.

#### HashiCorp Vault {% new_in 2.14 %}

The `vault` extension provider issues workload certificates from a [Vault PKI secrets engine](https://developer.hashicorp.com/vault/docs/secrets/pki).

Prerequisites:

* A mounted PKI secrets engine. The default mount path is `kong-mesh-pki-<mesh>`.
* A PKI role (default `dataplanes`) that allows the mesh trust domain, for example permitting SANs that match `spiffe://<trust-domain>/*`.
* A Vault policy that grants the control plane access to the role:

```hcl
path "kong-mesh-pki-default/issue/dataplanes" { capabilities = ["create", "update"] }
path "kong-mesh-pki-default/ca_chain"         { capabilities = ["read"] }
path "kong-mesh-pki-default/ca/pem"           { capabilities = ["read"] }
```

The control plane supports three authentication methods (`Token`, `TLS`, and `AWS`) and can connect either directly to a Vault server or to a local Vault Agent.
The following example authenticates with a static token stored as a {{site.mesh_product_name}} `Secret`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity-vault
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  provider:
    type: Extension
    extension:
      name: vault
      config:
        connection:
          type: Server
          server:
            address: https://vault.vault.svc:8200
            tls:
              caCert:
                type: Secret
                secretRef:
                  kind: Secret
                  name: vault-ca
            auth:
              type: Token
              token:
                type: Secret
                secretRef:
                  kind: Secret
                  name: vault-token
        pki:
          mount: kong-mesh-pki-default
          role: dataplanes
          certificateParameters:
            expiry: 24h
```

Rotating the token is non-disruptive: update the `value` of the referenced `Secret` and the control plane uses the new token on the next certificate issuance.

To authenticate with a TLS client certificate, set `auth.type` to `TLS` and provide `clientCert` and `clientKey`:

```yaml
        connection:
          type: Server
          server:
            address: https://vault.vault.svc:8200
            auth:
              type: TLS
              tls:
                clientCert:
                  type: Secret
                  secretRef: { kind: Secret, name: vault-client-cert }
                clientKey:
                  type: Secret
                  secretRef: { kind: Secret, name: vault-client-key }
```

To use Vault's AWS auth method, set `auth.type` to `AWS`. Credentials come from the standard AWS credential chain (environment, instance profile, or IRSA), so no secret is stored in the mesh:

```yaml
        connection:
          type: Server
          server:
            address: https://vault.example.com:8200
            auth:
              type: AWS
              aws:
                type: IAM
                role: kong-mesh
                mount: aws
```

To delegate authentication to a [Vault Agent](https://developer.hashicorp.com/vault/docs/agent-and-proxy/agent) sidecar, set `connection.type` to `Agent` and omit `auth`:

```yaml
        connection:
          type: Agent
          agent:
            address: http://127.0.0.1:8100
        pki:
          mount: kong-mesh-pki-default
```

The following table describes the `vault` configuration fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`connection.type`"
    description: "`Server` for a direct connection or `Agent` for a local Vault Agent."
  - field: "`connection.namespace`"
    description: "Vault namespace (Vault Enterprise only)."
  - field: "`connection.server.address`"
    description: "URL of the Vault server."
  - field: "`connection.server.tls.caCert`"
    description: "CA certificate used to verify Vault's TLS certificate."
  - field: "`connection.server.tls.skipVerify`"
    description: "Disable TLS verification. Development only."
  - field: "`connection.server.auth.type`"
    description: "Authentication method: `Token`, `TLS`, or `AWS`."
  - field: "`pki.mount`"
    description: "PKI mount path. Defaults to `kong-mesh-pki-<mesh>`."
  - field: "`pki.role`"
    description: "PKI role used to issue certificates. Defaults to `dataplanes`."
  - field: "`pki.certificateParameters.expiry`"
    description: "Requested certificate lifetime (default `24h`). Capped by the PKI role `max_ttl`."
  - field: "`meshTrustCreation`"
    description: "`Enabled` (default) or `Disabled`."
{% endtable %}

#### cert-manager {% new_in 2.14 %}

The `certmanager` extension provider issues workload certificates through a [cert-manager](https://cert-manager.io/) `Issuer` or `ClusterIssuer`. This provider works on Kubernetes only.

Prerequisites:

* cert-manager installed in the cluster.
* An `Issuer` or `ClusterIssuer` that can sign certificates with a URI SAN containing the workload's SPIFFE ID. A CA issuer is the common choice.

cert-manager does not expose the issuing CA to the mesh automatically, so provide its CA certificate (as a {{site.mesh_product_name}} `Secret`) for `MeshTrust` auto-creation:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity-certmanager
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  provider:
    type: Extension
    extension:
      name: certmanager
      config:
        issuerRef:
          name: ca-issuer
          kind: ClusterIssuer
          group: cert-manager.io
        caCert:
          type: Secret
          secretRef:
            kind: Secret
            name: meshidentity-certmanager-ca
        certificateParameters:
          expiry: 24h
```

If you omit `caCert`, set `meshTrustCreation: Disabled` and create the `MeshTrust` resource manually.

The following table describes the `certmanager` configuration fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`issuerRef.name`"
    description: "Name of the `Issuer` or `ClusterIssuer`. Required."
  - field: "`issuerRef.kind`"
    description: "`Issuer` or `ClusterIssuer`. Defaults to `Issuer`."
  - field: "`issuerRef.group`"
    description: "API group of the issuer. Defaults to `cert-manager.io`."
  - field: "`caCert`"
    description: "Issuing CA certificate, used for `MeshTrust` auto-creation."
  - field: "`certificateParameters.expiry`"
    description: "Requested certificate lifetime (default `24h`)."
  - field: "`meshTrustCreation`"
    description: "`Enabled` (default, requires `caCert`) or `Disabled`."
{% endtable %}

#### AWS Private CA {% new_in 2.14 %}

The `acmpca` extension provider signs workload certificates with an [AWS Private CA](https://docs.aws.amazon.com/privateca/latest/userguide/PcaWelcome.html).

Prerequisites:

* An active AWS Private CA whose template allows certificates with a SPIFFE URI SAN.
* AWS credentials available to the control plane through the standard AWS credential chain (environment variables, instance profile, or IRSA — IRSA is recommended on EKS). The AWS region is taken from the CA ARN, so no separate region setting is required.
* IAM permissions on the control plane identity: `acm-pca:IssueCertificate`, `acm-pca:GetCertificate`, and `acm-pca:GetCertificateAuthorityCertificate`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity-acmpca
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  provider:
    type: Extension
    extension:
      name: acmpca
      config:
        arn: arn:aws:acm-pca:eu-central-1:123456789012:certificate-authority/12345678-1234-1234-1234-123456789012
        certificateParameters:
          expiry: 24h
```

The following table describes the `acmpca` configuration fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`arn`"
    description: "ARN of the AWS Private CA. Required. The AWS region is parsed from this value."
  - field: "`certificateParameters.expiry`"
    description: "Requested certificate lifetime (default `24h`)."
  - field: "`meshTrustCreation`"
    description: "`Enabled` (default) or `Disabled`. When enabled, the control plane fetches the CA chain and builds the `MeshTrust`."
{% endtable %}
