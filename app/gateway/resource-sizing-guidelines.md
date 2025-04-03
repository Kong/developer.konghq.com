---
title: "{{site.base_gateway}} resource sizing guidelines"
content_type: reference
layout: reference

products:
    - gateway

works_on:
    - on-prem

min_version:
    gateway: 3.4.x

tags:
    - performance

breadcrumbs:
    - /gateway

description: "Review Kong's recommended resource allocation sizing guidelines for {{site.base_gateway}} based on configuration and traffic patterns."

related_resources:
  - text: Performance benchmark
    url: /gateway/performance/benchmarks/
  - text: Guidelines for establishing a performance benchmark
    url: /gateway/performance/establish-performance-benchmark/
  - text: Cluster reference
    url: /gateway/cluster/
---

{{site.base_gateway}} is designed to handle large volumes of request
traffic and to proxy requests with minimal latency. This reference offers recommendations on sizing for
resource allocation based on expected {{site.base_gateway}} configuration and
traffic patterns.


## Scaling dimensions

{{site.base_gateway}} measures performance in the following dimensions:

| Performance dimension | Measured in | Performance limited by... | Description |
|-----------------------|-------------|-------------|
| Latency | Microseconds or milliseconds | *Memory-bound*<br>Add more database caching memory to decrease latency | The delay between the downstream client sending a request and receiving a response. Increasing the number of Routes and Plugins in a {{site.base_gateway}} cluster increases the amount of latency that's added to each request. |
| Throughput | Seconds or minutes |*CPU-bound*<br>Scale {{site.base_gateway}} vertically or horizontally to increase throughput | The number of requests that {{site.base_gateway}} can process in a given time span |

When all other factors remain the same, decreasing the latency for
each request increases the maximum throughput in {{site.base_gateway}}. This is because there is less CPU time spent handling each request, and more
CPU available for processing traffic as a whole. {{site.base_gateway}} is
designed to scale horizontally to add more overall compute power for
configurations that add substantial latency into requests, while needing to
meet specific throughput requirements.

Performance benchmarking and optimization as a whole is a complex exercise that
must account for a variety of factors, including those external to
{{site.base_gateway}}, such as the behavior of upstream services, or the health
of the underlying hardware on which {{site.base_gateway}} is running.

## General resource guidelines

These recommendations are a baseline guide only. 
For performance-critical environments, you should conduct specific [tuning or benchmarking efforts](/gateway/performance/establish-performance-benchmark/).

### Hybrid mode with large number of entities {% new_in 3.5 %}

