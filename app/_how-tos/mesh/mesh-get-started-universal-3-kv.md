---
title: Add the key/value store to the mesh
description: "Run a Redis container with a kuma-dp sidecar, and watch the control plane generate its MeshService."
content_type: how_to
permalink: /mesh/get-started/universal/kv/
breadcrumbs:
  - /mesh/
products:
  - mesh
works_on:
  - on-prem
tags:
  - get-started
  - universal-mode
  - docker
series:
  id: mesh-get-started-universal-3
  position: 3
tldr:
  q: How do I add a Universal workload to the mesh?
  a: Issue a dataplane token, start the workload with `kuma-dp` beside it and a `Dataplane` resource describing its ports, and the control plane generates the `MeshService` from the `kuma.io/workload` label.
related_resources:
  - text: Deploy a Universal data plane proxy
    url: /mesh/universal-data-plane/
  - text: MeshService
    url: /mesh/meshservice/
---

The first workload is a Redis instance the demo app will read and write. Adding it shows the
whole Universal pattern: a token, a `Dataplane`, and a sidecar.

## Issue a dataplane token

A Universal proxy proves who it is with a dataplane token. Bind it to the name the proxy will
use rather than to the mesh:

```sh
kongctl create mesh dataplane-token \
  --control-plane-url "$KONG_MESH_CP" \
  --name kv \
  --valid-for 24h > "$KONG_MESH_DEMO_TMP/token-kv"
```

A token bound only to a mesh authenticates **any** proxy in it, which is why `--name` is worth
the keystrokes. `--workload` and `--tag` bind it differently where instance names vary.

## Start the container

```sh
docker run \
  --detach \
  --name kong-mesh-demo-kv \
  --hostname kv \
  --network kong-mesh-demo \
  --ip 172.18.78.2 \
  --volume "$KONG_MESH_DEMO_TMP:/demo" \
  --cap-add NET_ADMIN \
  redis:7 \
  redis-server --port 6379
```

`NET_ADMIN` is what lets `kuma-dp` install the transparent proxy rules inside the container.

## Start the sidecar

Run `kuma-dp` in the same container, pointing it at the template from
[step 1](/mesh/get-started/universal/install/):

```sh
docker exec --detach kong-mesh-demo-kv \
  kuma-dp run \
    --cp-address https://control-plane:5678 \
    --skip-verify \
    --dataplane-file /demo/dataplane.yaml \
    --dataplane-var name=kv \
    --dataplane-var address=172.18.78.2 \
    --dataplane-var port=6379 \
    --dataplane-token-file /demo/token-kv \
    --transparent-proxy \
    --transparent-proxy-config /demo/transparent-proxy.yaml
```

{:.warning}
> `--skip-verify` skips TLS verification of the control plane certificate. It is here because the
> demo control plane uses a self-signed certificate. Never use it outside a demo — give
> `kuma-dp` the CA with `--ca-cert-file` instead.

`--dataplane-file` applies the `Dataplane` as the proxy starts, so there is no separate step.
The three `--dataplane-var` flags fill the template's placeholders.

## Check that it connected

```sh
kongctl get mesh dataplanes --control-plane-url "$KONG_MESH_CP"
```

```
MESH     NAME  TAGS  ADDRESS      AGE
default  kv          172.18.78.2  10s
```

And that the control plane considers it online:

```sh
kongctl get mesh inspect dataplanes --control-plane-url "$KONG_MESH_CP"
```

```
MESH     NAME  STATUS
default  kv    Online
```

## The MeshService appears on its own

You wrote no `MeshService`, and one exists:

```sh
kongctl get mesh meshservices --control-plane-url "$KONG_MESH_CP"
```

```
MESH     NAME  AGE
default  kv    5s
```

The control plane generated it from the `kuma.io/workload: kv` label on the `Dataplane`, with
one port per inbound. It re-checks every two seconds, and removes a generated `MeshService` an
hour after its last proxy disappears.

That is the rule to carry forward: **on Universal you own the `Dataplane`; the `MeshService`
follows from its `kuma.io/workload` label.** A `Dataplane` without that label generates nothing,
and no policy or route can target the workload.

Look at what was generated:

```sh
kongctl get mesh meshservices kv -o yaml --control-plane-url "$KONG_MESH_CP"
```

The selector matches on the workload label, the port carries the `protocol` you set on the
inbound, and the status reports a VIP the demo app will reach it on.

## Next

[Set up the demo application](/mesh/get-started/universal/demo-app/).
