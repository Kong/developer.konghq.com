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
> **Getting started with managed cache?**<br><br>
> For complete tutorials, see the following:
> * [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane](/dedicated-cloud-gateways/aws-managed-cache-control-plane/)
> * [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane group](/dedicated-cloud-gateways/aws-managed-cache-control-plane-group/)
> * [Configure an Azure managed cache for a Dedicated Cloud Gateway control plane](/dedicated-cloud-gateways/azure-managed-cache-control-plane/)
> * [Configure an Azure managed cache for a Dedicated Cloud Gateway control plane group](/dedicated-cloud-gateways/azure-managed-cache-control-plane-group/)

{% include_cached /sections/managed-cache-intro.md %}

Only AWS and Azure are currently supported as providers.

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
> <br><br>
> Specific cache sizes must be enabled on your account.
> Contact your Kong support team to enable a specific cache size before you create or upgrade one.

When sizing workloads, plan for approximately 70–75% of total managed cache memory to be available for cache data.
The platform reserves around 25% of each managed cache instance for operational needs, such as replication, failover, and memory management, so the usable cache capacity will be less than the total provisioned size.

To choose the right cache size, you'll need to know your Redis key count, which determines your cache pressure.
This is driven by the following equation:


For example, if you have 5,000 Consumers, 3,000 Routes, and 3 windows, this produces a theoretical key space of **45 million counters** per window cycle, each needing a periodic sync to Redis. 
The sync rate determines how aggressively these counters are pushed, and the cache instance must absorb both the read (fetch counters) and write (push diffs) load.

The following table describes which cache size you should use based on your entity count (Consumers and Routes), rate limit windows, and target number of requests per second (RPS):

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
      <br><br>
      Only use this when sub-second rate limiting accuracy is business-critical.
      <br><br>
      If you must use sync rate 0.1 for accuracy, size up the cache by at least one tier beyond what the entity count alone would suggest. 
      If you can tolerate sync rate 0.5, you can use a smaller cache instance.
  - sync_rate: "0.5"
    syncs_per_sec: "2"
    notes: |
      **Recommended default for production.**
      Best balance of accuracy and resource efficiency. 
      Stable across all instance types for standard workloads. 
      For high-entity deployments, this works well on `cache.m5.large` and above.
  - sync_rate: "1.0"
    syncs_per_sec: "1"
    notes: |
      Lowest Redis load, but introduces rate limiting accuracy degradation.
      At high entity counts, the rate limited percentage drops to 57–60% (expected: ~99%), which allows requests through that should be blocked. 
      Only use for non-critical or approximate rate limiting at very low entity counts.
{% endtable %}
<!--vale on-->
## Configure a managed cache

Managed caches are either created at the control plane or control plane group-level. 

{% include /gateway/dcgw-cpg-note.md %}

To create a managed cache at the control plane level, do the following:

{% navtabs "managed-cache" %}
{% navtab "API" %}
1. List your existing Dedicated Cloud Gateway control planes:
{% capture list_cp %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bcloud_gateway%5D=true
status_code: 200
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
               tier: micro
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_addon | indent: 3}}

   All regions are supported and you can configure the managed cache for multiple regions.

1. Export the ID of your managed cache from the response:

   ```sh
   export MANAGED_CACHE_ID='YOUR MANAGED CACHE ID'
   ```

1. Check the status of the managed cache. Once the `state` is marked as ready, the cache is ready to use:

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

{% endnavtab %}
{% navtab "Terraform" %}
1. Add the [`konnect_cloud_gateway_addon` resource](https://registry.terraform.io/providers/Kong/konnect/latest/docs/resources/cloud_gateway_addon) to your Terraform configuration:

   ```hcl
   echo '
   resource "konnect_gateway_control_plane" "test_cp" {
     name         = "CGW Control Plane"
     cloud_gateway = true
   }
   resource "konnect_cloud_gateway_addon" "managed_cache" {
     name = "managed-cache"
     owner = {
       control_plane = {
         control_plane_id  = konnect_gateway_control_plane.test_cp.id
         control_plane_geo = "us"
       }
     }
     config = {
       managed_cache = {
         capacity_config = {
           tiered = {
             tier = "micro"
           }
         }
       }
     }
   }
   ' >> main.tf
   ```
   
   All regions are supported and you can configure the managed cache for multiple regions.

1. Apply the configuration:

   ```sh
   terraform apply
   ```

{% endnavtab %}
{% endnavtabs %}

For control plane managed caches, you don't need to manually configure a Redis partial. 
After the managed cache is ready, {{site.konnect_short_name}} automatically creates a [Redis partial](/gateway/entities/partial/) configuration for you. 
[Use the Redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) to set up Redis-supported plugins by selecting the automatically created {{site.konnect_short_name}}-managed Redis configuration. 

{:.info}
> You can’t use the Redis partial configuration in custom plugins. Instead, use env referenceable fields directly.

## Resize a managed cache

{:.danger}
> **Managed caches cannot be downsized**
>
> You can only upgrade the size of a managed cache, you can't downsize one. 
> If you want to downsize a cache, you must delete and recreate it.

Before you resize a managed cache, consider the following:
* Resizes happen immediately.
* Schedule cache resizes during low traffic hours.
* Caches remain online during a resize, but you may experience brief interruptions of a few seconds. 

You can resize a managed cache by sending a PATCH request to the [`/cloud-gateways/add-ons/{addOnId}` endpoint](/api/konnect/cloud-gateways/v2/#/operations/update-add-on):

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/add-ons/$MANAGED_CACHE_ID
status_code: 200
method: PATCH
region: global
body:
  config:
    kind: managed-cache.v0
    capacity_config:
      kind: tiered
      tier: small
{% endkonnect_api_request %}
<!--vale on-->

