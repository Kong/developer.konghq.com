---
title: "Traditional mode"
content_type: reference
layout: reference
breadcrumbs: 
  - /gateway/deployment-topologies/
products:
    - gateway

works_on:
    - on-prem
    - konnect

tags:
    - deployment-topologies
    - traditional-mode
    - clustering

no_version: true

description: "Explains how {{site.base_gateway}} clustering and caching works in traditional mode."

related_resources:
  - text: Load balancing
    url: /gateway/traffic-control/load-balancing-reference/
  - text: Deployment topologies
    url: /gateway/deployment-topologies/
  - text: Data Plane hosting options
    url: /gateway/topology-hosting-options/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/
  - text: DB-less mode
    url: /gateway/db-less-mode/
---

In a traditional deployment, you run {{site.base_gateway}} nodes in clusters. A {{site.base_gateway}} cluster allows you to scale the system horizontally by adding more
machines to handle more incoming requests. They will all share the same
configuration since they point to the same database. {{site.base_gateway}} nodes pointing to the
**same datastore** will be part of the same {{site.base_gateway}} cluster.

You need a [load balancer](/gateway/traffic-control/load-balancing-reference/) in front of your {{site.base_gateway}} cluster to distribute traffic
across your available nodes.

<!--vale off -->
{% mermaid %}
flowchart TD

A[(Database)]
B(<img src="/assets/icons/gateway.svg" style="max-height:20px" class="no-image-expand"/> {{site.base_gateway}} instance)
C(<img src="/assets/icons/gateway.svg" style="max-height:20px" class="no-image-expand"/> {{site.base_gateway}} instance)
D(<img src="/assets/icons/gateway.svg" style="max-height:20px" class="no-image-expand"/> {{site.base_gateway}} instance)

A <---> B & C & D

{% endmermaid %}
<!-- vale on-->

> _Figure 1: In a traditional deployment, all {{site.base_gateway}} nodes connect to the database. 
Each node manages its own configuration._

## About {{site.base_gateway}} clusters

Data Plane nodes in the same {{site.base_gateway}} cluster share the same configuration.

To load balance traffic across Data Plane nodes in a cluster, configure a [load balancer](/gateway/load-balancing/) in front of your nodes to distribute the traffic. 

For performance reasons, {{site.base_gateway}} avoids database connections when proxying
requests, and caches the contents of your database in memory. The cached
[entities](/gateway/entities/) include Gateway Services, Routes, Consumers, plugins, credentials, and so on. Since those
values are stored in memory, any change made via the Admin API of one of the nodes
must be propagated to the other nodes.

## Single node clusters

A single {{site.base_gateway}} node connected to a [supported database](/gateway/configuration/#database) creates a
{{site.base_gateway}} cluster of one node. Any changes applied via the [Admin API](/api/gateway/admin-ee/#/operations/) of this node
will instantly take effect.

For example, consider a single {{site.base_gateway}} node `A`. If we delete a previously registered Service, then any subsequent request to `A` would instantly return `404 Not Found`, as
the node purged it from its local cache.

## Multiple node clusters

In a cluster of multiple {{site.base_gateway}} nodes, other nodes connected to the same database
wouldn't be instantly notified that the Service was deleted by node `A`.  While
the Service is **not** in the database anymore (it was deleted by node `A`), it is
**still** in node `B`'s memory.

All nodes perform a periodic background job to synchronize with changes that
may have been triggered by other nodes. The frequency of this job can be
configured using the [`db_update_frequency`](/gateway/configuration/#db-update-frequency) parameter in `kong.conf`.

Every `db_update_frequency` seconds, all running {{site.base_gateway}} nodes will poll the
database for any update, and will purge the relevant entities from their cache
if necessary.

If we delete a Service from node `A`, this change will not be effective in node
`B` until node `B`'s next database poll, which will occur up to
`db_update_frequency` seconds later (though it could happen sooner).

This makes {{site.base_gateway}} clusters **eventually consistent**.

## Using read-only replicas when deploying {{site.base_gateway}} clusters with PostgresSQL

When using PostgreSQL as the backend storage, you can optionally enable
{{site.base_gateway}} to serve read queries from a separate database instance.

Enabling the read-only connection support in {{site.base_gateway}}
greatly reduces the load on the main database instance since read-only
queries are no longer sent to it.

To learn more about how to configure this feature, refer to the
[Datastore section](/gateway/configuration/#datastore-section)
of the {{site.base_gateway}} configuration reference.

## What information is cached?

For performance reasons, {{site.base_gateway}} avoids database connections when proxying
requests, and caches the contents of your database in memory. All [Gateway entities](/gateway/entities/) are cached.

Since these values are stored in memory, any change made via the [Admin API](/api/gateway/admin-ee/#/operations/) of one of the nodes must be propagated to the other nodes.

Additionally, {{site.base_gateway}} also caches **database misses**. This means that if you
configure a Service with no plugin, {{site.base_gateway}} will cache this information. 

All CRUD operations trigger cache invalidations. Creation
(`POST`, `PUT`) will invalidate cached database misses, and update/deletion
(`PATCH`, `DELETE`) will invalidate cached database hits.

## Configure database caching

Using parameters in `kong.conf`, you can configure where {{site.base_gateway}} nodes stand on the performance versus consistency trade-off.

{{site.base_gateway}} comes with default values tuned for consistency so that you can
experiment with its clustering capabilities while avoiding surprises. As you
prepare a production setup, you should consider tuning those values to ensure
that your performance constraints are respected.

<!--vale off-->
{% kong_config_table %}
config:
  - name: db_update_frequency
  - name: db_update_propagation
  - name: db_cache_ttl
{% endkong_config_table %}
<!--vale on-->

## Interacting with the cache via the Admin API

If you want to investigate the cached values, or manually
invalidate a value cached by {{site.base_gateway}} (a cached hit or miss), you can do so via the
Admin API `/cache` endpoint.


* Inspect a cached value: [`/cache/{key}`](/api/gateway/admin-ee/#/operations/getCacheByKey)
* Purge a cached value: [`/cache/{cache_key}`](/api/gateway/admin-ee/#/operations/deleteCacheByKey)
* Purge a node's cache: [`/cache`](/api/gateway/admin-ee/#/operations/purgeAllCache)
  
  {:.info}
  > **Note**: Be wary of using this endpoint on a node running in production with warm cache.
  > If the node is receiving a lot of traffic, purging its cache at the same time
  > will trigger many requests to your database, and could cause a
  > [cache stampede](https://en.wikipedia.org/wiki/Cache_stampede).
