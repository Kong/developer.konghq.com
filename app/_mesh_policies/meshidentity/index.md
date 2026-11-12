---
title: Mesh Identity
name: MeshIdentities
products:
- mesh
description: Give workloads a SPIFFE identity and the certificates that prove it.
content_type: plugin
icon: policy.svg
related_resources:
- text: Migrate mesh mTLS to MeshIdentity
  url: "/mesh/migrate-mtls-to-meshidentity/"
- text: Policy targeting
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshidentity"
- text: MeshTrust resource
  url: "/mesh/policies/meshtrust/"
- text: MeshTrafficPermission policy
  url: "/mesh/policies/meshtrafficpermission/"
- text: "Concepts: Identity and trust"
  url: "/mesh/concepts/#identity-and-trust"
---

The `MeshIdentity` resource gives workloads an identity and configures the provider that issues
their certificates. A workload presents its certificate when it connects to another proxy over
mTLS. The certificate contains a SPIFFE ID, such as
`spiffe://payments.eu.mesh.local/ns/storefront/sa/frontend`, that identifies the caller.

Identity works together with the following resources:

{% table %}
columns:
  - title: Resource
    key: resource
  - title: Responsibility
    key: responsibility
rows:
  - resource: "`MeshIdentity`"
    responsibility: "Selects workloads and configures their identities and certificate provider."
  - resource: "[MeshTrust](/mesh/policies/meshtrust/)"
    responsibility: "Publishes the CA certificates that proxies use to verify peers."
  - resource: "[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)"
    responsibility: "Decides whether an authenticated caller can connect to a destination."
{% endtable %}

A certificate doesn't grant access, so configure traffic permissions before or alongside
identities. [MeshTLS](/mesh/policies/meshtls/) controls whether a destination also accepts
plaintext and which TLS settings it uses.

A proxy that no `MeshIdentity` matches gets no identity and no mTLS. `Mesh.mtls` is removed
from the API, so `MeshIdentity` is the only way to issue identities.

`MeshIdentity` isn't a policy in the usual sense. It has no `targetRef`, `to`, or `rules`, and
selects proxies with a label selector instead. On Kubernetes, it's only accepted in the system
namespace.

## Issue identities for every workload in the mesh

The following example issues identities to every proxy the resource reaches in the `default`
mesh, from a certificate authority (CA) that the control plane generates. On Kubernetes, create
it in the mesh system namespace:

{% policy_yaml %}
```yaml
type: MeshIdentity
mesh: default
name: default-identity
spec:
  selector:
    dataplane: {}
  provider:
    type: Bundled
    bundled:
      autogenerate:
        enabled: true
      insecureAllowSelfSigned: true
      meshTrustCreation: Enabled
```
{% endpolicy_yaml %}

What each field does:

