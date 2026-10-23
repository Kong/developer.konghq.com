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
  - text: Universal control plane
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
  --volume "$KONG_MESH_DEMO_DIR:/demo" \
  kong/kuma-cp:{{page.latest_release.version}} run
```

The control plane defaults to `mode: zone` with an in-memory store, which is what a single-node
demo wants. In a real deployment, use PostgreSQL. For more information, see
[Universal control plane](/mesh/universal-control-plane/).

Two ports are important:
* 5681, which serves the HTTP API and the GUI. This is what `kongctl` uses.
* 5678, which serves the data plane server where proxies connect.

You can reach the GUI at <http://127.0.0.1:25681/gui>.

## Get the admin token

The {{site.mesh_product_name}} API enforces RBAC. It treats only requests from the control plane's own
host as admin, and requests through the published port come from outside the
container.

This means `kongctl` needs a token. The control plane creates an admin token at startup and
stores it as the `admin-user-token` global secret. Fetch it from inside the container:

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

## Point kongctl at the control plane

`kongctl` reaches a self-managed control plane through `--control-plane-url`, and authenticates
with `--control-plane-token`. 

1. Export the control plane URL:

   ```sh
   export KONG_MESH_CP=http://127.0.0.1:25681
   ```

1. Pass both flags to list the control plane's resource types:

   ```sh
   kongctl get mesh resource-types \
     --control-plane-url "$KONG_MESH_CP" \
     --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
   ```

   The command lists every resource type this control plane serves.

## Confirm the default mesh

Check that the control plane includes the `default` mesh:

```sh
kongctl get mesh meshes \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```
