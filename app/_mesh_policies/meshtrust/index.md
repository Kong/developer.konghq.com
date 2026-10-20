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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshtrust"
- text: MeshIdentity resource
  url: "/mesh/policies/meshidentity/"
- text: MeshTLS policy
  url: "/mesh/policies/meshtls/"
---

The `MeshTrust` resource tells proxies which certificate authorities (CAs) can verify workload
certificates in a trust domain. A trust domain is the part of a SPIFFE ID between `spiffe://`
and the next `/`. For example, to verify `spiffe://corp.example.com/workload/payments`, the
certificate must chain to a CA published for `corp.example.com`.

`MeshTrust` works alongside two other resources:

* [MeshIdentity](/mesh/policies/meshidentity/) issues certificates. `MeshTrust` publishes the
  public CA certificates that verify them.
* [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) decides whether a verified
  caller can connect. Trust doesn't grant access.

You usually don't need to create this resource. A `MeshIdentity` with a `Bundled` provider
creates the `MeshTrust` for its own CA, which covers a single-zone mesh that issues its own
identities, and a migration between two Bundled identities. Create one manually when you
manage trust separately, for example to accept certificates from an external identity system.

Like `MeshIdentity`, `MeshTrust` isn't a policy. It has no `targetRef`, `to`, or `rules`, because a
trust domain is either trusted mesh-wide or it isn't. On Kubernetes, it's accepted only in the
system namespace.

## Trust an external CA

Get the issuing system's CA certificate bundle and the trust domain in its workload identities.
Never put a private key in this resource.

The following example trusts a corporate CA for `corp.example.com`. Replace the abbreviated PEM
with the complete CA certificate, including its BEGIN and END lines:

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

What each field does:

* `spec.trustDomain` names the trust domain this resource verifies.
* `spec.caBundles` lists the CA certificates allowed to sign identities in that domain.

This resource doesn't issue certificates. It only gives proxies the CA material to verify
certificates issued elsewhere.

## Trust domain and CA bundles

`MeshTrust` accepts the following fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`trustDomain`"
    value: "The trust domain the bundles verify. Required, at most 253 characters, and must match the trust domain of the identities being verified."
  - field: "`caBundles`"
    value: "At least one CA bundle. Each has `type: Pem` and the certificate in `pem.value`. The control plane rejects a value that isn't valid PEM, or that is a private key, when you apply it."
{% endtable %}

`caBundles` accepts several entries, so old and new certificates stay verifiable during a CA
rotation:

1. Publish the new CA alongside the old one.
1. Confirm that the receiving proxies have the updated trust configuration. Proxies receive
   trust bundle changes on the configuration refresh interval
   (`KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL`, 10 seconds by default).
1. Switch certificate issuance to the new CA, and confirm that connections with the new
   certificates work.
1. Remove the old CA when no workload needs certificates it issued.

Adding a CA doesn't change the issuer or renew workload certificates, so coordinate the change
with the identity provider. Both CAs belong to the same `spec.trustDomain`. A different trust
domain needs a separate `MeshTrust`.

## Trust domain matching

A certificate verifies only if a `MeshTrust` publishes a CA for the exact trust domain in its
SPIFFE ID. When identities don't verify, compare the following:

* The trust domain in the peer certificate's SPIFFE URI
* `spec.trustDomain` on each `MeshTrust`
* The `spiffeID` values in [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)
  rules, which match the ID the client presents

A mismatch with the trust bundle fails certificate verification. A mismatch in a permission
rule denies authorization after a successful handshake. The resource can be accepted in either
case, so diagnose the handshake and the authorization decision separately.

## Resources created from a MeshIdentity

A `MeshTrust` created by the control plane has `status.origin.kri`, which identifies its
`MeshIdentity`. A `MeshTrust` written by hand has no origin.

A generated `MeshTrust` always publishes the trust domain recorded in its `MeshIdentity`
status. An identity's trust domain can't be changed in place. For a staged transition, create a
second `MeshIdentity` with a different name, so each issuer publishes its own `MeshTrust`. Keep the old trust until no workload needs it, and update
authorization rules to accept the new identities before moving workloads.

A `MeshTrust` created on the global control plane is distributed to every zone. A `MeshTrust`
created on a zone, including every generated one, stays in that zone and only syncs to the
global control plane. In a multi-zone mesh, each zone generates its own `MeshTrust`, so for
cross-zone mTLS, create a copy of each zone's generated `trustDomain` and `caBundles` on the
global control plane. For more information, see
[Multi-zone meshes](/mesh/policies/meshidentity/#multi-zone-meshes).

To publish trust bundles yourself, set `meshTrustCreation: Disabled` on the `MeshIdentity`
`Bundled` provider and write the `MeshTrust` resources by hand.

## Validating certificate trust

1. Confirm that the trust domain in the peer certificate's SPIFFE URI is identical to
   `MeshTrust.spec.trustDomain`.
1. Confirm that `caBundles` contains the CA that signed the client certificate, not the client
   certificate or its private key.
1. Connect from a workload in that trust domain and confirm that the mTLS handshake succeeds.
1. Connect with a certificate from an untrusted domain or CA and confirm that the handshake
   fails.
1. In a multi-zone deployment, confirm that every zone has a `MeshTrust` for each other zone's
   trust domain, then connect across zones and confirm that the handshake succeeds.
