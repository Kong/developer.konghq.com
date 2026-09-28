---
title: Add the demo application
description: "Run a second Universal workload that reaches the key/value store by name, and see the policies that now apply to it."
content_type: how_to
permalink: /mesh/get-started/universal/demo-app/
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
  position: 4
tldr:
  q: How does one Universal workload reach another?
  a: With transparent proxying on, it dials the other workload's generated hostname and the sidecar routes it. Without it, declare an outbound with a `backendRef`.
related_resources:
  - text: Deploy a Universal data plane proxy
    url: /mesh/universal-data-plane/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
---

The second workload is an application that reads and writes the key/value store. Adding it is
the same three steps, and then the interesting part: how it finds `kv`.

## Issue a token and start the container

```sh
kongctl create mesh dataplane-token \
  --control-plane-url "$KONG_MESH_CP" \
  --name demo-app \
  --valid-for 24h > "$KONG_MESH_DEMO_TMP/token-demo-app"
```

```sh
docker run \
  --detach \
  --name kong-mesh-demo-app \
  --hostname demo-app \
  --network kong-mesh-demo \
  --ip 172.18.78.3 \
  --publish 25050:5050 \
  --volume "$KONG_MESH_DEMO_TMP:/demo" \
  --cap-add NET_ADMIN \
  --env KV_ADDRESS=kv.svc.mesh.local:6379 \
  kong/kuma-demo:latest
```

## Start the sidecar

```sh
docker exec --detach kong-mesh-demo-app \
  kuma-dp run \
    --cp-address https://control-plane:5678 \
    --skip-verify \
    --dataplane-file /demo/dataplane.yaml \
    --dataplane-var name=demo-app \
    --dataplane-var address=172.18.78.3 \
    --dataplane-var port=5050 \
    --dataplane-token-file /demo/token-demo-app \
    --transparent-proxy \
    --transparent-proxy-config /demo/transparent-proxy.yaml
```

## How it finds the key/value store

The application was told to reach `kv` at a hostname, not an address. Two pieces make that work,
and both came from the previous page:

- The control plane **generated a `MeshService`** named `kv` and allocated it a VIP and a
  hostname.
- `kuma-dp` is running with **transparent proxying and the embedded DNS proxy**, so the
  application's DNS lookups resolve mesh hostnames and its outbound traffic is intercepted.

Nothing in the `Dataplane` for `demo-app` mentions `kv`. That is what transparent proxying buys:
the workload dials a name and the sidecar does the rest.

### Without transparent proxying

Turn it off and the proxy no longer intercepts outbound traffic, so each destination needs an
explicit outbound that binds a local port:

```yaml
networking:
  address: 172.18.78.3
  inbound:
    - port: 5050
      name: main
      protocol: http
  outbound:
    - port: 6379
      backendRef:
        kind: MeshService
        name: kv
        port: 6379
```

The application then connects to `127.0.0.1:6379`. `backendRef` is required — an outbound
without one is rejected with `backendRef: must be defined` — and it takes either `name` or
`labels`, never both.

## Verify it works

```sh
curl -XPOST http://127.0.0.1:25050/api/v1/items \
  --header 'Content-Type: application/json' \
  --data '{"key":"hello","value":"mesh"}'

curl http://127.0.0.1:25050/api/v1/items/hello
```

Both workloads are now in the mesh:

```sh
kongctl get mesh inspect dataplanes --control-plane-url "$KONG_MESH_CP"
```

```
MESH     NAME      STATUS
default  demo-app  Online
default  kv        Online
```

## See what applies to a proxy

`inspect` answers what the control plane computed, per port, which is how you check a policy
landed where you meant it to:

```sh
kongctl get mesh inspect dataplane demo-app --control-plane-url "$KONG_MESH_CP"
```

Nothing is listed yet, because no policy targets these workloads. The next page changes that.

## Next

[Introduce zero-trust security](/mesh/get-started/universal/zero-trust-security/).
