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

`MeshTrust` tells proxies which certificate authorities (CAs) they can use to verify workload
certificates in a trust domain. A trust domain is the part of a SPIFFE ID between
`spiffe://` and the next `/`.

For example, verifying `spiffe://corp.example.com/workload/payments` requires trust material
for `corp.example.com`. The certificate must chain to a CA published for that domain.
[MeshIdentity](/mesh/policies/meshidentity/) configures certificate issuance;
`MeshTrust` supplies the public certificates needed for verification.

Trust does not grant access. Once the peer's certificate is verified,
[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) determines whether the caller
may connect. A trusted caller can still be denied by authorization.

You usually do not need to create this resource yourself. A `MeshIdentity` with a `Bundled` provider creates the `MeshTrust`
for its own CA automatically, and that covers a single-zone mesh issuing its own identities.
Create one manually when you manage trust separately, such as when accepting certificates
issued by an external identity system. A migration between two Bundled identities can use
their automatically generated trust resources.

Like `MeshIdentity`, this is not a policy. It has no `targetRef`, `to` or `rules` — a trust
domain is either trusted or it is not, mesh-wide — and on Kubernetes it is accepted only in the
system namespace.

## Trust an external CA

Obtain the issuing system's CA certificate bundle and the trust domain used in its workload
identities. Set `spec.trustDomain` to that domain and replace the abbreviated PEM below with
the complete CA certificate, including its BEGIN and END lines. The example cannot be applied
with the `...` placeholder. Never put a private key in this resource.

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

`caBundles` accepts several entries so old and new certificates can remain verifiable during
a CA rotation:

1. Publish the new CA alongside the old CA.
1. Confirm that receiving proxies have received the updated trust configuration.
1. Switch certificate issuance to the new CA and verify connections using the new certificates.
1. Remove the old CA only when no workload needs certificates issued by it.

Adding a CA here does not change the issuer or renew workload certificates. Coordinate that
change with the identity provider. Both entries belong to the same `spec.trustDomain`;
a different trust domain needs a separate trust resource.

A `pem.value` that is not a certificate is rejected with
`provided certificate has incorrect format`. That check also rejects a PEM private-key block
specifically, so pasting a key where the certificate belongs fails on apply rather than at the
proxy.

## Trust domains have to match

A certificate verifies only if some `MeshTrust` publishes a CA bundle for the exact trust
domain in its SPIFFE ID. When identities are not verifying, compare three things:

- the trust domain in the peer certificate's SPIFFE URI
- `spec.trustDomain` on each `MeshTrust`
- the `spiffeID` values in any [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)
  rules, which are matched against the ID the client presents

A mismatch between the certificate and the trust bundle prevents certificate verification.
A mismatch in a permission rule denies authorization after a successful handshake. The resource
may be accepted in either case, so diagnose the handshake and the authorization decision separately.

## Resources created from a MeshIdentity

A `MeshTrust` the control plane created carries `status.origin.kri`, identifying the
`MeshIdentity` it came from. One written by hand has no origin.

The control plane updates the generated trust resource when its issuer's trust domain changes.
For a staged transition, use a second `MeshIdentity` with a different name so the two issuers
can publish separate trust resources. Keep the old trust until no workload requires it, and
update authorization rules to accept the new caller identities before moving workloads.

To publish trust bundles some other way, set `meshTrustCreation: Disabled` on the
`MeshIdentity`'s `Bundled` provider and write the `MeshTrust` resources yourself.

## Validate certificate trust

1. Compare the trust domain in the peer certificate's SPIFFE URI with `MeshTrust.spec.trustDomain`.
   The strings must be identical.
1. Confirm that `caBundles` contains the CA that signed the client certificate, not the client
   certificate or its private key.
1. Connect from a workload issued in that trust domain and confirm that the mTLS handshake
   succeeds.
1. Connect with a certificate from a domain or CA that is not trusted and confirm that the
   handshake fails.
1. In a multi-zone deployment, repeat the successful handshake across zones to prove that the
   trust resource has propagated.
