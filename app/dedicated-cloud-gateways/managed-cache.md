---
title: "Managed cache for Redis"
content_type: reference
layout: reference
description: "Learn how to configure and scale a Dedicated Cloud Gateway managed cache for Redis. See recommended sizing configurations based on use case."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect
min_version:
  gateway: '3.13'

related_resources:
  - text: Dedicated Cloud Gateways reference
    url: /dedicated-cloud-gateways/reference/
  - text: Configure an AWS managed cache for a Dedicated Cloud Gateway control plane
    url: /dedicated-cloud-gateways/aws-managed-cache-control-plane/
  - text: Configure an Azure managed cache for a Dedicated Cloud Gateway control plane
    url: /dedicated-cloud-gateways/azure-managed-cache-control-plane/
next_steps:
  - text: Configure an AWS managed cache for a Dedicated Cloud Gateway control plane
    url: /dedicated-cloud-gateways/aws-managed-cache-control-plane/
  - text: Configure an Azure managed cache for a Dedicated Cloud Gateway control plane
    url: /dedicated-cloud-gateways/azure-managed-cache-control-plane/
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
tags:
  - dedicated-cloud-gateways
---

{:.success}
> **Getting started with managed cache?**<br>
> For complete tutorials, see the following:
> * [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane](/dedicated-cloud-gateways/aws-managed-cache-control-plane/)
> * [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane group](/dedicated-cloud-gateways/aws-managed-cache-control-plane-group/)
> * [Configure an Azure managed cache for a Dedicated Cloud Gateway control plane](/dedicated-cloud-gateways/azure-managed-cache-control-plane/)
> * [Configure an Azure managed cache for a Dedicated Cloud Gateway control plane group](/dedicated-cloud-gateways/azure-managed-cache-control-plane-group/)

{% include_cached /sections/managed-cache-intro.md %}
Only AWS and Azure are supported as providers currently.

## Managed cache sizing recommendations

You can choose from the following cache sizes:
<!--vale off-->
* micro: ~0.5 GiB capacity
* small: ~1 GiB capacity
* medium: ~3 GiB capacity
* large: ~6 GiB capacity
* xlarge: ~12 GiB capacity
* 2xlarge: ~25 GiB capacity
* 4xlarge: ~52 GiB capacity
* 8xlarge: ~100 GiB capacity
* 12xlarge: ~150 GiB capacity
* 16xlarge: ~200 GiB capacity
* 24xlarge: ~300 GiB capacity
<!--vale on-->
{:.info}
> **Contact Kong to enable cache tiers**
>
> The managed cache size must be enabled on your account.
> Contact your Kong support team to enable a specific cache size before you create or upgrade one.

For capacity planning, you should size workloads assuming approximately 70–75% of total managed cache memory is usable for cache data. 
A portion of each managed cache instance, approximately 25%, is reserved by the platform to maintain performance and reliability. 
This headroom is used for operational needs such as replication, failover, and memory management, so the usable cache capacity will be less than the total provisioned size.

To determine which cache size is the correct fit, you'll need to know the number of Redis keys (and thus the cache pressure).
This is driven by the following equation:

**Key count ≈ Unique Consumers × Unique Routes × Rate limit windows × Kong data plane nodes**

For example, if you have 5,000 Consumers, 3,000 Routes, and 3 windows, this produces a theoretical key space of **45 million counters** per window cycle, each needing a periodic sync to Redis. 
The sync rate determines how aggressively these counters are pushed, and the cache instance must absorb both the read (fetch counters) and write (push diffs) load.

The following table describes which cache size you should use based on your entity count (Consumers and Routes), rate limit windows, and target RPS:

<!--vale off-->
{% table %}
columns:
  - title: Deployment profile
    key: profile
  - title: Entities (Consumers × Routes × Windows)
    key: entities
  - title: Target RPS
    key: rps
  - title: Recommended minimum instance
    key: instance
  - title: Recommended sync rate
    key: sync
  - title: Notes
    key: notes
