---
title: PostgreSQL multi-host reference
content_type: reference
layout: reference
description: 'How {{site.base_gateway}} uses a list of PostgreSQL nodes in `pg_host`. Covers the host list format, how {{site.base_gateway}} finds the primary, timeouts, logs, and failure modes.'
permalink: /gateway/postgresql-multi-host-reference/

breadcrumbs:
  - /gateway/

products:
  - gateway

works_on:
  - on-prem

tier: enterprise

min_version:
  gateway: '3.17'

tags:
  - database

search_aliases:
  - database failover
  - primary detection

related_resources:
  - text: Use {{site.base_gateway}} with a PostgreSQL cluster without a VIP
    url: /how-to/use-kong-with-a-postgres-cluster-without-a-vip/
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/#datastore
  - text: Traditional mode
    url: /gateway/traditional-mode/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/
  - text: PostgreSQL TLS configuration reference
    url: /gateway/postgresql-tls-reference/
  - text: PostgreSQL privileges reference
    url: /gateway/postgresql-privileges-reference/

faqs:
  - q: How does {{site.base_gateway}} know which PostgreSQL node is the primary?
    a: |
      {{site.base_gateway}} connects to a node and runs `SHOW transaction_read_only`.
      When the result is `off`, the node accepts writes and {{site.base_gateway}} starts using the datastore.
      The order of the list doesn't decide which node is the primary.
  - q: What happens when {{site.base_gateway}} starts and the first node in `pg_host` is down?
    a: |
      If the first node is down, {{site.base_gateway}} tries the next node.
      Each node gets the full `pg_timeout` period.
  - q: Does {{site.base_gateway}} check for the primary on every query?
    a: |
      No, {{site.base_gateway}} checks each new connection for the primary.
      It checks pooled connections only after a failure, until one connection succeeds.
  - q: Can I use `host:port` in `pg_host` with only one node?
    a: |
      Yes, if `pg_host` contains a single entry, {{site.base_gateway}} uses it and doesn't check whether the node is a primary.
  - q: Does {{site.base_gateway}} spread reads across standbys?
    a: |
      No, {{site.base_gateway}} doesn't load-balance across PostgreSQL nodes.
      To send read-only queries to other nodes, use `pg_ro_host`.
  - q: Does multi-host failover work with AWS IAM, Azure, GCP, or OAuth authentication?
    a: |
      Yes, {{site.base_gateway}} gets a token for each node.
---