* `selector.dataplane: {}` selects every proxy the resource reaches. For more information, see
  [Multi-zone meshes](#multi-zone-meshes).
* `type: Bundled` keeps the CA in the control plane.
* `autogenerate.enabled: true` creates the CA.
* `insecureAllowSelfSigned: true` allows the generated self-signed CA, and is required with
  `autogenerate`. It doesn't disable certificate verification: peers verify certificates against
  the CA published in `MeshTrust`.
* `meshTrustCreation: Enabled` publishes the CA in a `MeshTrust`, so peers can verify the
  identities it issues.

To use certificates from your existing PKI, see [Use your own CA](#use-your-own-ca).

### Multi-zone meshes

An identity created on a zone control plane covers only that zone. Neither the identity nor its
`MeshTrust` is distributed to other zones. In a multi-zone mesh, create the identity on the
global control plane so every zone receives the same configuration.

Each zone still initializes the identity separately. With `autogenerate`, each zone generates
its own CA and publishes it in a `MeshTrust` in that zone. With the default trust domain
template, each zone also issues in its own trust domain. A generated `MeshTrust` syncs to the
global control plane, but isn't sent to other zones, so by default proxies don't trust
certificates issued in another zone.

For cross-zone mTLS, read each zone's generated `MeshTrust` on the global control plane, and
create a `MeshTrust` with the same `trustDomain` and `caBundles` on the global control plane,
which distributes it to every zone. If a zone's CA changes, update its copy too. Also allow the
other zones' trust domains in [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)
rules.

{:.warning}
> A zone with no applicable `MeshIdentity` has no workload certificates, so its proxies get no
> inbound TLS listener. Traffic inside that zone is plaintext, and
> [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) cannot apply, because it only
> attaches to TLS filter chains. Requests still succeed, so the zone looks healthy, but
> cross-zone requests into it fail with `503`, because the calling proxy attempts mTLS.

## Proxy selection

`spec.selector.dataplane.matchLabels` selects the proxies. An empty `dataplane: {}` matches
every proxy the resource reaches.

When several identities match a proxy, the one with the most match labels wins. If two tie, the
one whose name sorts first alphabetically wins. Providers aren't combined.

For example, an identity with `matchLabels: {app: payments}` overrides a mesh-wide
`dataplane: {}` identity for the payments proxies, and other proxies keep the mesh-wide one. If
the narrower identity has a different trust domain, the payments proxies' trust domain changes
too. Before changing a selector, check that peers trust the new provider's CA and that
authorization rules allow the new caller identity.

## Providers

`spec.provider.type` sets where certificates come from:

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Where certificates come from
    key: what
rows:
  - type: "`Bundled`"
    what: "A CA held by the control plane, either generated by it or supplied by you."
  - type: "`Spire`"
    what: "A SPIRE agent on the node, reached over its socket. `spire.agent.timeout` limits the connection time, and defaults to 1s."
  - type: "`Extension`"
    what: "An enterprise CA, set with `extension.name` and an `extension.config` validated for that provider. `extension.name` accepts `acmpca`, `vault`, or `certmanager` (Kubernetes only)."
{% endtable %}

### Use your own CA

To use your own CA, leave `autogenerate` off and give `bundled.ca` a CA certificate and its
private key, each as a secure data source. Both are required, and `ca` can't be combined with
`autogenerate.enabled: true`. A `Bundled` provider with neither `autogenerate` nor `ca` is
rejected.

The CA certificate must have the `CA:TRUE` basic constraint and the `keyCertSign` key usage, and
must not have the `keyAgreement` key usage. A self-signed root CA also needs
`insecureAllowSelfSigned: true`. Otherwise, the identity reports `Provider: False` and issues
no certificates.

The following example reads an intermediate CA from the `mesh-ca-cert` and `mesh-ca-key`
secrets, and issues leaf certificates that last 24 hours. Create both secrets before applying
it. They hold signing credentials, not a workload's certificate and key:

{% policy_yaml %}
```yaml
type: MeshIdentity
mesh: default
name: corporate-ca
spec:
  selector:
    dataplane: {}
  provider:
    type: Bundled
    bundled:
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: mesh-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: mesh-ca-key
      certificateParameters:
        expiry: 24h
```
{% endpolicy_yaml %}

Secure data sources use the following field for each type:

{% table %}
columns:
  - title: Type
    key: type
  - title: Value field
    key: value
rows:
  - type: "`Secret`"
    value: "`secretRef.name`, with `secretRef.kind: Secret`"
  - type: "`File`"
    value: "`file.path`"
  - type: "`EnvVar`"
    value: "`envVar.name`"
  - type: "`InsecureInline`"
    value: "`insecureInline.value`"
{% endtable %}

The control plane loads the CA, so file paths and environment variables must be available to
the control plane. Don't embed the private key in a policy that other users can read.

## SPIFFE ID

A SPIFFE ID has two parts after `spiffe://`: the trust domain and the workload path. In
`spiffe://payments.eu.mesh.local/ns/storefront/sa/frontend`, the trust domain is
`payments.eu.mesh.local` and the path is `/ns/storefront/sa/frontend`.

`spec.spiffeID` sets both parts as Go templates, using the following variables:

{% table %}
columns:
  - title: Field
    key: field
  - title: Variables it can use
    key: vars
rows:
  - field: "`trustDomain`"
    vars: "`.Mesh`, `.Zone`"
  - field: "`path`"
    vars: "`.TrustDomain`, `.Namespace`, `.ServiceAccount`, `.Workload`"
{% endtable %}

{{site.mesh_product_name}} uses the following defaults:

{% raw %}
```yaml
spiffeID:
  # trustDomain, on every environment
  trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
  # path, on Kubernetes
  path: "/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}"
  # path, on Universal
  # path: "/workload/{{ .Workload }}"
```
{% endraw %}

With the default Kubernetes path, replicas that share a namespace and service account share an
identity.

Both fields also accept a `label` function, so `{% raw %}{{ label "team" }}{% endraw %}` reads
a label from the resource. A missing label fails rendering instead of resolving to an empty
string. A template that doesn't parse is rejected on apply, with the Go template error.

### Change an identity without losing access

`spec.spiffeID.trustDomain` and `spec.spiffeID.path` are immutable. The API rejects an update
that changes either one.

The control plane renders the trust domain once, when it first initializes the identity, and
records it in `status.trustDomain`. Later changes to template inputs, such as renaming a zone,
don't change the domain that the identity issues in or that its `MeshTrust` publishes.

To change identities, create a second `MeshIdentity` with a different name, so the old issuer
and its trust material stay in place while you move workloads:

1. Configure the new identity, and make sure receiving proxies trust its CA.
1. Update destination `MeshTrafficPermission` rules to allow both the old and new caller IDs.
1. Move a small group of workloads to the new identity with `selector.dataplane.matchLabels`.
   Make sure the new selector wins under the [selection rules](#proxy-selection).
1. Check the workloads' issued certificates and their calls to destinations.
1. Move the remaining workloads. Remove the old permissions and trust only when no workload
   needs them.

Trusting both CAs isn't enough: authorization rules must also match the new IDs. Deleting and
recreating an issuer can replace CA material that's still needed to verify existing
certificates.

## MeshTrust creation

A `Bundled` provider creates a [MeshTrust](/mesh/policies/meshtrust/) that publishes its CA
bundle, so other proxies can verify the certificates it issues. If your mesh publishes trust
bundles another way, set `bundled.meshTrustCreation: Disabled`.

## Validating identity issuance

Read the resource's status after applying it, replacing `$IDENTITY_NAME` with your identity's
name:

```sh
kubectl get meshidentity $IDENTITY_NAME -n {{site.mesh_namespace}} -o yaml
```

For the autogenerated `Bundled` example, the following conditions should be `True`:

{% table %}
columns:
  - title: Condition
    key: condition
  - title: Means
    key: what
rows:
  - condition: "`Provider`"
    what: "The provider generated or loaded the CA."
  - condition: "`MeshTrustCreated`"
    what: "The `MeshTrust` publishing the CA bundle exists."
  - condition: "`Ready`"
    what: "The identity is initialized and issuing certificates."
{% endtable %}

`MeshTrustCreated` is only reported when the provider publishes a CA for automatic trust
creation, so it can be missing when trust is managed separately. If a condition is false, its
`reason` and `message` name the step that failed.

A resource with no `provider` runs in SPIFFE-ID-only mode: it advertises service identities
without issuing workload certificates. Its status shows `SpiffeIDProvider: True` and
`Ready: False` with reason `PartiallyReady`. This status doesn't prove mTLS.

A ready resource only confirms initialization. To check certificate delivery, peer trust, and
permissions together:

1. Read `MeshTrust.spec.trustDomain` on the generated trust resource to see the domain it
   publishes.
1. Inspect a selected proxy's certificate through Envoy's `/certs` admin endpoint, and confirm
   that its SPIFFE URI matches the expected trust domain and path.
1. Make an authorized mTLS request to a peer.
