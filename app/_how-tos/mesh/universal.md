---
title: 'Deploy {{site.mesh_product_name}} on Universal'
description: 'Guide to deploying {{site.mesh_product_name}} in Universal mode using Docker containers. Walks through installing the Control Plane, adding demo services, enabling mTLS, and configuring gateways.'
content_type: how_to
permalink: /mesh/universal/
bread-crumbs:
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
tags:
  - get-started
  - universal-mode
  - docker
min_version:
  mesh: '2.9'
---

This quick start guide demonstrates how to run {{site.mesh_product_name}} in Universal mode using Docker containers.

You'll set up and secure a simple demo application to explore how {{site.mesh_product_name}} works. The application consists of two services:

- `demo-app`: A web application that lets you increment a numeric counter.
- `kv`: A data store that keeps the counter's value.

<!-- vale Vale.Spelling = NO -->
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
<!-- vale Vale.Spelling = YES -->

## Prerequisites

1. Make sure you have the following tools installed: `docker`, `curl`, `jq`, and `base64`

   {:.info}
   > **Note:** This guide has been tested with [Docker Engine](https://docs.docker.com/engine/), [Docker Desktop](https://docs.docker.com/desktop/), [OrbStack](https://orbstack.dev/), and [Colima](https://github.com/abiosoft/colima). A small adjustment is required for Colima, which we'll explain later.

## Prepare the environment

1. **Install {{site.mesh_product_name}}**

   Run the installation command:

   ```sh
   curl -L https://developer.konghq.com/mesh/installer.sh | sh -
   ```

   Then add the binaries to your system's [PATH](https://en.wikipedia.org/wiki/PATH_(variable)). Replace `<version>` with the version shown by the installer:

   ```sh
   export PATH="$(pwd)/kong-mesh-<version>/bin:$PATH"
   ```

   To confirm that {{site.mesh_product_name}} is installed correctly, run:

   ```sh
   kumactl version 2>/dev/null
   ```

   You should see output similar to:

   ```
   Client: {{site.mesh_product_name}} <version>
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
   name: {% raw %}{{ name }}{% endraw %}{% if_version gte:2.10.x %}
   labels:
     app: {% raw %}{{ name }}{% endraw %}{% endif_version %}
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

## Set up the control plane

1. **Start the control plane**

   Use the official Docker image to run the {{site.mesh_product_name}} control plane. This image starts the control plane binary automatically, so no extra flags or configurations are needed for this guide. Simply use the `run` command:

   ```sh
   docker run \
     --detach \
     --name kong-mesh-demo-control-plane \
     --hostname control-plane \
     --network kong-mesh-demo \
     --ip 172.57.78.1 \
     --publish 25681:5681 \
     --volume "$KONG_MESH_DEMO_TMP:/demo" \
     kong/kuma-cp:latest run
   ```

   You can now access the [{{site.mesh_product_name}} user interface (GUI)](/mesh/interact-with-control-plane/) at <http://127.0.0.1:25681/gui>.

2. **Configure kumactl**

   To use [kumactl](/mesh/cli/) with our {{site.mesh_product_name}} deployment, we need to connect it to the control plane we set up earlier.

   1. **Retrieve the admin token**

      Run the following command to get the admin token from the control plane:

      ```sh
      export KONG_MESH_DEMO_ADMIN_TOKEN="$( 
        docker exec --tty --interactive kong-mesh-demo-control-plane \
          wget --quiet --output-document - \
          http://127.0.0.1:5681/global-secrets/admin-user-token \
          | jq --raw-output .data \
          | base64 --decode
      )"
      ```

   2. **Connect to the control plane**

      Use the retrieved token to link [kumactl](/mesh/cli/) to the control plane:

      ```sh
      kumactl config control-planes add \
        --name kong-mesh-demo \
        --address http://127.0.0.1:25681 \
        --auth-type tokens \
        --auth-conf "token=$KONG_MESH_DEMO_ADMIN_TOKEN" \
        --skip-verify
      ```

   3. **Verify the connection**

      Run this command to check if the connection is working:

      ```sh
      kumactl get meshes
      ```

      You should see a list of meshes with one entry: `default`. This confirms the configuration is successful.

3. **Configure the default mesh**

   Set the default mesh to use [MeshServices](/mesh/meshservice/) in [Exclusive mode](/mesh/meshservice/#exclusive). MeshServices are explicit resources that represent destinations for traffic in the mesh. They define which [Dataplanes](/mesh/data-plane-proxy/) serve the traffic, as well as the available ports, IPs, and hostnames. This configuration ensures a clearer and more precise way to manage services and traffic routing in the mesh.

   ```sh
   echo 'type: Mesh
   name: default
   meshServices:
     mode: Exclusive' | kumactl apply -f -
   ```

## Set up services

<!-- vale Google.Headings = NO -->
### Key/Value Store
<!-- vale Google.Headings = YES -->

This section explains how to start the `kv` service, which mimics key/value store database.

1. **Generate a data plane token**

   Create a token for the `kv` data plane proxy to authenticate with the control plane:

   ```sh
   kumactl generate dataplane-token \
     --tag kuma.io/service=kv \
     --valid-for 720h \
     > "$KONG_MESH_DEMO_TMP/token-kv"
   ```

2. **Start the container**

   ```sh
   docker run \
     --detach \
     --name kong-mesh-demo-kv \
     --hostname kv \
     --network kong-mesh-demo \
     --ip 172.57.78.2 \
     --volume "$KONG_MESH_DEMO_TMP:/demo" \
     ghcr.io/kumahq/kuma-counter-demo:debian-slim
   ```
   
   To confirm the container is running properly, check its logs:

   ```sh
   docker logs kong-mesh-demo-kv
   ```

   You should see a line like:

   ```txt
   time=2025-03-14T12:17:34.630Z level=INFO ... msg="server running" addr=:5050
   ```

   indicating that the key/value store is up and running.

3. **Prepare the container**

   Enter the container for the remaining steps. Inside it, you'll configure the zone name in the key-value store, start the data plane proxy, and install the transparent proxy.

   ```sh
   docker exec --tty --interactive --privileged kong-mesh-demo-kv bash
   ```

   {:.important.no-icon}
   > **Important:** The following steps must be executed inside the container.

   1. **Install tools and create data plane proxy user**

      Install the required tools for downloading {{site.mesh_product_name}} binaries, setting up the [transparent proxy](/mesh/transparent-proxying/), and create a dedicated user for the data plane proxy:

      - `curl`: Needed to download the {{site.mesh_product_name}} binaries.
      - `iptables`: Required to configure the transparent proxy.

      Run the following commands:

      ```sh
      # install necessary packages
      apt-get update && \
        apt-get install --yes curl iptables
      
      # download and install {{site.mesh_product_name}}
      curl --location https://developer.konghq.com/mesh/installer.sh | sh -
      
      # move {{site.mesh_product_name}} binaries to /usr/local/bin/ for global availability
      mv kong-mesh-*/bin/* /usr/local/bin/
      
      # create a dedicated user for the data plane proxy
      useradd --uid 5678 --user-group kong-mesh-data-plane-proxy
      ```

   2. **Set the zone name**

      Give the `kv` instance a name. The demo application will use this name to identify which `kv` instance is accessed:

      ```sh
      curl localhost:5050/api/key-value/zone \
        --header 'Content-Type: application/json' \
        --data '{"value":"local-demo-zone"}'
      ```

      You should see a response:

      ```json
      {"value":"local-demo-zone"}
      ```

      indicating that the name was successfully set.

   3. **Start the data plane proxy**

      ```sh
      runuser --user kong-mesh-data-plane-proxy -- \
        /usr/local/bin/kuma-dp run \
          --cp-address https://control-plane:5678 \
          --dataplane-token-file /demo/token-kv \
          --dataplane-file /demo/dataplane.yaml \
          --dataplane-var name=kv \
          --dataplane-var address=172.57.78.2 \
          --dataplane-var port=5050 \
          > /demo/logs-data-plane-proxy-kv.log 2>&1 &
      ```

      To verify the data plane proxy is running, after few seconds check the logs:

      ```sh
      tail /demo/logs-data-plane-proxy-kv.log
      ```

      You should see entries like:
      
      ```
      [2025-03-14 12:24:54.779][3088][info][config] [source/common/listener_manager/listener_manager_impl.cc:944] all dependencies initialized. starting workers
      [2025-03-14 12:24:59.595][3088][info][upstream] [source/common/upstream/cds_api_helper.cc:32] cds: add 8 cluster(s), remove 2 cluster(s)
      [2025-03-14 12:24:59.623][3088][info][upstream] [source/common/upstream/cds_api_helper.cc:71] cds: added/updated 1 cluster(s), skipped 7 unmodified cluster(s)
      [2025-03-14 12:24:59.628][3088][info][upstream] [source/common/listener_manager/lds_api.cc:106] lds: add/update listener 'kuma:dns'
      [2025-03-14 12:24:59.649][3088][info][upstream] [source/common/listener_manager/lds_api.cc:106] lds: add/update listener 'outbound:241.0.0.0:5050'
      ```

      indicating that the data plane proxy has started and is configured successfully.

   4. **Install the transparent proxy**

      {:.warning}
      > **Important:** Make sure this command is executed **inside the container**. It changes iptables rules to redirect all traffic to the data plane proxy. Running it on your computer or a virtual machine without the data plane proxy can disrupt network connectivity. On a virtual machine, this might lock you out until you restart it.

      ```sh
      kumactl install transparent-proxy \
        --config-file /demo/config-transparent-proxy.yaml \
        > /demo/logs-transparent-proxy-install-kv.log 2>&1
      ```

      To confirm the transparent proxy installed successfully, check the last log line:

      ```sh
      tail -n1 /demo/logs-transparent-proxy-install-kv.log
      ```

      You should see a message containing:

      ```sh
      # transparent proxy setup completed successfully
      ```

      indicating that the transparent proxy is now configured.

   5. **Exit the container**

      Key/Value Store is now set up and running. You can safely exit the container as the configuration is complete:

      ```sh
      exit
      ```

4. **Check if service is running**

   To confirm the service is set up correctly and running, use [kumactl](/mesh/cli/) to inspect the MeshServices:

   ```sh
   kumactl get meshservices
   ```

   The output should show a single service, `kv`.

   You can also open the [{{site.mesh_product_name}} GUI](/mesh/interact-with-control-plane/) at <http://127.0.0.1:25681/gui/meshes/default/services/mesh-services>. Look for the `kv` service, and verify that its state is `Available`.

### Demo Application

The steps are the same as those explained earlier, with only the names changed. We won't repeat the explanations here, but you can refer to the [Key/Value Store service](#keyvalue-store) instructions if needed.


1. **Generate a data plane token**

   ```sh
   kumactl generate dataplane-token \
     --tag kuma.io/service=demo-app \
     --valid-for 720h \
     > "$KONG_MESH_DEMO_TMP/token-demo-app"
   ```

2. **Start the application container**

   ```sh
   docker run \
     --detach \
     --name kong-mesh-demo-app \
     --hostname demo-app \
     --network kong-mesh-demo \
     --ip 172.57.78.3 \
     --publish 25050:5050 \
     --volume "$KONG_MESH_DEMO_TMP:/demo" \
     --env KV_URL=http://kv.svc.mesh.local:5050 \
     --env APP_VERSION=v1 \
     ghcr.io/kumahq/kuma-counter-demo:debian-slim
   ```

   To confirm the container is running, check its logs:

   ```sh
   docker logs kong-mesh-demo-app
   ```

   Look for log entries like:

   ```
   time=2025-03-14T12:40:51.954Z level=INFO ... msg="starting handler with" kv-url=http://kv.svc.mesh.local:5050 version=v1
   time=2025-03-14T12:40:51.961Z level=INFO ... msg="server running" addr=:5050
   ```

   which indicates the demo app is up and listening on port `5050`.

3. **Prepare the application container**

   Enter the container to install the data plane proxy and transparent proxy.

   ```sh
   docker exec --tty --interactive --privileged kong-mesh-demo-app bash
   ```

   {:.important.no-icon}
   > **Important:** The following steps must be executed inside the container.

   1. **Install tools and create data plane proxy user**

      ```sh
      # install necessary packages
      apt-get update && \
        apt-get install --yes curl iptables
      
      # download and install {{site.mesh_product_name}}
      curl --location https://developer.konghq.com/mesh/installer.sh | sh -
      
      # move {{site.mesh_product_name}} binaries to /usr/local/bin/ for global availability
      mv kong-mesh-*/bin/* /usr/local/bin/
      
      # create a dedicated user for the data plane proxy
      useradd --uid 5678 --user-group kong-mesh-data-plane-proxy
      ```

   2. **Start the data plane proxy**

      ```sh
      runuser --user kong-mesh-data-plane-proxy -- \
        /usr/local/bin/kuma-dp run \
          --cp-address https://control-plane:5678 \
          --dataplane-token-file /demo/token-demo-app \
          --dataplane-file /demo/dataplane.yaml \
          --dataplane-var name=demo-app \
          --dataplane-var address=172.57.78.3 \
          --dataplane-var port=5050 \
          > /demo/logs-data-plane-proxy-demo-app.log 2>&1 &
      ```

      To verify the proxy is running, after few seconds check its logs:

      ```sh
      tail /demo/logs-data-plane-proxy-demo-app.log
      ```

      You should see logs similar to:

      ```
      [2025-03-14 12:42:45.797][3090][info][config] [source/common/listener_manager/listener_manager_impl.cc:944] all dependencies initialized. starting workers
      [2025-03-14 12:42:48.159][3090][info][upstream] [source/common/upstream/cds_api_helper.cc:32] cds: add 9 cluster(s), remove 2 cluster(s)
      [2025-03-14 12:42:48.210][3090][info][upstream] [source/common/upstream/cds_api_helper.cc:71] cds: added/updated 1 cluster(s), skipped 8 unmodified cluster(s)
      [2025-03-14 12:42:48.218][3090][info][upstream] [source/common/listener_manager/lds_api.cc:106] lds: add/update listener 'kuma:dns'
      [2025-03-14 12:42:48.245][3090][info][upstream] [source/common/listener_manager/lds_api.cc:106] lds: add/update listener 'outbound:241.0.0.1:5050'
      ```

      indicating that the data plane proxy has started and is configured successfully.

   3. **Install the transparent proxy**

      {:.warning}
      > **Important:** Make sure this command is executed **inside the container**. It changes iptables rules to redirect all traffic to the data plane proxy. Running it on your computer or a virtual machine without the data plane proxy can disrupt network connectivity. On a virtual machine, this might lock you out until you restart it.

      ```sh
      kumactl install transparent-proxy \
        --config-file /demo/config-transparent-proxy.yaml \
        > /demo/logs-transparent-proxy-install-demo-app.log 2>&1
      ```

      To confirm success, check the last line of the log:

      ```sh
      tail -n1 /demo/logs-transparent-proxy-install-demo-app.log
      ```
      
      You should see a message containing:
      
      ```sh
      # transparent proxy setup completed successfully
      ```

   4. **Exit the container**

      Demo application is now set up and running. You can safely exit the container as the configuration is complete:

      ```sh
      exit
      ```

4. **Verify the application**

   Open <http://127.0.0.1:25050> in your browser and use the demo application to increment the counter. The demo application is now fully set up and running.

   You can also check if the services were registered successfully:

   ```sh
   kumactl get meshservices
   ```

   You should see the registered services, including the `demo-app`.

## Introduction to zero-trust security

By default, the network is **insecure and unencrypted**. With {{site.mesh_product_name}}, you can enable the [Mutual TLS (mTLS)](/mesh/policies/mutual-tls/) policy to secure the network. This works by setting up a Certificate Authority (CA) that automatically provides TLS certificates to your services (specifically to the data plane proxies running next to each service).

To enable Mutual TLS using a `builtin` CA backend, run the following command:

```sh
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin' | kumactl apply -f -
```

After enabling mTLS, all traffic is **encrypted and secure**. However, you can no longer access the `demo-app` directly, meaning <http://127.0.0.1:25050> will no longer work. This happens for two reasons:

<!-- vale Vale.Terms = NO -->
1. When mTLS is enabled, {{site.mesh_product_name}} doesn't create traffic permissions by default. This means no traffic will flow until you define a [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy to allow `demo-app` to communicate with `kv`.

2. When you try to call `demo-app` using a browser or other HTTP client, you are essentially acting as an external client without a valid TLS certificate. Since all services are now required to present a certificate signed by the `ca-1` Certificate Authority, the connection is rejected. Only services within the `default` mesh, which are assigned valid certificates, can communicate with each other.
<!-- vale Vale.Terms = YES -->

To address the first issue, you need to apply an appropriate [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy:

```sh
echo 'type: MeshTrafficPermission 
name: allow-kv-from-demo-app
mesh: default 
spec: 
  targetRef:
    kind: {% if_version lte:2.9.x %}MeshSubset
    tags:
      kuma.io/service{% endif_version %}{% if_version gte:2.10.x %}Dataplane
    labels:
      app{% endif_version %}: kv
  from: 
  - targetRef: 
      kind: MeshSubset 
      tags:
        kuma.io/service: demo-app
    default: 
      action: Allow' | kumactl apply -f -
```

The second issue is a bit more challenging. You can't just get the necessary certificate and set up your web browser to act as part of the mesh. To handle traffic from outside the mesh, you need a _gateway proxy_. You can use tools like [Kong](https://github.com/Kong/kong), or you can use the [Built-in Gateway](/mesh/built-in-gateway/) that {{site.mesh_product_name}} provides.

{:.info}
> **Note:** For more information, see the [Managing incoming traffic with gateways](/mesh/ingress/) section in the documentation.

In this guide, we'll use the built-in gateway. It allows you to configure a data plane proxy to act as a gateway and manage external traffic securely.

### Setting up the built-in gateway

The built-in gateway works like the data plane proxy for a regular service, but it requires its own configuration. Here's how to set it up step by step.

1. **Create a Dataplane resource**

   For regular services, we reused a single [Dataplane](/mesh/data-plane-proxy/) configuration file and provided dynamic values (like names and addresses) when starting the data plane proxy. This made it easier to scale or deploy multiple instances. However, since we're deploying only one instance of the gateway, we can simplify things by hardcoding all the values directly into the file, as shown below:

   ```sh
   echo 'type: Dataplane
   mesh: default
   name: edge-gateway-instance-1
   networking:
     gateway:
       type: BUILTIN
       tags:
         kuma.io/service: edge-gateway
     address: 172.57.78.4' > "$KONG_MESH_DEMO_TMP/dataplane-edge-gateway.yaml"
   ```

   If you prefer to keep the flexibility of dynamic values, you can use the same template mechanisms for the gateway's [Dataplane](/mesh/data-plane-proxy/) configuration as you did for regular services.

2. **Generate a data plane token**

   The gateway proxy requires a data plane token to securely register with the control plane. You can generate the token using the following command:

   ```sh
   kumactl generate dataplane-token \
     --tag kuma.io/service=edge-gateway \
     --valid-for 720h \
     > "$KONG_MESH_DEMO_TMP/token-edge-gateway"
   ```

3. **Start the gateway container**

   With the configuration and token in place, you can start the gateway proxy as a container:

   ```sh
   docker run \
     --detach \
     --name kong-mesh-demo-edge-gateway \
     --hostname gateway \
     --network kong-mesh-demo \
     --ip 172.57.78.4 \
     --publish 28080:8080 \
     --volume "$KONG_MESH_DEMO_TMP:/demo" \
     kong/kuma-dp:latest run \
       --cp-address https://control-plane:5678 \
       --dataplane-token-file /demo/token-edge-gateway \
       --dataplane-file /demo/dataplane-edge-gateway.yaml \
       --dns-enabled=false
   ```

   This command starts the gateway proxy and registers it with the control plane. However, the gateway is not yet ready to route traffic.

4. **Configure the gateway with [MeshGateway](/mesh/gateway-listeners/)**

   To enable the gateway to accept external traffic, configure it with a [MeshGateway](/mesh/gateway-listeners/). This setup defines listeners that specify the port, protocol, and tags for incoming traffic, allowing policies like [MeshHTTPRoute](/mesh/policies/meshhttproute/) or [MeshTCPRoute](/mesh/policies/meshtcproute/) to route traffic to services.

   Apply the configuration:

   ```sh
   echo 'type: MeshGateway
   mesh: default
   name: edge-gateway
   selectors:
   - match:
       kuma.io/service: edge-gateway
   conf:
     listeners:
     - port: 8080
       protocol: HTTP
       tags:
         port: http-8080' | kumactl apply -f -
   ```

   <!-- vale Vale.Terms = NO -->
   This sets up the gateway to listen on port `8080` using the HTTP protocol and adds a tag (`port: http-8080`) to identify this listener in routing policies.
   <!-- vale Vale.Terms = YES -->

   You can test the gateway by visiting <http://127.0.0.1:28080>. You should see a message saying no routes match this [MeshGateway](/mesh/gateway-listeners/). This means the gateway is running, but no routes are set up yet to handle traffic.

5. **Create a route to connect the gateway to `demo-app`**

   To route traffic from the gateway to the service, create a [MeshHTTPRoute](/mesh/policies/meshhttproute/) policy:

   ```sh
   echo 'type: MeshHTTPRoute
   name: edge-gateway-demo-app-route
   mesh: default
   spec:
     targetRef:
       kind: MeshGateway
       name: edge-gateway
       tags:
         port: http-8080
     to:
     - targetRef:
         kind: Mesh
       rules:
       - matches:
         - path:
             type: PathPrefix
             value: "/"
         default:
           backendRefs:
           - kind: MeshService
             name: demo-app' | kumactl apply -f -
   ```

   This route connects the gateway and its listener (`port: http-8080`) to the `demo-app` service. It forwards any requests with the path prefix `/` to `demo-app`.

   After setting up this route, the gateway will try to send traffic to `demo-app`. However, if you test it by visiting <http://127.0.0.1:28080>, you'll see:

   ```
   RBAC: access denied
   ```
   {:.no-line-numbers}

   This happens because there is no [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy allowing traffic from the gateway to `demo-app`. You'll need to create one in the next step.

6. **Allow traffic from the gateway to `demo-app`**

   To fix the `RBAC: access denied` error, create a [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy to allow the gateway to send traffic to `demo-app`:

   ```sh
   echo 'type: MeshTrafficPermission
   name: allow-demo-app-from-edge-gateway
   mesh: default
   spec:
     targetRef:
       kind: {% if_version lte:2.9.x %}MeshSubset
       tags:
         kuma.io/service{% endif_version %}{% if_version gte:2.10.x %}Dataplane
       labels:
         app{% endif_version %}: demo-app
     from:
     - targetRef:
         kind: MeshSubset
         tags:
           kuma.io/service: edge-gateway
       default:
         action: Allow' | kumactl apply -f -
   ```

   This policy allows traffic from the gateway to `demo-app`. After applying it, you can access <http://127.0.0.1:28080>, and the traffic will reach the `demo-app` service successfully.

## Cleanup

To clean up your environment, remove the Docker containers, network, temporary directory, and the control plane configuration from [kumactl](/mesh/cli/). Run the following commands:

```sh
kumactl config control-planes remove --name kong-mesh-demo

docker rm --force \
   kong-mesh-demo-control-plane \
   kong-mesh-demo-kv \
   kong-mesh-demo-app \
   kong-mesh-demo-edge-gateway

docker network rm kong-mesh-demo

# If you're using Colima, update this path as needed.
rm -rf /tmp/kong-mesh-demo
```

## Next steps

- Explore all [features](/mesh/enterprise/) to better understand {{site.mesh_product_name}}'s capabilities.
- Try using the [{{site.mesh_product_name}} GUI](/mesh/interact-with-control-plane/) to easily visualize your mesh.
- Read the [full documentation](/mesh/) for more details.
- Check deployment examples for [single-zone](/mesh/single-zone/) or [multi-zone](/mesh/mesh-multizone-service-deployment/) setups.
