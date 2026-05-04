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
  mesh: '2.9'
series:
  id: mesh-get-started-universal
  position: 2
tldr:
  q: How do I start the {{site.mesh_product_name}} control plane in Universal mode?
  a: Run the control plane as a Docker container, retrieve the admin token, configure kumactl to connect to it, and enable MeshServices in Exclusive mode.
---

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
