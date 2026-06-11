---
title: Set up the {{site.mesh_product_name}} key/value store
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

## Generate a data plane token

Create a token for the `kv` data plane proxy to authenticate with the control plane:

```sh
kumactl generate dataplane-token \
  --tag kuma.io/service=kv \
  --valid-for 720h \
  > "$KONG_MESH_DEMO_TMP/token-kv"
```

## Start the container

1. Run the container:

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

1. Check the container logs to confirm it started:

   ```sh
   docker logs kong-mesh-demo-kv
   ```

   You should see something like this:

   ```txt
   time=2025-03-14T12:17:34.630Z level=INFO ... msg="server running" addr=:5050
   ```
   {:.no-copy-code}

## Configure the container

Enter the container for the remaining steps. Inside it, you'll configure the zone name in the key-value store, start the data plane proxy, and install the transparent proxy.

```sh
docker exec --tty --interactive --privileged kong-mesh-demo-kv bash
```

{:.warning}
> The following steps must be executed inside the container.

### Install tools and create data plane proxy user

1. Install the required tools:

   * `curl`: Downloads the {{site.mesh_product_name}} binaries.
   * `iptables`: Configures the [transparent proxy](/mesh/transparent-proxying/).

   ```sh
   apt-get update && \
     apt-get install --yes curl iptables
   ```

1. Download and install {{site.mesh_product_name}}:
   ```sh
   curl --location https://developer.konghq.com/mesh/installer.sh | sh -
   ```

1. Move {{site.mesh_product_name}} binaries to `/usr/local/bin/` for global availability:
   ```sh
   mv kong-mesh-*/bin/* /usr/local/bin/
   ```

1. Create a dedicated user for the data plane proxy
   ```sh
   useradd --uid 5678 --user-group kong-mesh-data-plane-proxy
   ```

### Set the zone name

Give the `kv` instance a name. The demo application will use this name to identify which `kv` instance is accessed:

```sh
curl localhost:5050/api/key-value/zone \
  --header 'Content-Type: application/json' \
  --data '{"value":"local-demo-zone"}'
```

You should see the following output:

```json
{"value":"local-demo-zone"}
```
{:.no-copy-code}

### Start the data plane proxy

1. Start the proxy:

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

1. After a few seconds, check the logs to verify the proxy is running:

   ```sh
   tail /demo/logs-data-plane-proxy-kv.log
   ```

   You should see entries like these:

   ```
   [2025-03-14 12:24:54.779][3088][info][config] [source/common/listener_manager/listener_manager_impl.cc:944] all dependencies initialized. starting workers
   [2025-03-14 12:24:59.595][3088][info][upstream] [source/common/upstream/cds_api_helper.cc:32] cds: add 8 cluster(s), remove 2 cluster(s)
   [2025-03-14 12:24:59.623][3088][info][upstream] [source/common/upstream/cds_api_helper.cc:71] cds: added/updated 1 cluster(s), skipped 7 unmodified cluster(s)
   [2025-03-14 12:24:59.628][3088][info][upstream] [source/common/listener_manager/lds_api.cc:106] lds: add/update listener 'kuma:dns'
   [2025-03-14 12:24:59.649][3088][info][upstream] [source/common/listener_manager/lds_api.cc:106] lds: add/update listener 'outbound:241.0.0.0:5050'
   ```
   {:.no-copy-code}

### Install the transparent proxy

{:.danger}
> Make sure this command is executed **inside the container**. It changes iptables rules to redirect all traffic to the data plane proxy. Running it on your computer or a virtual machine without the data plane proxy can disrupt network connectivity. On a virtual machine, this might lock you out until you restart it.

1. Install the transparent proxy:

   ```sh
   kumactl install transparent-proxy \
     --config-file /demo/config-transparent-proxy.yaml \
     > /demo/logs-transparent-proxy-install-kv.log 2>&1
   ```

1. Confirm the installation succeeded by checking the last line of the log:

   ```sh
   tail -n1 /demo/logs-transparent-proxy-install-kv.log
   ```

   You should see the following output:

   ```sh
   # transparent proxy setup completed successfully
   ```
   {:.no-copy-code}

### Exit the container

The key/value store is set up. Exit the container:

```sh
exit
```

## Check if service is running

To confirm the service is set up correctly and running, use [kumactl](/mesh/cli/) to inspect the `MeshService` resources:

```sh
kumactl get meshservices
```

The output should show a single service, `kv`.

You can also open the {{site.mesh_product_name}} UI at <http://127.0.0.1:25681/gui/meshes/default/services/mesh-services>. Look for the `kv` service, and verify that its state is `Available`.