When {{site.base_gateway}} is operating in hybrid mode with a large number of
[entities](/gateway/entities/) (like Routes and Gateway Services), it can benefit from enabling [`dedicated_config_processing`](/gateway/configuration/#dedicated_config_processing).

When enabled, certain CPU-intensive steps of the data plane reconfiguration operation are offloaded
to a dedicated worker process. This reduces proxy latency during reconfigurations at the cost of a
slight increase in memory usage. The benefits of this are most apparent with configurations
of more than 1,000 entities. 


### {{site.base_gateway}} resources

{{site.base_gateway}} is designed to operate in a variety of deployment
environments. It has no minimum system requirements to operate.

Resource requirements vary substantially based on configuration. The following
high-level matrices offer a guideline for determining system requirements
based on overall configuration and performance requirements.

The following table provides rough usage requirement estimates based on simplified examples with latency and throughput requirements on a per-node basis:

| Size | Number of configured entities | Latency requirements | Throughput requirements | Use cases |
|---|---|---|---|---|
| Development | < 100 | < 100 ms | < 500 RPS   | * Dev/test environments<br>* Latency-insensitive gateways |
| Small | < 1000  | < 20 ms  | < 2500 RPS  | * Production clusters<br>* Greenfield traffic deployments |
| Medium | < 10000 | < 10 ms  | < 10000 RPS | * Mission-critical clusters<br>* Legacy and greenfield traffic<br>* Central enterprise-grade gateways |
| Large | < 50000+ | < 10 ms  | < 10000 RPS | * Mission-critical clusters<br>* Legacy and greenfield traffic<br>* Central enterprise-grade gateways |

### Database resources

We do not provide any specific numbers for database sizing because it
depends on your particular setup. Sizing varies based on:
* Traffic
* Number of nodes
* Enabled features
  
  *For example: [Rate limiting](/gateway/rate-limiting/) uses a database or Redis*
* Number and rate of change of entities
* The rate at which {{site.base_gateway}} processes are started and restarted within the cluster
* The size of {{site.base_gateway}}'s [in-memory cache](#in-memory-caching)

{{site.base_gateway}} intentionally relies on the database as little as
possible. To access configuration, {{site.base_gateway}}
only reads configuration from the database when a node first starts or
configuration for a given entity changes.

Everything in the database is meant to be read infrequently and held in memory
as long as possible. Therefore, database resource requirements are lower than
those of compute environments running {{site.base_gateway}}.

Query patterns are typically simple and follow schema indexes. Provision
sufficient database resources in order to handle spiky query patterns.

You can adjust [datastore settings](/gateway/configuration/#datastore-section)
in `kong.conf` to keep database access minimal. If the database is down for maintenance, see the [in-memory caching](#in-memory-caching) section or
[keep {{site.base_gateway}} operational](https://support.konghq.com/support/s/article/Keeping-Kong-Functional-During-DB-Down-Times). If you choose to keep the database
operational during downtime, Vitals data is not written to the
database during this time.

### Cluster resource allocations

Based on the expected size and demand of the [cluster](/gateway/cluster/), we recommend
the following resource allocations as a starting point:

| Size  | CPU  | RAM  | Typical cloud instance sizes |
|---|---|---|---|---|
| Development | 1-2 cores  | 2-4 GB   | **AWS**: t3.medium<br/>**GCP**: n1-standard-1<br/>**Azure**: Standard A1 v2  |
| Small  | 1-2 cores  | 2-4 GB   | **AWS**: t3.medium<br/>**GCP**: n1-standard-1<br/>**Azure**: Standard A1 v2  |
| Medium | 2-4 cores  | 4-8 GB   | **AWS**: m5.large<br/>**GCP**: n1-standard-4<br/>**Azure**: Standard A1 v4  |
| Large  | 8-16 cores | 16-32 GB | **AWS**: c5.xlarge<br/>**GCP**: n1-highcpu-16<br/>**Azure**: F8s v2  |

We strongly discourage using throttled cloud instance types (such as the
AWS `t2` or `t3` series of machines) in large clusters, because CPU throttling is detrimental to {{site.base_gateway}}'s performance. We also recommend
testing and verifying the bandwidth availability for a given instance class.
Bandwidth requirements for {{site.base_gateway}} depend on the shape and volume
of traffic flowing through the cluster.

### In-memory caching

We recommend defining the largest [`mem_cache_size`](/gateway/configuration/#mem_cache_size) possible
while still providing adequate resources to the operating system and any other
processes running adjacent to {{site.base_gateway}}. This configuration allows
{{site.base_gateway}} to take maximum advantage of the in-memory cache, and
reduce the number of trips to the database.

Each {{site.base_gateway}} worker process maintains its own memory allocations,
and must be accounted for when provisioning memory. By default, one worker
process runs per number of available CPU cores. We recommend allocating about 500MB of memory per worker process.

For example, on a machine with 4 CPU cores and 8 GB of RAM available, we recommend allocating between 4-6 GB to cache using `mem_cache_size`, depending on what other processes are running alongside {{site.base_gateway}}.

### Plugin queues

Several {{site.base_gateway}} plugins use internal, in-memory queues to reduce the number of concurrent requests to an upstream server
under high load conditions and provide buffering during temporary network and upstream outages. 

These plugins include:
* [HTTP Log](/plugins/http-log/)
* [OpenTelemetry](/plugins/opentelemetry/)
* [Datadog](/plugins/datadog/)
* [StatsD](/plugins/statsd/)
* [Zipkin](/plugins/zipkin/)

The `queue.max_entries` plugin configuration parameter determines how many entries can be waiting in a given plugin queue. 
The default value of 10,000 for `queue.max_entries` should provide for enough buffering in many installations while keeping 
the maximum memory usage of queues at reasonable levels. 
Once this limit is reached, the oldest entry is removed when a new entry is queued.

For larger configurations, we recommend experimentally determining
the memory requirements of queues by running {{site.base_gateway}} in
a test environment. You can force plugin queues to reach configured limits by observing its memory consumption while plugin
upstream servers are unavailable. Most plugins use one queue per plugin instance, with the exception of
the [HTTP Log](/plugins/http-log/) plugin, which uses one queue per log server upstream
configuration. 

## Next steps

* [Conduct performance benchmark tuning tests](/gateway/performance/establish-performance-benchmark/)
* See {{site.base_gateway}}'s [performance testing benchmark results](/gateway/performance/benchmarks/)