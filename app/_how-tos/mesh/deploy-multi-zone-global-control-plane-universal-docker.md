---
title: Deploy a multi-zone global {{site.mesh_product_name}} control plane in Universal mode with Docker
description: "Run a multi-zone {{site.mesh_product_name}} deployment in Universal mode using Docker containers: a PostgreSQL database, a global control plane, a zone control plane, and a zone ingress."
content_type: how_to
permalink: /mesh/deploy-multi-zone-global-control-plane-universal-docker/
breadcrumbs:
  - /mesh/
related_resources:
  - text: "Multi-zone deployment"
    url: /mesh/multi-zone/
  - text: "{{site.mesh_product_name}} data plane on Universal"
    url: /mesh/data-plane-universal/
  - text: "Zone ingress"
    url: /mesh/zone-ingress/
  - text: "Zone egress"
    url: /mesh/zone-egress/

products:
  - mesh

works_on:
  - on-prem

tags:
  - multi-zone
  - universal-mode
  - docker

min_version:
  mesh: '2.10'

prereqs:
  skip_product: true
  inline:
    - title: Docker
      content: |
        This guide requires [Docker](https://docs.docker.com/get-started/get-docker/) installed on your system.
    - title: jq
      content: |
        This guide requires [jq](https://jqlang.org/download/) installed on your system.

cleanup:
  inline:
    - title: Remove the {{site.mesh_product_name}} containers, network, and temporary directory
      content: |
        ```sh
        docker rm --force \
          kong-mesh-multi-zone-zone1-ingress \
          kong-mesh-multi-zone-zone1-control-plane \
          kong-mesh-multi-zone-global-control-plane \
          kong-mesh-multi-zone-postgres
        docker network rm kong-mesh-multi-zone
        rm -rf "$KONG_MESH_MULTI_ZONE_TMP"
        ```

tldr:
  q: How do I deploy a multi-zone {{site.mesh_product_name}} global control plane in Universal mode with Docker?
  a: Run PostgreSQL, a global control plane, and a zone control plane as Docker containers, then attach a zone ingress so the zone can join the global mesh and exchange traffic with other zones.
---

This guide walks you through running a multi-zone {{site.mesh_product_name}} deployment in Universal mode using Docker containers. We'll start a PostgreSQL database to back the control planes, deploy a global control plane, register a zone control plane against it, and run a zone ingress so cross-zone traffic can flow.

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

Set up a temporary directory to store the zone token and the `ZoneIngress` resource file. Ensure the path does not end with a trailing `/`.

{:.warning}
> If you are using [Colima](https://colima.run/), make sure to adjust the path in the steps of this guide. Colima only allows shared paths from the `HOME` directory or `/tmp/colima/`. Instead of `/tmp/kong-mesh-multi-zone`, you can use `/tmp/colima/kong-mesh-multi-zone`.

Create the directory if it doesn't exist:

```sh
export KONG_MESH_MULTI_ZONE_TMP="/tmp/kong-mesh-multi-zone"
mkdir -p "$KONG_MESH_MULTI_ZONE_TMP"
```

## Create a Docker network

Set up a separate Docker network for the containers. In this example we'll use IP addresses in the `172.18.78.0/24` range:

```sh
docker network create \
  --subnet 172.18.0.0/16 \
  --ip-range 172.18.78.0/24 \
  --gateway 172.18.78.254 \
  kong-mesh-multi-zone
```

## Start PostgreSQL

The global and zone control planes both need a database to persist state in Universal mode. Run a single PostgreSQL container and create one database per control plane.

1. Run PostgreSQL:

   ```sh
   docker run \
     --detach \
     --name kong-mesh-multi-zone-postgres \
     --hostname postgres \
     --network kong-mesh-multi-zone \
     --ip 172.18.78.10 \
     --env POSTGRES_USER=kong \
     --env POSTGRES_PASSWORD=pass123 \
     postgres:16
   ```

1. Create a database for each control plane:

   ```sh
   docker exec --interactive kong-mesh-multi-zone-postgres \
     psql -U kong -d postgres <<'SQL'
   CREATE DATABASE global;
   CREATE DATABASE zone1;
   SQL
   ```

## Start the global control plane

The global control plane accepts connections from zone control planes, distributes policies, and keeps an inventory of all data plane proxies across zones.

1. Run the database migrations for the `global` database:

   ```sh
   docker run --rm \
     --network kong-mesh-multi-zone \
     --env KUMA_STORE_TYPE=postgres \
     --env KUMA_STORE_POSTGRES_HOST=postgres \
     --env KUMA_STORE_POSTGRES_PORT=5432 \
     --env KUMA_STORE_POSTGRES_USER=kong \
     --env KUMA_STORE_POSTGRES_PASSWORD=pass123 \
     --env KUMA_STORE_POSTGRES_DB_NAME=global \
     kong/kuma-cp:{{site.data.mesh_latest.version}} migrate up
   ```

1. Run the global control plane:

   ```sh
   docker run \
     --detach \
     --name kong-mesh-multi-zone-global-control-plane \
     --hostname global-control-plane \
     --network kong-mesh-multi-zone \
     --ip 172.18.78.1 \
     --publish 5681:5681 \
     --publish 5685:5685 \
     --env KUMA_MODE=global \
     --env KUMA_ENVIRONMENT=universal \
     --env KUMA_STORE_TYPE=postgres \
     --env KUMA_STORE_POSTGRES_HOST=postgres \
     --env KUMA_STORE_POSTGRES_PORT=5432 \
     --env KUMA_STORE_POSTGRES_USER=kong \
     --env KUMA_STORE_POSTGRES_PASSWORD=pass123 \
     --env KUMA_STORE_POSTGRES_DB_NAME=global \
     kong/kuma-cp:{{site.data.mesh_latest.version}} run
   ```

   The global control plane exposes:

   * Port `5681`: the HTTP API and GUI, available at <http://127.0.0.1:5681/gui>.
   * Port `5685`: the {{site.mesh_product_name}} Discovery Service (KDS) endpoint that zone control planes connect to.

## Configure kumactl

To manage the deployment with [kumactl](/mesh/cli/), connect it to the global control plane.

1. Run the following command to get the admin token from the global control plane:

   ```sh
   export KONG_MESH_MULTI_ZONE_ADMIN_TOKEN="$(
     docker exec --tty --interactive kong-mesh-multi-zone-global-control-plane \
       wget --quiet --output-document - \
       http://127.0.0.1:5681/global-secrets/admin-user-token \
       | jq --raw-output .data \
       | base64 --decode
   )"
   ```

1. Use the retrieved token to link kumactl to the global control plane:

   ```sh
   kumactl config control-planes add \
     --name kong-mesh-multi-zone-global \
     --address http://127.0.0.1:5681 \
     --auth-type tokens \
     --auth-conf "token=$KONG_MESH_MULTI_ZONE_ADMIN_TOKEN" \
     --skip-verify
   ```

1. Run the following command to verify the connection. No zones are registered yet:

   ```sh
   kumactl get zones
   ```

   You should see an empty list.

## Configure the default mesh

Apply an mTLS-enabled `Mesh` to the global control plane. mTLS is required for cross-zone communication because {{site.mesh_product_name}} uses the [Server Name Indication](https://en.wikipedia.org/wiki/Server_Name_Indication) field of the TLS handshake to pass routing information between zones. The mesh syncs down to every zone once registered:

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

## Start the zone control plane

Each zone runs its own control plane. The zone control plane connects to the global control plane over KDS and serves XDS configuration to local data plane proxies.

1. Run the database migrations for the `zone1` database:

   ```sh
   docker run --rm \
     --network kong-mesh-multi-zone \
     --env KUMA_STORE_TYPE=postgres \
     --env KUMA_STORE_POSTGRES_HOST=postgres \
     --env KUMA_STORE_POSTGRES_PORT=5432 \
     --env KUMA_STORE_POSTGRES_USER=kong \
     --env KUMA_STORE_POSTGRES_PASSWORD=pass123 \
     --env KUMA_STORE_POSTGRES_DB_NAME=zone1 \
     kong/kuma-cp:{{site.data.mesh_latest.version}} migrate up
   ```

1. Run the zone control plane:

   ```sh
   docker run \
     --detach \
     --name kong-mesh-multi-zone-zone1-control-plane \
     --hostname zone1-control-plane \
     --network kong-mesh-multi-zone \
     --ip 172.18.78.2 \
     --publish 25681:5681 \
     --publish 25678:5678 \
     --env KUMA_MODE=zone \
     --env KUMA_MULTIZONE_ZONE_NAME=zone1 \
     --env KUMA_ENVIRONMENT=universal \
     --env KUMA_STORE_TYPE=postgres \
     --env KUMA_STORE_POSTGRES_HOST=postgres \
     --env KUMA_STORE_POSTGRES_PORT=5432 \
     --env KUMA_STORE_POSTGRES_USER=kong \
     --env KUMA_STORE_POSTGRES_PASSWORD=pass123 \
     --env KUMA_STORE_POSTGRES_DB_NAME=zone1 \
     --env KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS=grpcs://global-control-plane:5685 \
     --env KUMA_MULTIZONE_ZONE_KDS_TLS_SKIP_VERIFY=true \
     kong/kuma-cp:{{site.data.mesh_latest.version}} run
   ```

   The zone control plane exposes:

   * Port `25681`: the local HTTP API and GUI, available at <http://127.0.0.1:25681/gui>.
   * Port `25678`: the local XDS endpoint that data plane proxies inside the zone connect to.

   `KUMA_MULTIZONE_ZONE_KDS_TLS_SKIP_VERIFY=true` is required because the global control plane's certificate is self-signed in this demo. For production, use a certificate signed by a trusted CA. See [Secure access across services](/mesh/secure-access-across-services/) for more information.

1. Confirm the zone registered against the global control plane:

   ```sh
   kumactl get zones
   ```

   You should see `zone1` listed as `Online`.

## Start the zone ingress

A zone ingress is the entry point for cross-zone traffic. Without it, the global control plane has no way to route requests from other zones into `zone1`.

1. Generate a zone token scoped to ingress and egress for `zone1`:

   ```sh
   kumactl generate zone-token \
     --zone=zone1 \
     --valid-for 720h \
     --scope ingress \
     --scope egress \
     > "$KONG_MESH_MULTI_ZONE_TMP/token-zone1"
   ```

1. Create a `ZoneIngress` resource definition:

   ```sh
   echo 'type: ZoneIngress
   name: zone1-ingress
   networking:
     address: 172.18.78.3
     port: 10000
     advertisedAddress: zone1-ingress
     advertisedPort: 10000' > "$KONG_MESH_MULTI_ZONE_TMP/zone1-ingress.yaml"
   ```

   `networking.address` is the address `kuma-dp` binds to inside the ingress container. It must be a real address in this example we'll use the static IP we'll assign to the ingress container in the next step: `172.18.78.3`.

   `advertisedAddress` and `advertisedPort` are the values other zones use to reach this ingress. On this single-host Docker network, the container hostname `zone1-ingress` resolves via Docker's embedded DNS and works for both directions.

1. Run the zone ingress data plane proxy:

   ```sh
   docker run \
     --detach \
     --name kong-mesh-multi-zone-zone1-ingress \
     --hostname zone1-ingress \
     --network kong-mesh-multi-zone \
     --ip 172.18.78.3 \
     --publish 10000:10000 \
     --volume "$KONG_MESH_MULTI_ZONE_TMP:/demo" \
     kong/kuma-dp:{{site.data.mesh_latest.version}} run \
       --proxy-type=ingress \
       --cp-address=https://zone1-control-plane:5678 \
       --dataplane-token-file=/demo/token-zone1 \
       --dataplane-file=/demo/zone1-ingress.yaml
   ```

1. Confirm the zone ingress registered with the zone control plane:

   ```sh
   kumactl get zone-ingresses
   ```

   You should see `zone1-ingress` listed.

## Verify the deployment

1. Confirm the zone is healthy and online:

   ```sh
   kumactl inspect zones
   ```

   You should see `zone1` reporting `Online` with its ingress listed.

1. Open the global control plane UI at <http://127.0.0.1:5681/gui> and check that:

   * `zone1` appears in the **Zones** view.
   * `zone1-ingress` appears in the **Zone** > **Ingresses** view.
   * The `default` mesh has mTLS enabled.
