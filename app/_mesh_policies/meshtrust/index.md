---
title: Mesh Trust
name: MeshTrusts
products:
- mesh
description: Publish the CA bundles a mesh trusts to verify workload certificates.
content_type: plugin
icon: policy.svg
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshtrust"
- text: MeshIdentity resource
  url: "/mesh/policies/meshidentity/"
- text: MeshTLS policy
  url: "/mesh/policies/meshtls/"
---

`MeshTrust` publishes the CA bundles that verify certificates in one trust domain.
[MeshIdentity](/mesh/policies/meshidentity/) issues a workload its certificate; `MeshTrust` is
how every other proxy comes to accept it.

Most meshes never write one. A `MeshIdentity` with a `Bundled` provider creates the `MeshTrust`
for its own CA automatically, and that covers a single-zone mesh issuing its own identities.
Writing one by hand is for the cases that automatic creation cannot cover: trusting a CA the
mesh does not own, or keeping a second trust domain verifiable while workloads move between
them.

Like `MeshIdentity`, this is not a policy. It has no `targetRef`, `to` or `rules` — a trust
domain is either trusted or it is not, mesh-wide — and on Kubernetes it is accepted only in the
system namespace.

## Trust an external CA

{% policy_yaml %}
```yaml
type: MeshTrust
mesh: default
name: corporate-ca
spec:
  trustDomain: corp.example.com
  caBundles:
    - type: Pem
      pem:
        value: |
          -----BEGIN CERTIFICATE-----
          MIIDazCCAlOgAwIBAgIRAKrcbXW7tGrFmOA1rNBBCPkwDQYJKoZIhvcNAQELBQAw
          ...
          -----END CERTIFICATE-----
```
{% endpolicy_yaml %}

The two fields describe one trust relationship:

- `spec.trustDomain` names the domain in the workload SPIFFE IDs this resource verifies.
- `spec.caBundles` contains the CA certificates allowed to sign identities in that domain.

This resource does not issue a workload certificate. It only gives proxies the CA material
needed to verify certificates issued elsewhere.

## Configure the trust domain and CA bundles

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`trustDomain`"
    value: "The trust domain these bundles verify. Required, and at most 253 characters. It has to match the trust domain of the identities being verified."
  - field: "`caBundles`"
    value: "The CA bundles, at least one. Each has a `type` of `Pem` and the certificate under `pem.value`."
{% endtable %}

`caBundles` accepts several entries, which is what makes a CA rotation possible: publish the new
CA alongside the old one, wait for every workload to be re-issued from the new one, then remove
the old entry.

A `pem.value` that is not a certificate is rejected with
`provided certificate has incorrect format`. That check also rejects a PEM private-key block
specifically, so pasting a key where the certificate belongs fails on apply rather than at the
proxy.

## Trust domains have to match

A certificate verifies only if some `MeshTrust` publishes a CA bundle for the exact trust
domain in its SPIFFE ID. When identities are not verifying, compare three things:

- `status.trustDomain` on the `MeshIdentity`, which is the domain it actually issues in
- `spec.trustDomain` on each `MeshTrust`
- the `spiffeID` values in any [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)
  rules, which are matched against the ID the client presents

A mismatch in any of them shows up as traffic being denied rather than as an error on the
resource.

## Resources created from a MeshIdentity

A `MeshTrust` the control plane created carries `status.origin.kri`, identifying the
`MeshIdentity` it came from. One written by hand has no origin.

The generated resource is keyed by the identity's name, which is why moving a trust domain means
creating a second `MeshIdentity` under a new name rather than editing the existing one — see
[Changing it is a migration, not an edit](/mesh/policies/meshidentity/#changing-it-is-a-migration-not-an-edit).
Two identities publish two `MeshTrust` resources, so both domains stay verifiable for the whole
transition.

To publish trust bundles some other way, set `meshTrustCreation: Disabled` on the
`MeshIdentity`'s `Bundled` provider and write the `MeshTrust` resources yourself.

## Validate certificate trust

1. Compare `MeshIdentity.status.trustDomain` with `MeshTrust.spec.trustDomain`. The strings must
   be identical.
1. Confirm that `caBundles` contains the CA that signed the client certificate, not the client
   certificate or its private key.
1. Connect from a workload issued in that trust domain and confirm that the mTLS handshake
   succeeds.
1. Connect with a certificate from a domain or CA that is not trusted and confirm that the
   handshake fails.
1. In a multi-zone deployment, repeat the successful handshake across zones to prove that the
   trust resource has propagated.
