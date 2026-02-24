---
title: "Configure an AWS managed cache for a Dedicated Cloud Gateway control plane group"
content_type: how_to
permalink: /dedicated-cloud-gateways/aws-managed-cache-control-plane-group/
breadcrumbs:
  - /dedicated-cloud-gateways/ 
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I configure an AWS managed cache for my Dedicated Cloud Gateway control plane?
  a: |
    After your Dedicated Cloud Gateway AWS network is ready, send a `POST` request to the `/cloud-gateways/add-ons` endpoint to create your AWS managed cache. {{site.konnect_short_name}} will automatically create a Redis partial for you for control plane managed caches. [Use the Redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) in a Redis-backed plugin, specifying the {{site.konnect_short_name}} managed cache as the shared Redis configuration (for example: `konnect-managed`).
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Partials
    url: /gateway/entities/partial/
min_version:
  gateway: '3.13'
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways
      icon_url: /assets/icons/kogo-white.svg
    
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---

An AWS managed cache for Dedicated Cloud Gateways is a Redis-compatible datastore that powers all Redis-enabled plugins. This is fully-managed by Kong in the regions of your choice, so you don't have to host Redis infrastructure. Managed cache allows you get up and running faster with [Redis-backed plugins](/gateway/entities/partial/#use-partials), such as Proxy Caching, Rate Limiting, AI Rate Limiting, and ACME. 

## Set up an AWS managed cache on a control plane group

### Create a hybrid control plane

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click **New**.
1. Select **New API gateway**.
1. Select **Self-managed**.
1. Select **Docker**.
1. In the **Gateway name** field, enter `hybrid-cp`.
1. Click **Create**.
1. Scroll and click **Set up later**.

### Create a Dedicated Cloud control plane group

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click **New**.
1. Select **New control plane group**.
1. In the **Name** field, enter `dcgw-control-plane-group`.
1. From the **Control Planes** dropdown menu, select `hybrid-cp`. 
1. For the Node Type, select **Dedicated Cloud**.
1. Click **Save**.
1. Click **Configure data plane**.
1. From the **Provider** dropdown menu, select "AWS".
1. From the **Region** dropdown menu, select the region you want to configure the cluster in. 
1. Edit the Network range as needed.
   
   {:.danger}
   > **Important:** Your AWS virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited.
1. From the **Access** dropdown menu, select "Public" or "Private".
1. Click **Create data plane node**.
1. Click **Go to overview**.

   {:.warning}
   > **Important:** Wait until your AWS network displays as `Ready` before proceeding to the next step.

1. Copy and export the control plane group you want to configure the managed cache for:
   ```sh
   export CONTROL_PLANE_GROUP_ID='YOUR CONTROL PLANE GROUP ID'
   ```

### Create a managed cache for your control plane group

1. Create a managed cache using the Cloud Gateways add-ons API:

   {% capture create_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons
   status_code: 201
   method: POST
   region: global
   body:
       name: aws-managed-cache
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

   When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates. All regions in AWS are supported and you can configure the managed cache for multiple regions.

1. Export the ID of your managed cache in the response:
   ```sh
   export MANAGED_CACHE_ID='YOUR MANAGED CACHE ID'
   ```

1. Check the status of the managed cache. Once its marked as ready, it indicates the cache is ready to use:

   {% capture get_addon %}
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons/$MANAGED_CACHE_ID
   status_code: 200
   method: GET
   region: global
   {% endkonnect_api_request %}
   {% endcapture %}
   {{ get_addon | indent: 3}}

   This can take about 15 minutes. 

## Configure Redis for plugins

You must manually create a [Redis partial](/gateway/entities/partial/) configuration on each control plane where Redis-backed plugins are enabled. [Use the redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) to setup Redis-supported plugins by selecting the automatically created {{site.konnect_short_name}}-managed Redis configuration. You can’t use the Redis partial configuration in custom plugins. Instead, use env referenceable fields directly.

### Create a managed cache Redis partial

1. Create a Redis partial configuration:

{% capture create_redis_partial %}
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
{% endcapture %}
{{ create_redis_partial | indent: 3 }}
1. Repeat the previous step for all the control planes in your control plane group.

### Apply the managed cache Redis partial to a plugin

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click your Dedicated Cloud Gateway.
1. In the API Gateway sidebar, click **Plugins**.
1. Click **New plugin**.
1. Select **Rate Limiting Advanced**.
1. In the **Rate Limit Window Type** fields, enter `100` and `3600`. 
1. Click **View advanced parameters**.
1. In the **Strategy** dropdown menu, select "redis".
1. In the **Shared Redis Configuration** dropdown menu, select your {{site.konnect_short_name}}-managed configuration. For example: `konnect-managed-a188516a-b1a6-4fad-9eda-f9b1be1b7159`
1. In the **Sync Rate** field, enter `0`.
1. Click **Save**.
1. Repeat steps 1 - 11 for each control plane in your control plane group.
   
   You can add more data plane groups to the control plane group or remove existing data plane groups. The cache is automatically updated accordingly. You can check the managed cache's ready status to make sure the managed cache is up-to-date.

{:.warning}
> **Important:** If you're configuring your plugins with decK, you must include the `konnect-managed` partial [default lookup tag](/deck/gateway/tags/) to ensure the managed cache partial is available. Add the following to your plugin config file:
```yaml
_info:
default_lookup_tags:
  partials:
    - konnect-managed
```

## Validate

Verify that the Rate Limiting Advanced plugin is using the managed cache partial configuration:
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins
status_code: 200
method: GET
region: global
{% endkonnect_api_request %}

In the response, locate your `rate-limiting-advanced` plugin and confirm that `config.strategy` is set to `redis` and that the partials array contains your managed Redis partial:

```sh
"partials": [
    {
      "id": "dcf411a3-475b-4212-bdf8-ae2b4dfa0a04",
      "name": "konnect-managed",
      "path": "config.redis"
    }
  ]
```
{:.no-copy-code}
