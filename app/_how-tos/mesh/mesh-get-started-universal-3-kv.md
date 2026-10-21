---
title: Add the key/value store to the mesh
description: "Run the key/value store with a kuma-dp sidecar and the transparent proxy, and watch the control plane generate its MeshService."
content_type: how_to
permalink: /mesh/get-started/universal/kv/
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
  position: 3
tldr:
  q: How do I add a Universal workload to the mesh?
  a: Issue a workload-bound dataplane token, install the transparent proxy, and start `kuma-dp` beside the workload with a `Dataplane` resource describing its ports. The control plane generates the `MeshService` from the `kuma.io/workload` label.
related_resources:
  - text: Universal data plane
    url: /mesh/universal-data-plane/
  - text: MeshService
    url: /mesh/meshservice/
min_version:
  mesh: '3.0'
---

The first workload is the key/value store the demo app will read and write. Adding it shows the
whole Universal pattern: a token, the transparent proxy, a `Dataplane`, and a sidecar.

## Issue a dataplane token

A Universal proxy proves who it is with a dataplane token. Bind it to the proxy's name and to
its workload:

```sh
kongctl create mesh dataplane-token \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN" \
  --name kv \
  --workload kv \
  --valid-for 24h > "$KONG_MESH_DEMO_TMP/token-kv"
```

`--workload` matters later: once [step 5](/mesh/get-started/universal/zero-trust-security/)
creates a `MeshIdentity`, the proxy's identity comes from its `kuma.io/workload` label, and the
control plane rejects a token that isn't bound to that workload the next time the proxy
connects.

## Start the container

```sh
docker run \
  --detach \
  --name kong-mesh-demo-kv \
  --hostname kv \
  --network kong-mesh-demo \
  --ip 172.18.78.2 \
  --volume "$KONG_MESH_DEMO_TMP:/demo" \
  ghcr.io/kumahq/kuma-counter-demo:debian-slim
```

Check that the store is listening on port `5050`:

```sh
docker logs kong-mesh-demo-kv
```

```text
time=2025-03-14T12:17:34.630Z level=INFO ... msg="server running" addr=:5050
```
{:.no-copy-code}

## Install the sidecar binaries

Run the setup script from [step 1](/mesh/get-started/universal/install/) inside the container:

```sh
docker exec kong-mesh-demo-kv sh /demo/setup-sidecar.sh
```

## Set the zone name

The demo app reads a `zone` key from the store and fails without it. Set it:

```sh
docker exec kong-mesh-demo-kv \
  curl -s localhost:5050/api/key-value/zone \
    --header 'Content-Type: application/json' \
    --data '{"value":"local-demo-zone"}'
```

```json
{"value":"local-demo-zone"}
```
{:.no-copy-code}

## Install the transparent proxy

`kumactl install transparent-proxy` writes the iptables rules that redirect the container's
traffic through the sidecar. It needs root and the `NET_ADMIN` capability, which
`docker exec --privileged` provides:

```sh
docker exec --privileged kong-mesh-demo-kv \
  kumactl install transparent-proxy \
    --config-file /demo/transparent-proxy.yaml
```

The last line of the output is:

```text
# transparent proxy setup completed successfully
```
{:.no-copy-code}

{:.danger}
> Run this command only inside the container. It redirects all of the host's traffic to a data
> plane proxy, so running it on your own machine or a VM without one can cut off its network
> access.

## Start the sidecar

Run `kuma-dp` in the same container, as the `kuma-dp` user the iptables rules exclude, pointing
it at the template from [step 1](/mesh/get-started/universal/install/):

```sh
docker exec --detach kong-mesh-demo-kv sh -c '
  runuser -u kuma-dp -- kuma-dp run \
    --cp-address https://control-plane:5678 \
    --skip-verify \
    --dataplane-file /demo/dataplane.yaml \
    --dataplane-var name=kv \
    --dataplane-var address=172.18.78.2 \
    --dataplane-var port=5050 \
    --dataplane-token-file /demo/token-kv \
    --transparent-proxy-config /demo/transparent-proxy.yaml \
    > /demo/logs-kv.log 2>&1'
```

{:.warning}
> `--skip-verify` skips TLS verification of the control plane certificate. It is here because the
> demo control plane uses a self-signed certificate. Never use it outside a demo; give
> `kuma-dp` the CA with `--ca-cert-file` instead.

`--dataplane-file` applies the `Dataplane` as the proxy starts, so there is no separate step.
The three `--dataplane-var` flags fill the template's placeholders. `--transparent-proxy-config`
turns on transparent proxying for this proxy and tells the control plane how the rules are set
up. The sidecar's output goes to `$KONG_MESH_DEMO_TMP/logs-kv.log`.

## Check that it connected

```sh
kongctl get mesh dataplanes \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

```text
MESH     NAME  TAGS  ADDRESS      AGE
default  kv          172.18.78.2  10s
```
{:.no-copy-code}

And that the control plane considers it online:

```sh
kongctl get mesh inspect dataplanes \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

```text
MESH     NAME  STATUS
default  kv    Online
```
{:.no-copy-code}

If `kv` doesn't appear, check `$KONG_MESH_DEMO_TMP/logs-kv.log` for the reason.

## Inspect the generated MeshService

You wrote no `MeshService`, and one exists:

```sh
kongctl get mesh meshservices \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

```text
MESH     NAME  AGE
default  kv    5s
```
{:.no-copy-code}

The control plane generated it from the `kuma.io/workload: kv` label on the `Dataplane`, with
one port per inbound. It re-checks every two seconds, and removes a generated `MeshService` an
hour after its last proxy disappears.

That is the rule to carry forward: **on Universal you own the `Dataplane`; the `MeshService`
follows from its `kuma.io/workload` label.** A `Dataplane` without that label generates nothing,
and no policy or route can target the workload.

Look at what was generated:

```sh
kongctl get mesh meshservices kv -o yaml \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
```

The selector matches on the workload label, the port carries the `protocol` you set on the
inbound, and the status reports the VIP and the `kv.svc.mesh.local` hostname the demo app will
reach it on.
