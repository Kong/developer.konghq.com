---
title: Set up the control plane
description: "Start the {{site.mesh_product_name}} control plane as a Docker container and configure kumactl to connect to it."
content_type: how_to
permalink: /mesh/get-started/universal/control-plane/
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
  position: 2
tldr:
  q: How do I start the {{site.mesh_product_name}} control plane in Universal mode?
  a: Run the control plane as a Docker container, retrieve the admin token, configure kumactl to connect to it, and enable MeshServices in Exclusive mode.
---

## Start the control plane

Run the {{site.mesh_product_name}} control plane using the official Docker image:

```sh
docker run \
  --detach \
  --name kong-mesh-demo-control-plane \
  --hostname control-plane \
  --network kong-mesh-demo \
  --ip 172.57.78.1 \
  --publish 25681:5681 \
  --volume "$KONG_MESH_DEMO_TMP:/demo" \
  kong/kuma-cp:{{site.data.mesh_latest.version}} run
```

You can now access the [{{site.mesh_product_name}} user interface (GUI)](/mesh/interact-with-control-plane/) at <http://127.0.0.1:25681/gui>.

## Configure kumactl

To manage the deployment with [kumactl](/mesh/cli/), connect it to the control plane you started in the previous section.

### Retrieve the admin token

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

### Connect to the control plane

Use the retrieved token to link [kumactl](/mesh/cli/) to the control plane:

```sh
kumactl config control-planes add \
  --name kong-mesh-demo \
  --address http://127.0.0.1:25681 \
  --auth-type tokens \
  --auth-conf "token=$KONG_MESH_DEMO_ADMIN_TOKEN" \
  --skip-verify
```

### Verify the connection

To verify the connection, run:

```sh
kumactl get meshes
```

You should see one mesh listed: `default`.

## Configure the default mesh

Set the default mesh to use [MeshServices](/mesh/meshservice/) in [Exclusive mode](/mesh/meshservice/#exclusive). MeshServices are explicit resources that represent traffic destinations — they define which [Dataplanes](/mesh/data-plane-proxy/) serve the traffic and the available ports, IPs, and hostnames.

```sh
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive' | kumactl apply -f -
```
