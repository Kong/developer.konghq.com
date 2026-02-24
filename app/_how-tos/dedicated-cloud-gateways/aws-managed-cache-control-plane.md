---
title: "Configure an AWS managed cache for Dedicated Cloud Gateways control plane"
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
  q: How do I configure ?
  a: |
    placeholder 
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
min_version:
  gateway: '3.13'
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways
      icon_url: /assets/icons/kogo-white.svg
    - title: "AWS"
      content: |
        You need an AWS IAM user account with permissions to create AWS Resource Configuration Groups, Resource Gateways, and to use AWS Resource Access Manager (RAM).

        You also need:
        * A configured [VPC and subnet](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html#create-vpc-and-other-resources)
        * A [resource gateway](https://docs.aws.amazon.com/vpc-lattice/latest/ug/create-resource-gateway.html)
        * A [resource configuration group](https://docs.aws.amazon.com/vpc-lattice/latest/ug/create-resource-configuration.html)
          
          Copy and save the resource configuration ID and resource definition domain name for each resource configuration. {{site.konnect_short_name}} will use these to create a mapping of upstream domain names and resource configuration IDs.  
        
        Export your AWS resource configuration domain name:
        ```sh
        export RESOURCE_DOMAIN_NAME='http://YOUR-RESOURCE-DOMAIN-NAME/anything'
        ```
        We'll use this to connect to our Dedicated Cloud Gateway service.
      icon_url: /assets/icons/aws.svg
    
faqs:
  - q: Which Availability Zones (AZs) does AWS resource endpoints support for Dedicated Cloud Gateway?
    a: |
      Dedicated Cloud Gateways supports [specific Availability Zones (AZs)](/konnect-platform/geos/#dedicated-cloud-gateways) in the supported AWS regions.
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---


Dedicated Cloud Gateway (DCGW) Managed Cache introduces a built-in Redis-compatible datastore that powers all Redis-enabled plugins across {{site.base_gateway}} deployments. This enhancement enables seamless activation and operation of performance-critical, redis-backed plugins, including Proxy Caching, Rate Limiting, AI Rate Limiting, ACME, and more. This fully-managed Redis service is provisioned and operated by Kong, removing the need for you to host Redis infrastructure.

You can configure AWS managed caches for control planes and control plane groups. When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates. 

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

1. Create a managed cache using the Cloud Gateways add-ons API. This step is required for both control planes and control plane groups:

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

   When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates. All regions in AWS are supported.

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

For control planes, no manual Redis configuration is required. After the managed cache is ready, Konnect automatically creates a Redis partial configuration. When configuring Redis-backed plugins, select Konnect Managed in the Redis configuration field.

[Use the redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) to setup Redis-supported plugins. Select the automatically created Konnect Managed Redis configuration.
   
{:.warning}
> **Important:** If you're configuring your plugins with decK, you must include the `konnect-managed` partial [default lookup tag](/deck/gateway/tags/) to ensure the managed cache partial is available. Add the following to your plugin config file:
```yaml
_info:
default_lookup_tags:
  partials:
    - konnect-managed
```

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Plugins**.
1. Click **New plugin**.
1. Select **Rate Limiting Advanced**.
1. Click **View advanced parameters**.
1. In the **Strategy** dropdown menu, select "redis".
1. In the **Shared Redis Configuration** dropdown menu, select your {{site.konnect_short_name}}-managed configuration.
1. Click **Save**.

{:.important}
> **Note:** You can’t use redis configuration in custom plugins. Use env referenceable fields directly.

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
example response here
```
{:.no-copy-code}
