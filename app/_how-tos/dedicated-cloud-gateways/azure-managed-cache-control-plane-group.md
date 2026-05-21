---
title: "Configure an Azure managed cache for a Dedicated Cloud Gateway control plane group"
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-managed-cache-control-plane-group/
description: "Learn how to configure an Azure managed cache for a Dedicated Cloud Gateway control plane group."
breadcrumbs:
  - /dedicated-cloud-gateways/ 
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I configure an Azure managed cache for my Dedicated Cloud Gateway control plane group?
  a: |
    After your Dedicated Cloud Gateway Azure network is ready, send a `POST` request to the `/cloud-gateways/add-ons` endpoint to create your Azure managed cache. 
    For control plane groups, you must manually create a Redis partial on each control plane that references the {{site.konnect_short_name}} managed cache. 
    Then [use the Redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) in a Redis-backed plugin, specifying the {{site.konnect_short_name}} managed cache as the shared Redis configuration (for example: `konnect-managed`).
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Managed cache for Redis
    url: /dedicated-cloud-gateways/managed-cache/
  - text: Partials
    url: /gateway/entities/partial/
  - text: Dedicated Cloud Gateways network architecture
    url: /dedicated-cloud-gateways/network-architecture/
  - text: Dedicated Cloud Gateways private network architecture and security
    url: /dedicated-cloud-gateways/private-network/
  - text: Dedicated Cloud Gateways public network architecture and security
    url: /dedicated-cloud-gateways/public-network/
  - text: Multi-cloud Dedicated Cloud Gateway network architecture and security
    url: /dedicated-cloud-gateways/multi-cloud/
min_version:
  gateway: '3.13'
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways
      icon_url: /assets/icons/kogo-white.svg
faqs:
  - q: |
      {% include faqs/resize-managed-cache.md section='question' %}
    a: |
      {% include faqs/resize-managed-cache.md section='answer' %}
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---

{% include /gateway/dcgw-cpg-note.md %}

{% include_cached /sections/managed-cache-intro.md %}

{% include /gateway/managed-cache-recommendation-note.md %}

## Set up an Azure managed cache on a control plane group

Set up a control plane, control plane group, and a managed cache for the group. 
All control planes in the group will have access to the managed cache.

### Create a hybrid control plane

{% include_cached /sections/hybrid-cp-setup.md %}

### Create a Dedicated Cloud control plane group

{% include_cached /sections/dedicated-cloud-cpg.md provider="Azure" %}

### Create a managed cache for your control plane group

{% include_cached /sections/managed-cache-cpg-setup.md %}

## Configure Redis for plugins

Next, you must manually create a [Redis partial](/gateway/entities/partial/) configuration on each control plane where Redis-backed plugins are enabled. 
Each Redis partial will use the managed cache that you just set up.

{:.info}
> **Note**: You can’t use the Redis partial configuration in custom plugins. Instead, use [env referenceable fields](/gateway/entities/vault/#store-secrets-as-environment-variables) directly.

### Create a managed cache Redis partial

Now that you've created your managed cache, you must manually create a Redis partial for it.

1. Create a Redis partial configuration:

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
    host: "{vault://env/ADDON_MANAGED_CACHE_HOST}"
    port: "{vault://env/ADDON_MANAGED_CACHE_PORT}"
    username: "{vault://env/ADDON_MANAGED_CACHE_USERNAME}"
    ssl: true
    ssl_verify: true
    server_name: "{vault://env/ADDON_MANAGED_CACHE_SERVER_NAME}"
    database: 0
    connect_timeout: 2000
    read_timeout: 5000
    send_timeout: 2000
    keepalive_backlog: 512
    keepalive_pool_size: 256
    connection_is_proxied: false
    cloud_authentication:
      auth_provider: "azure"
      azure_client_id: "{vault://env/ADDON_MANAGED_CACHE_AZURE_CLIENT_ID}"
      azure_client_secret: "{vault://env/ADDON_MANAGED_CACHE_AZURE_CLIENT_SECRET}"
      azure_tenant_id: "{vault://env/ADDON_MANAGED_CACHE_AZURE_TENANT_ID}"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create_redis_partial | indent: 3 }}
1. Repeat the previous step for all the control planes in your control plane group.

### Apply the managed cache Redis partial to a plugin

{% include_cached /sections/managed-cache-cpg-plugin-setup.md %}

## Validate

{% include_cached /sections/managed-cache-validate.md %}
