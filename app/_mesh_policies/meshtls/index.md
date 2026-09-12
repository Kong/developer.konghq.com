---
title: Mesh TLS
name: MeshTLSes
products:
- mesh
description: Decide whether an inbound accepts plaintext alongside mTLS, and set the TLS versions and ciphers a mesh permits.
content_type: plugin
icon: meshtls.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshtls"
- text: MeshIdentity policy
  url: "/mesh/policies/meshidentity/"
- text: MeshTrafficPermission policy
  url: "/mesh/policies/meshtrafficpermission/"
---

`MeshTLS` controls whether destination proxies accept plaintext alongside mTLS. It also sets
the TLS versions and cipher suites used for mesh connections.

[MeshIdentity](/mesh/policies/meshidentity/) supplies the workload identity and certificate.
Without a workload identity, the proxy skips `MeshTLS`; setting `Strict` alone does not
create certificates or enable mTLS.

Given an identity, an inbound is `Strict` unless a `MeshTLS` policy says otherwise, so plaintext
is rejected by default. A policy is only needed to relax that, or to narrow the versions and
ciphers below what Envoy would otherwise negotiate. A mesh that wants mTLS everywhere, with
Envoy's defaults for version and cipher, needs no `MeshTLS` at all.

`MeshIdentity` carries no TLS version, cipher or mode settings of its own, so the two do not
overlap: one decides whether a workload has an identity and where it comes from, the other what
the listener does with it.

## Accept plaintext while migrating a service

This policy lets proxies labeled `app: legacy` serve both mTLS and plaintext on their
inbounds, which keeps clients outside the mesh working while they are moved into the mesh:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTLS
mesh: default
name: legacy-permissive
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: legacy
  rules:
    - default:
        mode: Permissive
```
{% endpolicy_yaml %}

`targetRef` selects the `legacy` proxies whose inbound listeners change. `mode: Permissive`
allows them to accept plaintext as well as mesh mTLS. It does not turn outbound mTLS off.

Plaintext connections bypass [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)
checks because they carry no authenticated workload identity. Limit this exception to the
destinations that need it. Before restoring `Strict`, give the remaining callers identities,
allow them in the destination's permissions, and verify their mTLS connections.

## Where this policy applies

`spec.targetRef` selects the proxies whose inbounds are configured, and accepts `Mesh` or
`Dataplane` with `labels`.

Omitting `targetRef` selects the whole mesh. To limit a mode change to one inbound, set
`targetRef.sectionName` to its `name` in the selected Dataplane's `networking.inbound[]`.
For an unnamed inbound, use its port as a string, such as `"8080"`.

Configuration goes in `spec.rules`. There is no `to`: TLS on an inbound is a property of the
proxy accepting the connection, not of the client. `rules` also takes no `matches` — the
handshake happens before there is a request to match on, so a rule covers every client of the
selected proxies.

Two of the three fields are restricted to a mesh-wide policy:

{% table %}
columns:
  - title: Field
    key: field
  - title: Accepted on
    key: where
rows:
  - field: "`mode`"
    where: "Any `targetRef`."
  - field: "`tlsVersion`"
    where: "`kind: Mesh` only. On a `Dataplane` it is rejected with `tlsVersion can only be defined with top level targetRef kind: Mesh`."
  - field: "`tlsCiphers`"
    where: "`kind: Mesh` only, rejected the same way."
{% endtable %}

Both peers have to agree on a version and a cipher, so setting them per workload would mean
one half of a connection permitting something the other half does not. Applying them mesh-wide
keeps the two ends consistent.

Although these fields are written under `rules`, the mesh-wide version and cipher settings
also configure outbound mesh TLS connections. They do not configure TLS to external services.

## How mode overrides work

A more specific Dataplane policy can override the mode set by a mesh-wide policy. For example,
with mesh-wide `Permissive` and a Dataplane policy setting `Strict` for `app: payments`,
payments accepts only mTLS while the other destinations still accept plaintext.

Removing a specific override exposes the broader policy again. Removing the payments policy
in that example restores `Permissive`, not the built-in `Strict` default. Set `Strict`
explicitly when a broader permissive policy must remain in place.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Modes

{% table %}
columns:
  - title: "`mode`"
    key: mode
  - title: What the inbound accepts
    key: what
rows:
  - mode: "`Strict`"
    what: "mTLS only. The default, applied when no policy sets a mode."
  - mode: "`Permissive`"
    what: "Mesh mTLS or connections without mesh mTLS, including plaintext and application-managed TLS."
{% endtable %}

`Permissive` changes how the destination accepts connections. It does not downgrade mesh mTLS
sent by an identified caller. Application-managed TLS can also pass through to the application;
its certificate and authorization checks are the application's responsibility.

Only the mesh mTLS path provides the workload identity used by `MeshTrafficPermission`.
Encryption provided by the application does not turn that connection into mesh-authenticated
traffic.

## TLS versions

`tlsVersion.min` and `tlsVersion.max` bound the versions a proxy will negotiate. Each accepts
`TLS10`, `TLS11`, `TLS12`, `TLS13`, or `TLSAuto` to leave that end to Envoy, which is the
default for both.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTLS
mesh: default
name: require-tls13
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        tlsVersion:
          min: TLS13
          max: TLS13
```
{% endpolicy_yaml %}