{{site.base_gateway}} accepts a list of PostgreSQL nodes in [`pg_host`](/gateway/configuration/#pg-host).
With a list, {{site.base_gateway}} connects to a node that accepts writes, and finds the new primary when the primary moves.
This works without a virtual IP (VIP), a load balancer, or a reload.

{% include_cached gateway/postgresql-multi-host-scope.md %}

To set up a cluster with multiple PostgreSQL nodes, see [Use {{site.base_gateway}} with a PostgreSQL cluster without a VIP](/how-to/use-kong-with-a-postgres-cluster-without-a-vip/).

## Host list format

[`pg_host`](/gateway/configuration/#pg-host) accepts a comma-separated list of nodes, with an optional port for each entry.
{{site.base_gateway}} doesn't start when an entry is empty, has an invalid port, or has an invalid format.
The error starts with `invalid pg_host`.

A list with one node keeps the existing behavior.
Only a list with more than one node adds the check for the primary.

## How {{site.base_gateway}} finds the primary

{{site.base_gateway}} tries the nodes in list order, and starts again from the first node at the end of the list.
Each worker starts from the last node that worked, so when nothing fails, {{site.base_gateway}} tries only one node.

For each new connection, {{site.base_gateway}} runs `SHOW transaction_read_only`:
* When the result is `off`, the node is the primary and {{site.base_gateway}} uses it.
* When the result is `on`, the node is a standby. {{site.base_gateway}} closes the connection and tries the next node.
* When a node fails to connect, {{site.base_gateway}} tries the next node.

A node that an operator set to read-only with `default_transaction_read_only` also returns `on`, so {{site.base_gateway}} treats it as a standby.

While everything is working, {{site.base_gateway}} doesn't check connections that it reuses from the pool.
After a node fails, or after a query on the read-write connection fails, {{site.base_gateway}} checks pooled connections until one connection succeeds.
Each node has its own connection pool, and [`pg_pool_size`](/gateway/configuration/#pg-pool-size) and [`pg_backlog`](/gateway/configuration/#pg-backlog) apply to each pool.

## Timeouts

[`pg_timeout`](/gateway/configuration/#pg-timeout) applies to each node.
Each node gets a full `pg_timeout`, so a slow or unreachable node doesn't shorten the wait for the primary.
When nodes are down, the time to find the primary can be up to the number of nodes multiplied by `pg_timeout`.

A slow node can take longer than `pg_timeout` in total, because the timeout applies to each network operation of a connection attempt:
* The TCP connection
* TLS
* Startup
* Authentication
* The primary check

Each worker finds the primary independently, so after a start or a switchover each worker tries the nodes itself.
If the first node in the list drops packets, the first connection of each worker waits up to `pg_timeout`.

If you set [`pg_max_concurrent_queries`](/gateway/configuration/#pg-max-concurrent-queries), other queries in the same worker wait during that search.
Once a query finds the primary, the waiting queries start from the primary.

To shorten the worst case, set a lower `pg_timeout`.

## Read-only connection

[`pg_ro_host`](/gateway/configuration/#pg-ro-host) accepts a list in the [same format as `pg_host`](#host-list-format).
For the read-only connection, {{site.base_gateway}} accepts any node that it can connect to, primary or standby.
{{site.base_gateway}} doesn't give standbys priority, so a read-only query can run on the primary.

## Logs

{{site.base_gateway}} produces the following messages for multi-host PostgreSQL deployments:

<!--vale off-->
{% table %}
columns:
  - title: Event
    key: event
  - title: Level
    key: level
  - title: Message
    key: message
rows:
  - event: A worker makes its first connection.
    level: "`info`"
    message: "`connected to PostgreSQL host pg1:5432`"
  - event: A worker moves to a different node.
    level: "`notice`"
    message: "`connected to PostgreSQL host pg2:5432 (previous host: pg1:5432)`"
{% endtable %}
<!--vale on-->

The `notice` entry appears at the default [`log_level`](/gateway/configuration/#log-level).
To see the `info` entry, set `log_level` to `info` or `debug`.

## Limitations and failure modes

The following table describes situations where multi-host failover behaves in a way you might not expect:

<!--vale off-->
{% table %}
columns:
  - title: Situation
    key: situation
  - title: Behavior
    key: behavior
rows:
  - situation: All nodes are unreachable or read-only.
    behavior: |
      The operation that needs the database fails with `failed to connect to any PostgreSQL host`, followed by the cause for each node, for example `(pg1:5432: timeout; pg2:5432: server is read-only (not the primary))`.
      <br><br>
      The Admin API logs this message at `error` and returns a generic `500` response.
      If this happens at startup, {{site.base_gateway}} fails to start.
  - situation: A query is in progress during a switchover.
    behavior: |
      PostgreSQL closes the sessions on the old primary, so the queries in progress on those sessions fail.
      {{site.base_gateway}} doesn't retry them, because a retry can run a write twice.
      The next query connects to the new primary.
      An Admin API client can retry the request.
  - situation: Two nodes accept writes at the same time (split brain).
    behavior: |
      {{site.base_gateway}} can't detect split brain.
      It uses the first primary that it finds.
      The database cluster manager must prevent split brain.
  - situation: The cluster uses asynchronous replication.
    behavior: |
      If the old primary didn't replicate a write before the failover, the write is lost. 
      This includes rows that other nodes use to invalidate cache entries, so some entries can stay stale.
  - situation: The old primary stays up as a read-only node without a restart.
    behavior: |
      The first write on a pooled connection fails in each worker.
      The failure makes {{site.base_gateway}} check pooled connections, so the next query uses a connection to the new primary.
  - situation: A firewall or NAT drops idle connections silently.
    behavior: |
      Each dead pooled connection makes one request time out, as with one node.
      Set [`pg_keepalive_timeout`](/gateway/configuration/#pg-keepalive-timeout) lower than the idle timeout of your network devices, so that {{site.base_gateway}} closes idle pooled connections before the devices drop them.
  - situation: A DNS name resolves to many addresses.
    behavior: |
      {{site.base_gateway}} treats the name as one node, and doesn't try each address.
      List each node as a separate entry.
  - situation: You want to balance load or rank nodes.
    behavior: |
      {{site.base_gateway}} doesn't balance load, weight, or reorder nodes.
      It uses the first primary that it finds.
{% endtable %}
<!--vale on-->
