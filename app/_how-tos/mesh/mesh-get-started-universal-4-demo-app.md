---
title: Set up the demo application
description: "Deploy the demo-app service as a Docker container and configure a data plane proxy and transparent proxy in {{site.mesh_product_name}} Universal mode."
content_type: how_to
permalink: /mesh/get-started/universal/demo-app/
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
  position: 4
tldr:
  q: How do I set up the demo application in {{site.mesh_product_name}} Universal mode?
  a: Deploy the demo-app container, install the data plane proxy inside it, start the proxy with a generated token, and configure the transparent proxy to intercept all traffic automatically.
---

The steps are the same as in the [previous page](/mesh/get-started/universal/kv/), with only the names changed.

## Generate a data plane token

```sh
kumactl generate dataplane-token \
  --tag kuma.io/service=demo-app \
  --valid-for 720h \
  > "$KONG_MESH_DEMO_TMP/token-demo-app"
```

## Start the application container

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

## Prepare the application container

Enter the container to install the data plane proxy and transparent proxy.

```sh
docker exec --tty --interactive --privileged kong-mesh-demo-app bash
```

{:.important.no-icon}
> **Important:** The following steps must be executed inside the container.

### Install tools and create data plane proxy user

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

### Start the data plane proxy

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

### Install the transparent proxy

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

### Exit the container

Demo application is now set up and running. You can safely exit the container as the configuration is complete:

```sh
exit
```

## Verify the application

Open <http://127.0.0.1:25050> in your browser and use the demo application to increment the counter. The demo application is now fully set up and running.

You can also check if the services were registered successfully:

```sh
kumactl get meshservices
```

You should see the registered services, including the `demo-app`.
