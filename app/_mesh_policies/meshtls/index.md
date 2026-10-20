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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshtls"
- text: MeshIdentity resource
  url: "/mesh/policies/meshidentity/"
- text: MeshTrafficPermission policy
  url: "/mesh/policies/meshtrafficpermission/"
---

The `MeshTLS` policy configures TLS on mesh connections:

* With `mode`, it controls whether destination proxies accept plaintext alongside mTLS.
* With `tlsVersion` and `tlsCiphers`, it sets the TLS versions and cipher suites for mesh
  connections.

[MeshIdentity](/mesh/policies/meshidentity/) supplies the workload identity and certificate.
Without an identity, the proxy skips `MeshTLS`, so setting `Strict` alone doesn't enable mTLS.
`MeshIdentity` has no TLS mode, version, or cipher settings, so the two don't overlap.

With an identity, inbounds default to `Strict` and reject plaintext. You only need a `MeshTLS`
policy to accept plaintext, or to restrict versions and ciphers beyond Envoy's defaults.

## Accept plaintext while migrating a service

The following example lets proxies labeled `app: legacy` accept both mTLS and plaintext, so
clients outside the mesh keep working while they move into it:

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

What each field does:

* `targetRef` selects the `legacy` proxies whose inbounds change. Leaving it out selects the
  whole mesh. To change one inbound, set `targetRef.sectionName` to its `name` in the
  Dataplane's `networking.inbound[]`. For an unnamed inbound, use its port as a string, such as
  `"8080"`.
* `mode: Permissive` lets those inbounds accept plaintext as well as mTLS. It doesn't turn off
  outbound mTLS.

Configuration goes in `spec.rules`. There's no `to`, because inbound TLS belongs to the proxy
accepting the connection. `rules` takes no `matches` either: the handshake happens before
there's a request to match, so a rule covers every client of the selected proxies.

Plaintext connections bypass [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)
checks, because they carry no workload identity. Limit `Permissive` to the destinations that
need it. Before you restore `Strict`, give the remaining callers identities, allow them in the
destination's permissions, and verify their mTLS connections.

## Mesh-wide fields

`mode` is accepted with any `targetRef`. `tlsVersion` and `tlsCiphers` are accepted only with
`kind: Mesh` and rejected on a `Dataplane`, because both peers must agree on a version and a
cipher.

Although they're set under `rules`, the mesh-wide version and cipher settings also apply to
outbound mesh TLS connections. They don't apply to TLS connections to external services.

On Kubernetes, create mesh-wide policies in the `{{site.mesh_namespace}}` namespace. A policy in
an application namespace only affects proxies in that namespace.

## Modes

`mode` accepts the following values:

{% table %}
columns:
  - title: "`mode`"
    key: mode
  - title: What the inbound accepts
    key: what
rows:
  - mode: "`Strict`"
    what: "mTLS only. This is the default."
  - mode: "`Permissive`"
    what: "Mesh mTLS, plaintext, and application-managed TLS."
{% endtable %}

`Permissive` doesn't downgrade mTLS from an identified caller. Application-managed TLS passes
through to the application, which handles its certificate and authorization checks. Only mesh
mTLS provides the workload identity that `MeshTrafficPermission` uses.

## TLS versions

`tlsVersion.min` and `tlsVersion.max` set the range of versions a proxy negotiates. Each
accepts `TLS10`, `TLS11`, `TLS12`, `TLS13`, or `TLSAuto`. `TLSAuto`, the default, leaves that
end to the Envoy version shipped with your installation.

A `min` higher than `max` is rejected. `TLSAuto` isn't compared, so it never causes that error.

The following example requires TLS 1.3 on both ends of mesh connections:

{% policy_yaml %}
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

Check peer compatibility before you apply it. Peers with no version in common can't complete
the handshake.

## Ciphers

`tlsCiphers` restricts the cipher suites a proxy offers. If it's unset, Envoy chooses. It
accepts the following cipher suites, and rejects any other value:

* `ECDHE-ECDSA-AES128-GCM-SHA256`
* `ECDHE-ECDSA-AES256-GCM-SHA384`
* `ECDHE-ECDSA-CHACHA20-POLY1305`
* `ECDHE-RSA-AES128-GCM-SHA256`
* `ECDHE-RSA-AES256-GCM-SHA384`
* `ECDHE-RSA-CHACHA20-POLY1305`

The list applies only to TLS 1.2 and older versions. Envoy doesn't allow TLS 1.3 cipher suites
to be configured, so `tlsCiphers` has no effect on TLS 1.3 connections.

## Overlapping policies

A more specific `Dataplane` policy overrides the mode from a mesh-wide policy. For example,
with a mesh-wide `Permissive` policy and a `Strict` policy for `app: payments`, only payments
rejects plaintext.

Removing the specific policy brings back the broader one. In that example, removing the
payments policy restores `Permissive`, not the default `Strict`.

## Validating the TLS boundary

1. Confirm that every selected proxy has a `MeshIdentity`. Without one, the policy is skipped.
1. For `Strict`, confirm that an mTLS connection succeeds and a plaintext connection is
   rejected.
1. For `Permissive`, confirm that both connections succeed, and that only the mTLS connection
   carries a workload identity.
1. For `tlsVersion`, confirm that a version inside the range succeeds and one outside it fails.
1. For `tlsCiphers`, inspect the negotiated cipher and confirm that both peers share at least
   one permitted suite.

For the mTLS test, use a caller that `MeshTrafficPermission` allows, because the handshake can
succeed while the request is still denied. For the plaintext test, use a caller without a mesh
proxy, because a mesh caller can add mTLS even to an `http://` request.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "Plaintext still reaches a strict destination"
    check: "Confirm that traffic goes through the selected proxy and that it has a workload identity. Look for other matching mode policies."
  - unexpected: "mTLS connects but the request is denied"
    check: "The destination's traffic permissions and the caller's SPIFFE ID."
  - unexpected: "The handshake fails after a version or cipher change"
    check: "Confirm that both peers share a TLS version, a permitted cipher, and a compatible certificate key type."
  - unexpected: "Changing `tlsCiphers` has no effect"
    check: "The negotiated version. The list doesn't apply to TLS 1.3."
{% endtable %}