A `min` above `max` is rejected with `min version must be lower than max`. `TLSAuto` at either
end is not compared, so it never triggers that.

This example requires TLS 1.3 on both ends of mesh connections. Check peer compatibility before
applying it across the mesh: a peer with no permitted version in common cannot complete the
handshake. `TLSAuto` follows the Envoy version shipped with your installation, rather than
fixing a particular minimum or maximum.

## Ciphers

`tlsCiphers` restricts the cipher suites a proxy offers, and accepts these six:

{% table %}
columns:
  - title: Cipher
    key: cipher
rows:
  - cipher: "`ECDHE-ECDSA-AES128-GCM-SHA256`"
  - cipher: "`ECDHE-ECDSA-AES256-GCM-SHA384`"
  - cipher: "`ECDHE-ECDSA-CHACHA20-POLY1305`"
  - cipher: "`ECDHE-RSA-AES128-GCM-SHA256`"
  - cipher: "`ECDHE-RSA-AES256-GCM-SHA384`"
  - cipher: "`ECDHE-RSA-CHACHA20-POLY1305`"
{% endtable %}

Anything else is rejected, with the error listing the six. Leaving `tlsCiphers` unset leaves
the choice to Envoy.

The list applies to TLS 1.2 and below. TLS 1.3 has its own cipher suites, which Envoy does not
allow to be configured, so restricting `tlsCiphers` while permitting TLS 1.3 constrains only the
older versions.

## Validate the TLS boundary

1. Confirm that every selected proxy has a `MeshIdentity`. Without one, this policy is skipped.
1. For `Strict`, connect with mTLS and confirm success, then connect without TLS and confirm
   rejection.
1. For `Permissive`, confirm that both connections succeed and that only the mTLS connection
   carries a workload identity.
1. When setting `tlsVersion`, test one permitted version and one version outside the configured
   range.
1. When setting `tlsCiphers`, inspect the negotiated cipher and confirm that both peers share at
   least one permitted suite.

Use an allowed mesh caller for the mTLS test. A TLS handshake can succeed while
`MeshTrafficPermission` rejects the request afterward. For the plaintext test, use a caller
without a mesh proxy; an identified mesh caller may add mTLS even when the application requests
an `http://` URL.

| Unexpected result | Check |
| --- | --- |
| Plaintext still reaches a supposedly strict destination | Confirm that traffic crosses the selected proxy and that its workload identity is available. Inspect other matching mode policies. |
| mTLS connects but the request is denied | Check destination traffic permissions and the caller's SPIFFE ID. |
| The handshake fails after a version or cipher change | Confirm a common TLS version, compatible certificate key type, and permitted cipher on both peers. |
| Changing `tlsCiphers` has no effect | Check the negotiated version: this list does not control TLS 1.3 suites. |
