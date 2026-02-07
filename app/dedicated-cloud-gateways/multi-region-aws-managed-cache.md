---
title: "Multi-region AWS managed cache"
content_type: reference
layout: reference
description: | 
    Configure a built-in Redis-compatible datastore that powers all Redis-enabled plugins across Dedicated Cloud Gateway AWS deployments.
beta: true
tools:
  - deck
products:
    - gateway
works_on:
    - konnect
min_version:
  gateway: '3.13'
breadcrumbs:
  - /dedicated-cloud-gateways/

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/

tags:
  - aws
---

Dedicated Cloud Gateway (DCGW) Managed Cache introduces a built-in Redis-compatible datastore that powers all Redis-enabled plugins across {{site.base_gateway}} deployments. This enhancement enables seamless activation and operation of performance-critical, redis-backed plugins, including Proxy Caching, Rate Limiting, AI Rate Limiting, ACME, and more. This fully-managed Redis service is provisioned and operated by Kong, removing the need for you to host Redis infrastructure.

You can configure AWS managed caches for control planes and control plane groups. When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates. 

## How managed cache works
* Control planes (not in a control plane group)
  When the managed cache is ready, Konnect automatically creates a Redis partial configuration. This configuration appears as Konnect Managed in Redis-enabled plugin configuration fields and can be selected directly.
* Control plane groups
  You must manually create and apply a Redis partial configuration on each control plane where Redis-backed plugins are used. The managed cache provides the required environment variables, but the Redis partial is not created automatically.

The API calls for creating and managing the managed cache apply to both flows. Manual Redis configuration is required only when you are using a control plane group.

## Limitations

* This feature is enabled only for Gateways with 3.13 or later.
* AWS is the only provider supported currently. All regions within AWS are supported.
* You can’t use redis configuration in custom plugins. Use env referenceable fields directly.

## Set up an AWS managed cache

Choose one of the following configurations:
* Control plane group
	1.	Create a control plane group enabled for dedicated cloud gateways.
	1.	Add AWS multi-region data plane groups to the control plane group.
	1.	Add control planes to the control plane group.
* Single control plane
	1.	Create or use an existing control plane enabled for dedicated cloud gateways.

1. Create a managed cache using the Cloud Gateways add-ons API. This step is required for both control planes and control plane groups:

   {% capture create_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons
   status_code: 201
   method: POST
   region: global
   body:
       name: my-add-on
       owner:
           kind: control-plane-group
           control_plane_group_id: 71e52a7e-06ae-43b1-a350-d38df65f8654
           control_plane_group_geo: eu
       config:
           kind: managed-cache.v0
           capacity_config:
               kind: tiered
               tier: small
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_addon | indent: 3}}

   When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates.

1. Check the status of the managed cache. Once its marked as ready, it indicates the cache is ready to use:

   {% capture get_addon %}
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons/{addOnId}
   status_code: 200
   method: GET
   region: global
   {% endkonnect_api_request %}
   {% endcapture %}
   {{ get_addon | indent: 3}}

## Configure Redis for plugins:

* **Control planes:** No manual Redis configuration is required. After the managed cache is ready, Konnect automatically creates a Redis partial configuration. When configuring Redis-backed plugins, select Konnect Managed in the Redis configuration field.
* **Control plane groups:** For control plane groups, you must manually create a Redis partial configuration on each control plane where Redis-backed plugins are enabled.

1. Apply a Redis partial configuration using decK:

{% capture redis_config %}
{% entity_examples %}
entities:
  partial:
    - name: test-partial
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
{% endentity_examples %}
{% endcapture %}
{{ redis_config | indent: 3}}

1. [Use the redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) to setup plugins.
   
   Use the managed Redis configuration when setting up Redis-backed plugins:
   * For control planes, select the automatically created Konnect Managed Redis configuration.
   * For control plane groups, reference the Redis partial configuration you created.

   Repeat this setup on other control planes in the control plane group as needed.
 
1. Set up redis configuration and plugins on other CPs in that CPG as needed.
   
   You can add more data plane groups to the CPG or remove existing data plane groups. The cache is automatically updated accordingly. You can check the managed cache's ready status to make sure managed cache is up-to-date.