rows:
  - profile: Small/Dev/Test
    entities: "≤100 × ≤100 × 1 window"
    rps: "≤1,000"
    instance: "`cache.t3.small`"
    sync: "0.5"
    notes: Micro fails at 10K RPS. Small handles 1K RPS baseline cleanly.
  - profile: Standard enterprise
    entities: "≤1,000 × ≤100 × 3 windows"
    rps: "≤10,000"
    instance: "`cache.t3.medium`"
    sync: "0.5"
    notes: "--"
  - profile: Large enterprise
    entities: "≤5,000 × ≤3,000 × 3 windows"
    rps: "≤10,000"
    instance: "`cache.m5.xlarge`"
    sync: "0.5–1.0"
    notes: Large instances are overwhelmed at 0.1 sync rate with this entity count. xLarge provides headroom.
  - profile: High-scale enterprise
    entities: "≤5,000 × ≤3,000 × 3 windows"
    rps: "≤20,000"
    instance: "`cache.m5.2xlarge`"
    sync: "0.5–1.0"
    notes: "--"
  - profile: Ultra-high-scale
    entities: ">5,000 × >3,000 × 3 windows"
    rps: "≤65,000"
    instance: "`cache.m5.4xlarge`"
    sync: "0.5"
    notes: At this tier, it's critical that the base RPS you configured for the Dedicated Cloud Gateway is accurate to your production traffic.
{% endtable %}
<!--vale on-->

### Sync rate recommendations

The sync rate is the most impactful tuning lever and interacts directly with cache sizing:
<!--vale off-->
{% table %}
columns:
  - title: Sync rate
    key: sync_rate
  - title: Syncs per second
    key: syncs_per_sec
  - title: Notes
    key: notes
rows:
  - sync_rate: "0.1"
    syncs_per_sec: "10"
    notes: |
      Highest Redis command load. 
      Only viable on `cache.m5.xlarge` or larger when entity counts exceed 1,000 Consumers. 
      On smaller instances, it causes cache CPU saturation, Redis timeout cascades, and data plane node restarts.
      Only use this when sub-second rate limiting accuracy is business-critical.
      If you must use sync rate 0.1 for accuracy, size up the cache by at least one tier beyond what the entity count alone would suggest. 
      If you can tolerate sync rate 0.5, you can use a smaller cache instance.
  - sync_rate: "0.5"
    syncs_per_sec: "2"
    notes: |
      Recommended default for production.
      Best balance of accuracy and resource efficiency. 
      Stable across all instance types for standard workloads. 
      For high-entity deployments, this works well on `cache.m5.large` and above.
  - sync_rate: "1.0"
    syncs_per_sec: "1"
    notes: |
      Lowest Redis load, but introduces rate-limiting accuracy degradation.
      At high entity counts, the rate limited percentage drops to 57–60% (expected: ~99%), which allows requests through that should be blocked. 
      Only use for non-critical or approximate rate limiting at very low entity counts.
{% endtable %}
<!--vale on-->
## Configure a managed cache

Managed caches are either created at the control plane or control plane group-level. 

{% navtabs "managed-cache" %}
{% navtab "Control plane" %}
1. List your existing Dedicated Cloud Gateway control planes:
{% capture list_cp %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bcloud_gateway%5D=true
status_code: 201
method: GET
region: global
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ list_cp | indent: 3}}

1. Copy and export the control plane you want to configure the managed cache for:
   ```sh
   export CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
   ```

1. Create a managed cache using the Cloud Gateways add-ons API:

   {% capture create_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons
   status_code: 201
   method: POST
   region: global
   body:
       name: managed-cache
       owner:
           kind: control-plane
           control_plane_id: $CONTROL_PLANE_ID
           control_plane_geo: us
       config:
           kind: managed-cache.v0
           capacity_config:
               kind: tiered
               tier: small
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_addon | indent: 3}}

   When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates. All regions are supported and you can configure the managed cache for multiple regions.

1. Export the ID of your managed cache from the response:
   ```sh
   export MANAGED_CACHE_ID='YOUR MANAGED CACHE ID'
   ```

1. Check the status of the managed cache. Once it's marked as ready, it indicates the cache is ready to use:

   {% capture get_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons/$MANAGED_CACHE_ID
   status_code: 200
   method: GET
   region: global
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ get_addon | indent: 3}}

   This can take about 15 minutes. 

