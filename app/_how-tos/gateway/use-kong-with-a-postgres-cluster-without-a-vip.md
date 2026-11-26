---
title: Use {{site.base_gateway}} with a PostgreSQL cluster without a VIP
permalink: /how-to/use-kong-with-a-postgres-cluster-without-a-vip/
content_type: how_to
description: Set `pg_host` to a list of every node in a PostgreSQL cluster, so that {{site.base_gateway}} finds the primary without a virtual IP (VIP) or load balancer.

products:
  - gateway

works_on:
  - on-prem

tier: enterprise

min_version:
  gateway: '3.17'

breadcrumbs:
  - /gateway/

tags:
  - database

search_aliases:
  - postgresql failover
  - postgresql high availability
  - multi-host postgresql

tldr:
  q: How do I run {{site.base_gateway}} against a PostgreSQL cluster that has no virtual IP (VIP) or load balancer?
  a: |
    Set `pg_host` to a comma-separated list of every node in the cluster.
    {{site.base_gateway}} connects to the node that accepts writes, and finds the new primary after a switchover without a reload.

prereqs:
  skip_product: true
  inline:
    - title: Docker
      content: |
        This guide uses [Docker](https://docs.docker.com/get-started/get-docker/) to create a PostgreSQL cluster and run {{site.base_gateway}}.
      icon_url: /assets/icons/third-party/docker.svg
    - title: "{{site.base_gateway}} license"
      include_content: prereqs/gateway-license
      icon_url: /assets/icons/gateway.svg

cleanup:
  inline:
    - title: Destroy the containers and the network
      content: |
        ```sh
        docker rm -f kong-gateway pg-primary pg-standby1 pg-standby2
        docker network rm kong-pg-net
        ```
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: PostgreSQL multi-host reference
    url: /gateway/postgresql-multi-host-reference/
  - text: Configure the {{site.base_gateway}} datastore on Linux
    url: /how-to/configure-datastore/
  - text: Traditional mode
    url: /gateway/traditional-mode/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/

automated_tests: false
---

If your PostgreSQL nodes run in different data centers without a virtual IP (VIP) or load balancer in front of them, a single `pg_host` value can't follow the primary when it moves to a different node.
When you list every node in [`pg_host`](/gateway/configuration/#pg-host), {{site.base_gateway}} connects to the node that accepts writes, and follows the primary when it moves.
You don't need to edit `pg_host` or reload {{site.base_gateway}}.

{:.info}
> This feature applies to traditional mode and to the control plane in hybrid mode.
> It doesn't apply to DB-less mode or to {{site.konnect_short_name}}, because those deployments don't connect to a database that you manage.

## Create a PostgreSQL cluster

If you already have a PostgreSQL cluster, skip this section and use the host names of your own nodes.
All nodes must belong to the same cluster and share the same database and credentials.

This example creates one primary and two standbys that use streaming replication.

1. Create a Docker network:

   ```sh
   docker network create kong-pg-net
   ```

1. Start the primary PostgreSQL node:

   ```sh
   docker run -d --name pg-primary --network kong-pg-net \
     -e POSTGRES_USER=kong \
     -e POSTGRES_PASSWORD=kong \
     -e POSTGRES_DB=kong \
     postgres:16
   ```

   It can take a few seconds for the container to create the `kong` database.
   Wait for the database before you continue.

1. Allow the `kong` user to replicate from the other nodes:

   ```sh
   docker exec pg-primary bash -c 'echo "host replication kong all scram-sha-256" >> "$PGDATA/pg_hba.conf"'
   docker exec pg-primary psql -U kong -c "SELECT pg_reload_conf();"
   ```

1. Start two standby PostgreSQL nodes, which copy the primary and then follow it:

   ```sh
   for n in 1 2; do
     docker run -d --name pg-standby$n --network kong-pg-net --user postgres \
       -e PGPASSWORD=kong \
       -e SLOT=standby$n \
       --entrypoint bash postgres:16 \
       -c 'rm -rf "$PGDATA"/* && pg_basebackup -h pg-primary -U kong -D "$PGDATA" -R -X stream -C -S "$SLOT" && chmod 700 "$PGDATA" && exec docker-entrypoint.sh postgres'
   done
   ```

   Each standby creates a replication slot on the primary.
   The slot keeps the primary from removing write-ahead log (WAL) files that the standby hasn't copied yet.

1. After a few seconds, check that both standbys are streaming from the primary:

   ```sh
   docker exec pg-primary psql -U kong -c "SELECT client_addr, state FROM pg_stat_replication;"
   ```

   The output lists two rows with the state `streaming`.

## Run database migrations

List every node in `KONG_PG_HOST`, separated by commas.
An entry without a port uses `pg_port`.
To use a different port for a node, write the entry as `host:port`.

{:.warning}
> When building the `KONG_PG_HOST` list, use the following guidelines:
> * Don't list nodes of different clusters. {{site.base_gateway}} treats every entry as a copy of the same database.
> * Don't list a node that you don't control. {{site.base_gateway}} sends the database credentials to every node in the list.
> * Don't use a DNS name that resolves to many addresses as one entry. {{site.base_gateway}} treats each entry as one node, and doesn't try each address of a name. List each node as a separate entry.

Run `kong migrations bootstrap` to bootstrap the database.
{{site.base_gateway}} finds the primary in the list and runs the migrations on it:

```sh
docker run --rm --network kong-pg-net \
  -e KONG_DATABASE=postgres \
  -e KONG_PG_HOST=pg-primary,pg-standby1,pg-standby2 \
  -e KONG_PG_USER=kong \
  -e KONG_PG_PASSWORD=kong \
  -e KONG_PG_DATABASE=kong \
  -e KONG_LICENSE_DATA \
  kong/kong-gateway:{{ site.data.gateway_latest.ee-version }} kong migrations bootstrap
```

## Start {{site.base_gateway}}

Start {{site.base_gateway}} with the same host list that you used for the migrations:

```sh
docker run -d --name kong-gateway --network kong-pg-net \
  -p 8001:8001 \
  -e KONG_DATABASE=postgres \
  -e KONG_PG_HOST=pg-primary,pg-standby1,pg-standby2 \
  -e KONG_PG_USER=kong \
  -e KONG_PG_PASSWORD=kong \
  -e KONG_PG_DATABASE=kong \
  -e KONG_ADMIN_LISTEN=0.0.0.0:8001 \
  -e KONG_LICENSE_DATA \
  kong/kong-gateway:{{ site.data.gateway_latest.ee-version }}
```

To find the primary, {{site.base_gateway}} runs `SHOW transaction_read_only` on each new connection:
* A node that answers `off` accepts writes, so {{site.base_gateway}} keeps the connection.
* A node that answers `on` is a standby, so {{site.base_gateway}} closes the connection and tries the next node.

The order of the list doesn't decide which node is the primary.

For more details on how {{site.base_gateway}} finds the primary, see the [PostgreSQL multi-host reference](/gateway/postgresql-multi-host-reference/).

## Switch over to a standby

1. Create a Gateway Service to confirm that {{site.base_gateway}} writes to the primary:

{% capture before-switchover %}
{% control_plane_request %}
url: /services
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: before-switchover
  url: http://example.com
status_code: 201
{% endcontrol_plane_request %}
{% endcapture %}

{{ before-switchover | indent: 3 }}

   The response is `201 Created`.

1. Stop the primary:

   ```sh
   docker stop pg-primary
   ```

1. Promote the first standby:

   ```sh
   docker exec pg-standby1 pg_ctl promote -D /var/lib/postgresql/data
   ```

   The second standby stays a standby, so {{site.base_gateway}} skips it.

1. Create another Service without reloading {{site.base_gateway}}:

{% capture after-switchover %}
{% control_plane_request %}
url: /services
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: after-switchover
  url: http://example.com
status_code: 201
{% endcontrol_plane_request %}
{% endcapture %}

{{ after-switchover | indent: 3 }}

   You should get a `201 Created` response again.

The request can take longer than usual, because {{site.base_gateway}} first has to find the new primary.

If a request is in progress while the primary moves, the request can fail, because {{site.base_gateway}} doesn't retry queries that could write to the database.
If you get an error right after the promotion, send the request again.

{:.info}
> Finding the primary can take longer when nodes are down during a failover.
> {{site.base_gateway}} applies the [`pg_timeout`](/gateway/configuration/#pg-timeout) parameter to each node in the list, so the wait can be up to the number of nodes multiplied by `pg_timeout`.
>
> With the default `pg_timeout` of 5000 ms and three nodes, two of which drop packets, a new connection can wait about 10 seconds before it reaches the primary.
> To shorten the wait time, set a lower `pg_timeout`.

## Validate

Check that {{site.base_gateway}} moved to the new primary:

```sh
docker logs kong-gateway 2>&1 | grep "connected to PostgreSQL host"
```

The output includes a notice for each worker that moved to the new primary, with the node that it used before:


While the primary is down, the error log can also list the cause for each node that {{site.base_gateway}} tried, for example `pg-primary:5432: connection refused` and `pg-standby2:5432: server is read-only (not the primary)`.
This is expected until one node accepts writes.