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
min_version:
  mesh: '3.0'
---

This series runs {{site.mesh_product_name}} on Universal and configures a two-service mesh with
mTLS and traffic permissions.

The application is the [Kuma counter demo](https://github.com/kumahq/kuma-counter-demo), run as
two services from the same image:

- `demo-app`: a web application that increments a counter.
- `kv`: a key/value store that keeps the counter's value.

For more information Universal, see [{{site.mesh_product_name}} on Universal](/mesh/universal/)

## Create a working directory

The series writes tokens, resources and logs to a directory the containers share:

```sh
export KONG_MESH_DEMO_TMP="$(mktemp -d)"
chmod 755 "$KONG_MESH_DEMO_TMP"
echo "$KONG_MESH_DEMO_TMP"
```

`chmod` lets the unprivileged user that runs `kuma-dp` inside each container read the files.

## Create the Docker network

Create a Docker network to allow the control plane and the two workloads to reach each other by address:

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
{{site.mesh_product_name}} binaries: `kuma-dp`, `envoy`, and `kumactl`.

Write the script that later steps will run inside each container:

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

The script performs the following actions:
* Installs `curl` and `iptables`
* Downloads the Linux binaries for the container's architecture
* Creates the `kuma-dp` user (UID `5678`) that the sidecar runs as

## Write the Dataplane template

The `Dataplane` resource describes a proxy. Rather than writing one per workload, write a template:

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

In this template: 
* `labels.kuma.io/workload` names the workload. The control plane generates a `MeshService` per distinct value, and builds the proxy's SPIFFE ID from it. Without it, nothing is generated and no policy can target the workload.
* `labels.app` is used by policies to select the proxy.
* `networking.inbound[].protocol` sets the port's protocol. Without it, the port is treated as TCP.

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
`kumaDPUser` names the user whose traffic isn't redirected, and
`redirect.dns.enabled` sends DNS lookups to the sidecar's DNS proxy so mesh hostnames resolve.
