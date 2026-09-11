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

`MeshTLS` controls two things about a proxy's inbound listeners: whether they accept plaintext
as well as mTLS, and which TLS versions and ciphers are permitted.

It sits on top of [MeshIdentity](/mesh/policies/meshidentity/), which is what gives a proxy a
certificate in the first place. A proxy that no `MeshIdentity` matches gets no mTLS transport
socket at all, and this policy is skipped for it, logging `skip applying MeshTLS, the proxy has
no workload identity`. Neither the mode nor the TLS settings below mean anything until a mesh
has an identity.

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
keeps the normal mTLS filter chain and adds a plaintext path. It does not turn outbound mTLS off,
and it does not give plaintext clients an identity.

## Where this policy applies

`spec.targetRef` selects the proxies whose inbounds are configured, and accepts `Mesh` or
`Dataplane` with `labels`.

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
    what: "mTLS or plaintext. The listener gets a second filter chain matching raw TCP alongside the TLS one, and the connection takes whichever matches."
{% endtable %}

`Permissive` changes the inbound side only. Outbound connections are encrypted either way, so a
permissive destination still receives mTLS from a meshed client; what it gains is the ability to
also serve a client that speaks plaintext.

A permissive inbound cannot tell who an unencrypted client is, since the identity comes out of
the TLS handshake. A [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) matching on
`spiffeID` therefore has nothing to match for plaintext traffic. Treat `Permissive` as a state
to pass through during a migration rather than one to stay in.

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
