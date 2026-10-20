---
title: Install {{site.mesh_product_name}}
description: "Prepare the network, the sidecar setup script, and the files the rest of the series uses."
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
  a: Create a Docker network the containers share, and write the sidecar setup script, the `Dataplane` template and the transparent proxy config the later steps reuse.
related_resources:
  - text: "{{site.mesh_product_name}} on Universal"
    url: /mesh/universal/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
tools:
  - kongctl
prereqs:
  inline:
    - title: Docker
      content: |
        This series runs every component as a container with [Docker](https://docs.docker.com/get-docker/).
        Docker must be able to run Linux containers and give them addresses on a user-defined network.
    - title: curl
      content: |
        Used to call the demo application from your machine.
min_version:
  mesh: '3.0'
---

This series runs {{site.mesh_product_name}} on Universal from nothing to a two-service mesh with
mTLS and traffic permissions, entirely in containers on one machine. Each step builds on the last.

The application is the [Kuma counter demo](https://github.com/kumahq/kuma-counter-demo), run as
two services from the same image:

- `demo-app`: a web application that increments a counter.
- `kv`: a key/value store that keeps the counter's value.

Universal here means what it means in production: there is no Kubernetes API server to derive
anything from, so you declare each proxy yourself. Where Kubernetes would infer ports, protocols
and identity from a Pod and a Service, you supply them.

## Create a working directory

The series writes tokens, resources and logs to a directory the containers share:

```sh
export KONG_MESH_DEMO_TMP="$(mktemp -d)"
chmod 755 "$KONG_MESH_DEMO_TMP"
echo "$KONG_MESH_DEMO_TMP"
```

`chmod` lets the unprivileged user that runs `kuma-dp` inside each container read the files.
Keep that variable set; every later step uses it.

## Create the Docker network

The control plane and the two workloads need to reach each other by address:

```sh
docker network create \
  --subnet 172.18.78.0/24 \
  --gateway 172.18.78.254 \
  kong-mesh-demo
```

`--gateway` moves the network's gateway to `172.18.78.254`. Without it, Docker takes
`172.18.78.1`, the address the control plane runs on.

## Write the sidecar setup script

On Universal the sidecar runs beside the workload, so each workload container needs the
{{site.mesh_product_name}} binaries: `kuma-dp` (the sidecar), `envoy`, and `kumactl`, which
installs the transparent proxy's iptables rules. Write a script the later steps run inside each
container:

```sh
cat > "$KONG_MESH_DEMO_TMP/setup-sidecar.sh" <<'EOF'
set -e
apt-get update
apt-get install --yes curl iptables
cd /tmp
curl -L https://developer.konghq.com/mesh/installer.sh | VERSION={{page.latest_release.version}} sh -
mv kong-mesh-*/bin/* /usr/local/bin/
useradd --uid 5678 --user-group kuma-dp
EOF
```

The script installs `curl` and `iptables`, downloads the Linux binaries for the container's
architecture, and creates the `kuma-dp` user (UID `5678`) that the sidecar runs as. The
transparent proxy redirects every process's traffic to the sidecar except this user's.

The series manages resources from your machine with `kongctl`. See
[{{site.mesh_product_name}} CLI](/mesh/cli/) for the full command surface.

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

`kuma-dp` substitutes each placeholder from a matching `--dataplane-var` flag, so one file can
serve many workloads.

Three things in that file are worth understanding now, because they are most of what Universal
asks of you:

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
    why: "Sets the port's protocol. Both demo workloads serve HTTP. Leave it out and the port is treated as TCP, silently losing every L7 policy."
{% endtable %}

The template declares no destinations, which suits `kv`: it calls nothing. A transparent proxy
reaches only the destinations listed in its `Dataplane`, so the demo app, which calls `kv`, gets
its own `Dataplane` with that list in [step 4](/mesh/get-started/universal/demo-app/).

## Write the transparent proxy config

Transparent proxying intercepts a workload's traffic, so the workload calls other services by
name without binding a local port for each one:

```sh
cat > "$KONG_MESH_DEMO_TMP/transparent-proxy.yaml" <<'EOF'
kumaDPUser: kuma-dp
redirect:
  dns:
    enabled: true
EOF
```

`kumactl install transparent-proxy --config-file` reads this file when it installs the iptables
rules inside each container. `kumaDPUser` names the user whose traffic isn't redirected, and
`redirect.dns.enabled` sends DNS lookups to the sidecar's DNS proxy so mesh hostnames resolve.
`kuma-dp` gets the same file with `--transparent-proxy-config`, which tells the control plane
how the rules are set up.
