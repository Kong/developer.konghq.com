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
tools:
  - kongctl
tags:
  - get-started
  - universal-mode
  - docker
series:
  id: mesh-get-started-universal-3
  position: 4
tldr:
  q: How does one Universal workload reach another?
  a: With transparent proxying on, list the destination in the caller's `reachableBackends`, and the caller dials its generated hostname while the sidecar routes it. Without transparent proxying, declare an outbound with a `backendRef`.
related_resources:
  - text: Universal data plane
    url: /mesh/universal-data-plane/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
min_version:
  mesh: '3.0'
---

The second workload is the demo application, which reads and writes the key/value store. Adding
it is the same steps, plus the interesting part: how it finds `kv`.

## Issue a token and start the container

```sh
kongctl create mesh dataplane-token \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN" \
  --name demo-app \
  --workload demo-app \
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
  --env KV_URL=http://kv.svc.mesh.local:5050 \
  --env APP_VERSION=v1 \
  ghcr.io/kumahq/kuma-counter-demo:debian-slim
```

`KV_URL` tells the application to reach the store at `kv.svc.mesh.local`, the hostname the
control plane generated for the `kv` `MeshService`.

## Install the sidecar binaries and the transparent proxy

```sh
docker exec kong-mesh-demo-app sh /demo/setup-sidecar.sh
```

```sh
docker exec --privileged kong-mesh-demo-app \
  kumactl install transparent-proxy \
    --config-file /demo/transparent-proxy.yaml
```

## Write the demo app's Dataplane

The template from [step 1](/mesh/get-started/universal/install/) declares no destinations, and a
transparent proxy reaches only what its `Dataplane` lists in `reachableBackends`. With none
listed, the proxy reaches nothing. So `demo-app` gets its own `Dataplane`, which names `kv`:

```sh
cat > "$KONG_MESH_DEMO_TMP/dataplane-demo-app.yaml" <<'EOF'
type: Dataplane
mesh: default
name: demo-app
labels:
  kuma.io/workload: demo-app
  app: demo-app
networking:
  address: 172.18.78.3
  inbound:
    - port: 5050
      name: main
      protocol: http
  transparentProxying:
    reachableBackends:
      refs:
        - kind: MeshService
          labels:
            kuma.io/display-name: kv
EOF
```

Each ref selects destinations by `kind` and `labels`. `kuma.io/display-name` is the label the
control plane puts on a generated `MeshService` with its name.

## Start the sidecar

```sh
docker exec --detach kong-mesh-demo-app sh -c '
  runuser -u kuma-dp -- kuma-dp run \
    --cp-address https://control-plane:5678 \
    --skip-verify \
    --dataplane-file /demo/dataplane-demo-app.yaml \
    --dataplane-token-file /demo/token-demo-app \
    --transparent-proxy-config /demo/transparent-proxy.yaml \
    > /demo/logs-demo-app.log 2>&1'
```

## Understand service discovery

You told the application to reach `kv` at a hostname, not an address. Three pieces make that
work:

- The control plane **generated a `MeshService`** named `kv` on the previous page, and allocated
  it a VIP and the `kv.svc.mesh.local` hostname.
- The `demo-app` `Dataplane` **lists `kv` in `reachableBackends`**, so the control plane
  configures the proxy with an outbound for it.
- `kuma-dp` is running with **transparent proxying and the embedded DNS proxy**, so the
  application's DNS lookups resolve mesh hostnames and the sidecar intercepts its outbound traffic.

The application code doesn't change: it dials a name and the sidecar does the rest. What
Universal asks of you is the `reachableBackends` list. The control plane can drop that
requirement mesh-wide with `KUMA_DEFAULTS_RESTRICT_OUTBOUND=false`, at the cost of configuring
every proxy for every destination.

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
    - port: 10001
      backendRef:
        kind: MeshService
        name: kv
        port: 5050
```

The application then connects to `127.0.0.1:10001`. `backendRef` is required: an outbound
without one is rejected with `backendRef: must be defined`. It needs `name` or `labels`.

## Verify it works

Increment the counter through the published port:

```sh
curl -XPOST http://127.0.0.1:25050/api/counter
```

The response looks like this:

```json
{"counter":1,"zone":"local-demo-zone"}
```
{:.no-copy-code}

The application stored the counter in `kv` and read back the zone name you set on the previous
page. You can also open <http://127.0.0.1:25050> in a browser and increment the counter there.

Both workloads are now in the mesh:

```sh
kongctl get mesh inspect dataplanes \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

```text
MESH     NAME      STATUS
default  demo-app  Online
default  kv        Online
```
{:.no-copy-code}

## See what applies to a proxy

`inspect` answers what the control plane computed, per port, which is how you check a policy
landed where you meant it to:

```sh
kongctl get mesh inspect dataplane demo-app \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

Nothing is listed yet, because no policy targets these workloads. The next page changes that.
