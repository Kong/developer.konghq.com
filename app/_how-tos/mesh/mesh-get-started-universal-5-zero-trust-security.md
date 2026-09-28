---
title: Introduce zero-trust security
description: "Issue workload identities with MeshIdentity, watch traffic default to deny, and allow only what you mean to with MeshTrafficPermission."
content_type: how_to
permalink: /mesh/get-started/universal/zero-trust-security/
breadcrumbs:
  - /mesh/
products:
  - mesh
works_on:
  - on-prem
tags:
  - get-started
  - universal-mode
  - security
series:
  id: mesh-get-started-universal-3
  position: 5
tldr:
  q: How do I turn on mTLS and restrict traffic in {{site.mesh_product_name}} 3?
  a: Create a `MeshIdentity` so workloads get certificates, which makes traffic default to deny, then allow specific callers with a `MeshTrafficPermission` matching on their SPIFFE ID.
related_resources:
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
  - text: MeshTLS
    url: /mesh/policies/meshtls/
---

So far both workloads talk to each other with nothing stopping them, and nothing encrypting
them. This page fixes both.

{:.warning}
> This differs substantially from {{site.mesh_product_name}} 2.x. `Mesh.mtls` is removed, so mTLS
> comes from a `MeshIdentity`. `MeshTrafficPermission`'s `from` array and `action` field are
> removed, so permissions are expressed as `rules` matching the caller's SPIFFE ID. Following a
> 2.x guide here will not work.

## Issue identities

A workload gets a certificate from a [MeshIdentity](/mesh/policies/meshidentity/). Without one,
proxies have no identity, serve plaintext, and neither `MeshTLS` nor `MeshTrafficPermission`
applies to them.

```sh
cat <<'EOF' | kongctl create mesh -f - --control-plane-url "$KONG_MESH_CP"
type: MeshIdentity
mesh: default
name: demo-identity
spec:
  selector:
    dataplane: {}
  spiffeID:
    trustDomain: default.mesh.local
  provider:
    type: Bundled
    bundled:
      autogenerate:
        enabled: true
      insecureAllowSelfSigned: true
      meshTrustCreation: Enabled
EOF
```

`selector.dataplane: {}` matches every proxy in the mesh. `insecureAllowSelfSigned` accepts a CA
the control plane generates itself, which suits a demo and nothing else — a real mesh supplies a
CA under `bundled.ca`.

Setting `trustDomain` explicitly keeps the SPIFFE IDs predictable. Left out, it renders from
`{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}`.

Check it initialized:

```sh
kongctl get mesh meshidentities demo-identity -o yaml --control-plane-url "$KONG_MESH_CP"
```

`status.conditions` should report `Provider`, `MeshTrustCreated` and `Ready` as true, and
`status.trustDomain` shows the domain issuance is pinned to. A `MeshTrust` publishing the CA
bundle was created alongside it:

```sh
kongctl get mesh meshtrusts --control-plane-url "$KONG_MESH_CP"
```

## Traffic is now denied

Try the demo application again:

```sh
curl http://127.0.0.1:25050/api/v1/items/hello
```

It fails. Two things changed at once:

- Proxies now have identities, so `MeshTrafficPermission` applies — and no permission exists,
  so nothing is allowed. {{site.mesh_product_name}} 3 creates no default allow-all permission.
- Inbounds are `Strict` unless a [MeshTLS](/mesh/policies/meshtls/) policy says otherwise, so
  plaintext from outside the mesh is rejected. `curl` on your host is outside the mesh.

That is zero trust arriving: nothing is permitted until you say so.

## Allow the demo app to reach the key/value store

A permission names the caller by the identity it presents, not by a tag it sets:

```sh
cat <<'EOF' | kongctl create mesh -f - --control-plane-url "$KONG_MESH_CP"
type: MeshTrafficPermission
mesh: default
name: allow-demo-app-to-kv
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://default.mesh.local/workload/demo-app
EOF
```

The SPIFFE ID follows from the `kuma.io/workload` label you set in step 1: on Universal the path
defaults to `/workload/{workload}`, so `demo-app` becomes
`spiffe://default.mesh.local/workload/demo-app`.

{:.warning}
> In 2.x the documented idiom was a mesh-wide `Deny` followed by narrower `Allow` rules, because
> the last matching rule won. Precedence is now fixed: every `deny` is evaluated before every
> `allow`, so a deny-all can never be re-opened. Write the allows; traffic matching nothing is
> denied anyway.

## Check it landed

```sh
kongctl get mesh inspect dataplane kv --control-plane-url "$KONG_MESH_CP"
```

```
PORT  KIND                   ORIGINS
main  MeshTrafficPermission  kri_mtp_default___allow-demo-app-to-kv_
```

That is the control plane's own view, per port, after matching — not a read-back of what you
applied. And from the other direction, the proxies a policy matches:

```sh
kongctl get mesh inspect meshtrafficpermission allow-demo-app-to-kv \
  --control-plane-url "$KONG_MESH_CP"
```

## Verify

The demo application can reach the key/value store again, because its identity is allowed:

```sh
curl http://127.0.0.1:25050/api/v1/items/hello
```

This still fails from your host, and should: `curl` presents no mesh identity, and the inbound
is `Strict`. Traffic between the two workloads is now encrypted and authorized; traffic from
outside is not admitted at all.

## Letting external traffic in

External traffic reaches a mesh through a gateway, and in
{{site.mesh_product_name}} 3 that means a **delegated** gateway: a gateway you run yourself, with
`kuma-dp` beside it, as an ordinary `Dataplane`.

The built-in gateway is removed. `MeshGateway`, `MeshGatewayRoute`, `MeshGatewayInstance` and
`MeshGatewayConfig` no longer exist — not as resources, not as CRDs, and `MeshGateway` is no
longer a valid `targetRef.kind` for any policy. The `kuma.io/gateway` marking is gone too.

What made a gateway special was that {{site.mesh_product_name}} did not proxy the traffic it
terminates, and that now comes from keeping its listen ports out of inbound redirection with the
`traffic.kuma.io/exclude-inbound-ports` annotation. Everything else about it is an ordinary
proxy: it gets a `Dataplane`, a token, an identity from the same `MeshIdentity`, and it is
allowed through `MeshTrafficPermission` like any other caller.

## Clean up

```sh
docker rm --force kong-mesh-demo-app kong-mesh-demo-kv kong-mesh-demo-control-plane
docker network rm kong-mesh-demo
rm -rf "$KONG_MESH_DEMO_TMP"
```
