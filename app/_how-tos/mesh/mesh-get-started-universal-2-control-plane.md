---
title: Set up the {{site.mesh_product_name}} control plane
description: "Run the {{site.mesh_product_name}} control plane in Universal mode as a container, and point kongctl at it."
content_type: how_to
permalink: /mesh/get-started/universal/control-plane/
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
  - docker
series:
  id: mesh-get-started-universal-3
  position: 2
tldr:
  q: How do I start the {{site.mesh_product_name}} control plane in Universal mode?
  a: Run `kuma-cp` as a container in `zone` mode, read its admin token, then point `kongctl` at its API with `--control-plane-url` and `--control-plane-token`.
related_resources:
  - text: Deploy a Universal control plane
    url: /mesh/universal-control-plane/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
min_version:
  mesh: '3.0'
---

## Start the control plane

Run `kuma-cp` on the network you created, publishing its API port to the host:

```sh
docker run \
  --detach \
  --name kong-mesh-demo-control-plane \
  --hostname control-plane \
  --network kong-mesh-demo \
  --ip 172.18.78.1 \
  --publish 25681:5681 \
  --volume "$KONG_MESH_DEMO_TMP:/demo" \
  kong/kuma-cp:{{page.latest_release.version}} run
```

The control plane defaults to `mode: zone` with an in-memory store, which is what a single-node
demo wants. Everything is lost when the container stops; see
[Deploy a Universal control plane](/mesh/universal-control-plane/) for the PostgreSQL
configuration a real deployment needs.

Two ports matter:

{% table %}
columns:
  - title: Port
    key: port
  - title: Serves
    key: serves
rows:
  - port: "5681"
    serves: "The HTTP API and the GUI. `kongctl` talks to this one."
  - port: "5678"
    serves: "The data plane server. Proxies connect here."
{% endtable %}

The GUI is now at <http://127.0.0.1:25681/gui>.

## Get the admin token

The {{site.mesh_product_name}} API enforces RBAC. Only requests from the control plane's own
host are treated as admin, and requests through the published port come from outside the
container, so `kongctl` needs a token. The control plane creates an admin token at startup and
stores it as the `admin-user-token` global secret. Read it from inside the container, where the
request comes from localhost:

```sh
export KONG_MESH_ADMIN_TOKEN="$(
  docker exec kong-mesh-demo-control-plane \
    wget --quiet --output-document - \
    http://127.0.0.1:5681/global-secrets/admin-user-token \
    | sed -n 's/.*"data": *"\([^"]*\)".*/\1/p' \
    | base64 --decode
)"
```

`sed` extracts the secret's base64-encoded `data` field, which `base64` decodes into the token.
If `KONG_MESH_ADMIN_TOKEN` is empty, the control plane is still starting: wait a few seconds and
run the command again.

## Point kongctl at it

`kongctl` reaches a self-managed control plane through `--control-plane-url`, and authenticates
with `--control-plane-token`:

```sh
export KONG_MESH_CP=http://127.0.0.1:25681
kongctl get mesh resource-types \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

That lists every resource type this control plane serves. It is worth a look before going
further: `kongctl` reads the list from the control plane rather than carrying its own, so this
is the authoritative answer for the version you are running.

To avoid repeating the flag, put it in `kongctl`'s config file, which lives at
`$XDG_CONFIG_HOME/kongctl/config.yaml` and is keyed by profile:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/kongctl"
cat >> "${XDG_CONFIG_HOME:-$HOME/.config}/kongctl/config.yaml" <<EOF
demo:
    output: text
    konnect:
        mesh:
            control-plane:
                url: $KONG_MESH_CP
            mesh: default
EOF
```

Then select that profile per command:

```sh
kongctl get mesh resource-types --profile demo --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

The rest of this series writes `--control-plane-url "$KONG_MESH_CP"` and
`--control-plane-token "$KONG_MESH_ADMIN_TOKEN"` explicitly, so it works either way.

## Confirm the default mesh

A control plane starts with a `default` mesh:

```sh
kongctl get mesh meshes \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

```text
NAME     DATAPLANES
default  0/0 online
```
{:.no-copy-code}

No proxies yet. The next two pages add them.

## Review what isn't running yet

Nothing issues identities. `Mesh.mtls` was removed in 3.0, so a mesh gets mTLS from a
[MeshIdentity](/mesh/policies/meshidentity/) or not at all. Without one, proxies serve and
accept plaintext, and `MeshTLS` and `MeshTrafficPermission` do not apply to them.

That is deliberate for now: the first two workloads connect without mTLS so you can see traffic
flowing, and
[the last page](/mesh/get-started/universal/zero-trust-security/) turns it on.
