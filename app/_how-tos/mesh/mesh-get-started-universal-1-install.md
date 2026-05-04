---
title: Install
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
edge-gateway(edge-gateway)
demo-app(demo-app :5050)
kv(kv :5050)
end
edge-gateway --> demo-app
demo-app --> kv
browser --> edge-gateway
{% endmermaid %}
<!-- vale on -->

1. **Install {{site.mesh_product_name}}**

   Run the installation command:

   ```sh
   curl -L https://developer.konghq.com/mesh/installer.sh | VERSION={{site.data.mesh_latest.version}} sh -
   ```

   Then add the binaries to your system's [PATH](https://en.wikipedia.org/wiki/PATH_(variable)). Replace `<version>` with the version shown by the installer:

   ```sh
   export PATH="$(pwd)/kong-mesh-{{site.data.mesh_latest.version}}/bin:$PATH"
   ```

   To confirm that {{site.mesh_product_name}} is installed correctly, run:

   ```sh
   kumactl version 2>/dev/null
   ```

   You should see output similar to:

   ```
   Client: {{site.mesh_product_name}} {{site.data.mesh_latest.version}}
   ```

2. **Prepare a temporary directory**

   Set up a temporary directory to store resources like data plane tokens, [Dataplane](/mesh/data-plane-proxy/) templates, and logs. Ensure the path does not end with a trailing `/`.

   {:.warning}
   > **Important:** If you are using **Colima**, make sure to adjust the path in the steps of this guide. Colima only allows shared paths from the `HOME` directory or `/tmp/colima/`. Instead of `/tmp/kong-mesh-demo`, you can use `/tmp/colima/kong-mesh-demo`.

   Check if the directory exists and is empty, and create it if necessary:

   ```sh
   export KONG_MESH_DEMO_TMP="/tmp/kong-mesh-demo"
   mkdir -p "$KONG_MESH_DEMO_TMP"
   ```

3. **Prepare a Dataplane resource template**

   Create a reusable [Dataplane](/mesh/data-plane-proxy/) resource template for services:

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

   This template simplifies creating Dataplane configurations for different services by replacing dynamic values during deployment.

4. **Prepare a transparent proxy configuration file**

   ```sh
   echo 'kumaDPUser: kong-mesh-data-plane-proxy
   redirect:
     dns:
       enabled: true
   verbose: true' > "$KONG_MESH_DEMO_TMP/config-transparent-proxy.yaml"
   ```

5. **Create a Docker network**

   Set up a separate Docker network for the containers. Use IP addresses in the `172.57.78.0/24` range or customize as needed:

   ```sh
   docker network create \
     --subnet 172.57.0.0/16 \
     --ip-range 172.57.78.0/24 \
     --gateway 172.57.78.254 \
     kong-mesh-demo
   ```
