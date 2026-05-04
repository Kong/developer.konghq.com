---
title: Set up the key/value store
description: "Deploy the kv service as a Docker container and configure a data plane proxy and transparent proxy in {{site.mesh_product_name}} Universal mode."
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
min_version:
  mesh: '2.10'
series:
  id: mesh-get-started-universal
  position: 3
tldr:
  q: How do I set up the key/value store service in {{site.mesh_product_name}} Universal mode?
  a: Deploy the kv container, install the {{site.mesh_product_name}} binaries and data plane proxy inside it, and configure the transparent proxy to intercept all traffic automatically.
---

The `kv` service mimics a key/value store database.

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
