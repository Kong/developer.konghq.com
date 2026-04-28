---
title: "Managed cache for Redis"
content_type: reference
layout: reference
description: "Learn how to configure, scale, and troubleshoot a Dedicated Cloud Gateway managed cache for Redis."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect
min_version:
  gateway: '3.13'

related_resources:
  - text: Dedicated Cloud Gateways 
    url: /dedicated-cloud-gateways/
  - text: Serverless Gateways
    url: /serverless-gateways/
  - text: Private hosted zones
    url: /dedicated-cloud-gateways/private-hosted-zones/
  - text: Outbound DNS resolver
    url: /dedicated-cloud-gateways/outbound-dns-resolver/
next_steps:
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

## Troubleshoot a managed cache