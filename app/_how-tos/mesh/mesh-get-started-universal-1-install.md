---
title: Install {{site.mesh_product_name}}
description: "Install {{site.mesh_product_name}}, prepare working directories and configuration files, and create a Docker network for the Universal mode demo."
content_type: how_to
permalink: /mesh/get-started/universal/install/
breadcrumbs:
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}} data plane on Universal"
    url: /mesh/data-plane-universal/
  - text: Zone egress
    url: /mesh/zone-egress/
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/
  - text: '{{site.mesh_product_name}} resource sizing guidelines'
    url: '/mesh/resource-sizing-guidelines/'
  - text: '{{site.mesh_product_name}} version compatibility'
    url: '/mesh/version-compatibility/'
  - text: Mesh on Amazon ECS
    url: '/mesh/ecs/'
products:
  - mesh
works_on:
  - on-prem
tags:
  - get-started
  - universal-mode
  - docker
min_version:
  mesh: '2.10'
series:
  id: mesh-get-started-universal
  position: 1

prereqs:
  skip_product: true
  inline: 
    - title: Docker 
      content: |
        This guide requires [Docker](https://docs.docker.com/get-started/get-docker/) installed on your system.
    - title: jq
      content: |
        This guide requires [jq](https://jqlang.org/download/) installed on your system.

tldr:
  q: How do I prepare my environment to run {{site.mesh_product_name}} on Universal?
  a: Install the {{site.mesh_product_name}} binaries, create a temporary directory for tokens and configuration files, and set up a Docker network for the demo containers.
---

This series walks you through running {{site.mesh_product_name}} in Universal mode using Docker containers. You'll set up and secure a simple demo application to explore how {{site.mesh_product_name}} works. The application consists of two services:

- `demo-app`: A web application that lets you increment a numeric counter.
- `kv`: A data store that keeps the counter's value.

<!-- vale off -->
{% mermaid %}
flowchart LR
browser(browser)

subgraph mesh
edge-gateway
demo-app(demo-app :5050)
kv(kv :5050)
end
edge-gateway --> demo-app
demo-app --> kv
browser --> edge-gateway
{% endmermaid %}
<!-- vale on -->

## Install {{site.mesh_product_name}}

1. Run the following command to install the {{site.mesh_product_name}} binaries:

   ```sh
   curl -L https://developer.konghq.com/mesh/installer.sh | VERSION={{site.data.mesh_latest.version}} sh -
   ```

1. Add the binaries to your system's path:

   ```sh
   export PATH="$(pwd)/kong-mesh-{{site.data.mesh_latest.version}}/bin:$PATH"
   ```

1. Run the following command to confirm that {{site.mesh_product_name}} is installed correctly:

   ```sh
   kumactl version 2>/dev/null
   ```

   You should see the following output:

   ```
   Client: {{site.mesh_product_name}} {{site.data.mesh_latest.version}}
   ```
   {:.no-copy-code}

## Create a temporary directory

Set up a temporary directory to store resources like data plane tokens, [`Dataplane`](/mesh/data-plane-proxy/) templates, and logs. Ensure the path does not end with a trailing `/`.

{:.warning}
> If you are using [Colima](https://colima.run/), make sure to adjust the path in the steps of this guide. Colima only allows shared paths from the `HOME` directory or `/tmp/colima/`. Instead of `/tmp/kong-mesh-demo`, you can use `/tmp/colima/kong-mesh-demo`.

Create the directory if it doesn't exist:

```sh
export KONG_MESH_DEMO_TMP="/tmp/kong-mesh-demo"
mkdir -p "$KONG_MESH_DEMO_TMP"
```

## Create a `Dataplane` resource template

Create a reusable [`Dataplane`](/mesh/data-plane-proxy/) resource template for services:

```sh
echo 'type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
labels:
  app: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
    - port: {% raw %}{{ port }}{% endraw %}
      tags:
        kuma.io/service: {% raw %}{{ name }}{% endraw %}
        kuma.io/protocol: http
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001' > "$KONG_MESH_DEMO_TMP/dataplane.yaml"
```

This template simplifies creating `Dataplane` configurations for different services by replacing dynamic values during deployment.

## Create a transparent proxy configuration file

Create a configuration file that identifies the data plane proxy user and enables DNS traffic redirection through the mesh:

```sh
echo 'kumaDPUser: kong-mesh-data-plane-proxy
redirect:
  dns:
    enabled: true
verbose: true' > "$KONG_MESH_DEMO_TMP/config-transparent-proxy.yaml"
```

## Create a Docker network

Set up a separate Docker network for the containers. In this example we'll use IP addresses in the `172.18.78.0/24` range:

```sh
docker network create \
  --subnet 172.18.0.0/16 \
  --ip-range 172.18.78.0/24 \
  --gateway 172.18.78.254 \
  kong-mesh-demo
```