For control plane managed caches, you don't need to manually configure a Redis partial. 
After the managed cache is ready, {{site.konnect_short_name}} automatically creates a [Redis partial](/gateway/entities/partial/) configuration for you. 
[Use the Redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) to set up Redis-supported plugins by selecting the automatically created {{site.konnect_short_name}}-managed Redis configuration. 
You can’t use the Redis partial configuration in custom plugins. Instead, use env referenceable fields directly.
{% endnavtab %}
{% navtab "Control plane group" %}

{% include /gateway/dcgw-cpg-note.md %}

1. Create a managed cache using the Cloud Gateways [add-ons API](/api/konnect/cloud-gateways/v2/#/operations/create-add-on):

   {% capture create_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons
   status_code: 201
   method: POST
   region: global
   body:
       name: managed-cache
       owner:
           kind: control-plane-group
           control_plane_group_id: $CONTROL_PLANE_GROUP_ID
           control_plane_group_geo: us
       config:
           kind: managed-cache.v0
           capacity_config:
               kind: tiered
               tier: small
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_addon | indent: 3}}

   When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates. All regions are supported and you can configure the managed cache for multiple regions.

1. Export the ID of your managed cache from the response:
   ```sh
   export MANAGED_CACHE_ID='YOUR MANAGED CACHE ID'
   ```

1. [Check the status of the managed cache](/api/konnect/cloud-gateways/v2/#/operations/get-add-on). Once it's marked as ready, it indicates the cache is ready to use:

   {% capture get_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons/$MANAGED_CACHE_ID
   status_code: 200
   method: GET
   region: global
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ get_addon | indent: 3}}

   This can take about 15 minutes. 
1. Create a Redis partial configuration. The following example is for AWS:

{% capture create_redis_partial %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/partials
status_code: 201
method: POST
region: us
body:
  name: konnect-managed
  type: redis-ee
  config:
    cloud_authentication:
      auth_provider: "{vault://env/ADDON_MANAGED_CACHE_AUTH_PROVIDER}"
      aws_cache_name: "{vault://env/ADDON_MANAGED_CACHE_AWS_CACHE_NAME}"
      aws_region: "{vault://env/ADDON_MANAGED_CACHE_AWS_REGION}"
      aws_is_serverless: false
      aws_assume_role_arn: "{vault://env/ADDON_MANAGED_CACHE_AWS_ASSUME_ROLE_ARN}"
    connect_timeout: 2000
    connection_is_proxied: false
    database: 0
    host: "{vault://env/ADDON_MANAGED_CACHE_HOST}"
    keepalive_backlog: 512
    keepalive_pool_size: 256
    port: "{vault://env/ADDON_MANAGED_CACHE_PORT}"
    read_timeout: 5000
    send_timeout: 2000
    server_name: "{vault://env/ADDON_MANAGED_CACHE_SERVER_NAME}"
    ssl_verify: true
    ssl: true
    username: "{vault://env/ADDON_MANAGED_CACHE_USERNAME}"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create_redis_partial | indent: 3 }}
1. Repeat the previous step for all the control planes in your control plane group.

You can apply the managed cache to any Redis-backed plugin by selecting the {{site.konnect_short_name}} partial for the shared Redis configuration.
{% endnavtab %}
{% endnavtabs %}

## Resize a managed cache

{:.danger}
> **Managed caches cannot be downsized**
>
> You can only upgrade the size of a managed cache, you can't downsize one. 
> If you want to downsize a cache, you must delete and recreate it.

Before you resize a managed cache, consider the following:
* Caches are resized immediately.
* Schedule cache resizes during low traffic hours.
* How long a cache resize takes depends on your cloud service provider.
  For more information, see [Scaling replica nodes for Valkey or Redis OSS (Cluster Mode Disabled)](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Scaling.RedisReplGrps.html#Scaling.RedisReplGrps.ScaleUp) and [Scale an Azure Managed Redis instance](https://learn.microsoft.com/en-us/azure/redis/how-to-scale#how-long-does-scaling-take).

You can resize a managed cache sending a PATCH request to the [`/cloud-gateways/add-ons/{addOnId}` endpoint](/api/konnect/cloud-gateways/v2/#/operations/update-add-on):

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/add-ons/$ADD_ON_ID
status_code: 200
method: PATCH
region: global
body:
  config:
    kind: managed-cache.v0
    capacity_config:
      kind: tiered
      tier: large
{% endkonnect_api_request %}
<!--vale on-->