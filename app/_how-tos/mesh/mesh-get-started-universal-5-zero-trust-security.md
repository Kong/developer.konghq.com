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
tools:
  - kongctl
tags:
  - get-started
  - universal-mode
  - security
series:
  id: mesh-get-started-universal-3
  position: 5
tldr:
  q: How do I turn on mTLS and restrict traffic in {{site.mesh_product_name}} 3.x?
  a: Create a `MeshIdentity` so workloads get certificates, which makes traffic default to deny, then allow specific callers with a `MeshTrafficPermission` matching on their SPIFFE ID.
related_resources:
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
  - text: MeshTLS
    url: /mesh/policies/meshtls/
  - text: Application ingress
    url: /mesh/application-ingress/
cleanup:
  inline:
    - title: Remove the demo containers and network
      content: |
        Remove the demo containers:

        ```sh
        docker rm --force kong-mesh-demo-app kong-mesh-demo-kv kong-mesh-demo-control-plane
        ```

        Remove the Docker network:

        ```sh
        docker network rm kong-mesh-demo
        ```

        Remove the working directory:

        ```sh
        rm -rf "$KONG_MESH_DEMO_TMP"
        ```
min_version:
  mesh: '3.0'
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
cat <<'EOF' | kongctl create mesh -f - \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
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
the control plane generates itself, which suits a demo and nothing else: a real mesh supplies a
CA under `bundled.ca`.

Setting `trustDomain` explicitly keeps the SPIFFE IDs predictable. Left out, it renders from
`{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}`.

From now on, each proxy's identity comes from its `kuma.io/workload` label, so the control plane
accepts only dataplane tokens bound to that workload. You issued the tokens in steps 3 and 4
with `--workload`, so `kv` and `demo-app` keep reconnecting. The control plane would reject a proxy with a token bound only by
`--name` the next time it connected.

Check that the identity initialized:

```sh
kongctl get mesh meshidentities demo-identity -o yaml \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

`status.conditions` should report `Provider`, `MeshTrustCreated` and `Ready` as true, and
`status.trustDomain` shows the domain issuance is pinned to. The control plane also created a `MeshTrust` that publishes the CA
bundle:

```sh
kongctl get mesh meshtrusts \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

## Confirm that traffic is denied

Try the demo application again:

```sh
curl -XPOST http://127.0.0.1:25050/api/counter
```

It fails. Two things changed at once:

- Proxies now have identities, so `MeshTrafficPermission` applies, and no permission exists,
  so nothing is allowed. {{site.mesh_product_name}} 3.x creates no default allow-all permission.
- Inbounds are `Strict` unless a [MeshTLS](/mesh/policies/meshtls/) policy says otherwise, so
  the proxies reject plaintext from outside the mesh. `curl` on your host is outside the mesh.

That is zero trust arriving: nothing is permitted until you say so.

## Allow the demo app to reach the key/value store

A permission names the caller by the identity it presents, not by a tag it sets:

```sh
cat <<'EOF' | kongctl create mesh -f - \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
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

The SPIFFE ID follows from the `kuma.io/workload` label on the `demo-app` `Dataplane` you wrote in
[step 4](/mesh/get-started/universal/demo-app/): on Universal the path
defaults to `/workload/{workload}`, so `demo-app` becomes
`spiffe://default.mesh.local/workload/demo-app`.

{:.warning}
> In 2.x the documented idiom was a mesh-wide `Deny` followed by narrower `Allow` rules, because
> the last matching rule won. Precedence is now fixed: every `deny` is evaluated before every
> `allow`, so a deny-all can never be re-opened. Write the allows; traffic matching nothing is
> denied anyway.

## Inspect the applied policy

```sh
kongctl get mesh inspect dataplane kv \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

```text
PORT  KIND                   ORIGINS
main  MeshTrafficPermission  kri_mtp_default___allow-demo-app-to-kv_
```
{:.no-copy-code}

That is the control plane's own view, per port, after matching, not a read-back of what you
applied. And from the other direction, the proxies a policy matches:

```sh
kongctl get mesh inspect meshtrafficpermission allow-demo-app-to-kv \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

To let traffic from outside the mesh reach the demo application, see
[Application ingress](/mesh/application-ingress/).

## Validate

Send the request from inside the demo application's container, so the application calls the
key/value store through its sidecar:

```sh
docker exec kong-mesh-demo-app curl -s -XPOST http://127.0.0.1:5050/api/counter
```

The response returns the incremented counter and the `local-demo-zone` zone name, for example
`{"counter":2,"zone":"local-demo-zone"}`. The application reached `kv` over mTLS, and the `kv`
proxy admitted it because `demo-app`'s SPIFFE ID is allowed.

The same request from your host, `curl -XPOST http://127.0.0.1:25050/api/counter`, still fails:
`curl` presents no mesh identity, and the inbound is `Strict`. Traffic between the two workloads
is encrypted and authorized; traffic from outside isn't admitted at all.
