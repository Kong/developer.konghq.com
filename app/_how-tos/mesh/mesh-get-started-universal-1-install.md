---
title: Install {{site.mesh_product_name}}
description: "Install the {{site.mesh_product_name}} binaries and kongctl, and prepare the network and files the rest of the series uses."
content_type: how_to
permalink: /mesh/get-started/universal/install/
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
  position: 1
tldr:
  q: What do I need before running {{site.mesh_product_name}} on Universal?
  a: Install the {{site.mesh_product_name}} binaries and `kongctl`, create a Docker network the containers share, and write the `Dataplane` template and transparent proxy config the later steps reuse.
related_resources:
  - text: "{{site.mesh_product_name}} on Universal"
    url: /mesh/universal/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
---

This series runs {{site.mesh_product_name}} on Universal from nothing to a two-service mesh with
mTLS and a gateway, entirely in containers on one machine. Each step builds on the last.

Universal here means what it means in production: there is no Kubernetes API server to derive
anything from, so you declare each proxy yourself. Where Kubernetes would infer ports, protocols
and identity from a Pod and a Service, you supply them.

## What you need

- A container runtime that can run Linux containers and give them addresses on a user-defined
  network.
- `curl`.

## Install the binaries

{{site.mesh_product_name}} ships `kuma-cp` (the control plane), `kuma-dp` (the sidecar), and
`envoy`. Install them on the host:

```sh
curl -L https://developer.konghq.com/mesh/installer.sh | VERSION={{page.latest_release.version}} sh -
```

```sh
sudo mv kong-mesh-*/bin/* /usr/local/bin/
```

## Install kongctl

`kongctl` is the CLI for {{site.mesh_product_name}} 3, and replaces `kumactl`. Install it and
confirm it runs:

```sh
kongctl version
```

See [{{site.mesh_product_name}} CLI](/mesh/cli/) for the full command surface.

## Create a working directory

The series writes tokens and resources to a directory the containers share:

```sh
export KONG_MESH_DEMO_TMP="$(mktemp -d)"
echo "$KONG_MESH_DEMO_TMP"
```

Keep that variable set; every later step uses it.

## Create the Docker network

The control plane and the two workloads need to reach each other by address:

```sh
docker network create \
  --subnet 172.18.78.0/24 \
  kong-mesh-demo
```

## Write the Dataplane template

On Universal a proxy is described by a `Dataplane` resource. Rather than writing one per
workload by hand, write a template the later steps fill in:

{% raw %}
```sh
cat > "$KONG_MESH_DEMO_TMP/dataplane.yaml" <<'EOF'
type: Dataplane
mesh: default
name: {{ name }}
labels:
  kuma.io/workload: {{ name }}
  app: {{ name }}
networking:
  address: {{ address }}
  inbound:
    - port: {{ port }}
      name: main
      protocol: http
EOF
```
{% endraw %}

`kuma-dp` substitutes each placeholder from a matching `--dataplane-var` flag, so one file serves
every workload in the series.

Three things in that file are worth understanding now, because they are the whole of what
Universal asks of you:

{% table %}
columns:
  - title: Field
    key: field
  - title: Why it is there
    key: why
rows:
  - field: "`labels.kuma.io/workload`"
    why: "Names the workload. The control plane generates a `MeshService` per distinct value, and the proxy's SPIFFE ID is built from it. Without it, nothing is generated and no policy can target the workload."
  - field: "`labels.app`"
    why: "An ordinary label. This is what policies select on, now that inbounds carry no tags."
  - field: "`networking.inbound[].protocol`"
    why: "Sets the port's protocol. Leave it out and the port is treated as TCP, silently losing every L7 policy."
{% endtable %}

## Write the transparent proxy config

Transparent proxying lets a workload call other services by name without declaring an outbound
for each one:

```sh
cat > "$KONG_MESH_DEMO_TMP/transparent-proxy.yaml" <<'EOF'
redirect:
  dns:
    enabled: true
EOF
```

`kuma-dp` installs the iptables rules from this file when it starts with
`--transparent-proxy-config`.

## Next

[Set up the control plane](/mesh/get-started/universal/control-plane/).
