---
title: "Configure an AWS managed cache for a Dedicated Cloud Gateway control plane"
content_type: how_to
permalink: /dedicated-cloud-gateways/aws-managed-cache-control-plane/
breadcrumbs:
  - /dedicated-cloud-gateways/ 
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I configure an AWS managed cache for my Dedicated Cloud Gateway control plane group?
  a: |
    After your Dedicated Cloud Gateway AWS network is ready, send a `POST` request to the `/cloud-gateways/add-ons` endpoint to create your AWS managed cache. {{site.konnect_short_name}} will automatically create a Redis partial for you for control plane managed caches. [Use the Redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) in a Redis-backed plugin, specifying the {{site.konnect_short_name}} managed cache as the shared Redis configuration (for example: `konnect-managed-a188516a-b1a6-4fad-9eda-f9b1be1b7159`).
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

## Set up an AWS managed cache on a single control plane

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
       name: aws-managed-cache
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

For control plane managed caches, you don't need to manually configure a Redis partial. After the managed cache is ready, {{site.konnect_short_name}} automatically creates a [Redis partial](/gateway/entities/partial/) configuration for you. [Use the redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) to setup Redis-supported plugins by selecting the automatically created {{site.konnect_short_name}}-managed Redis configuration. You can’t use the Redis partial configuration in custom plugins. Instead, use env referenceable fields directly.

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
      "name": "konnect-managed-a188516a-b1a6-4fad-9eda-f9b1be1b7159",
      "path": "config.redis"
    }
  ]
```
{:.no-copy-code}
