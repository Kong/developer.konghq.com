---
title: "Migrating a V0 Serverless Gateway to a V1"
content_type: reference
layout: reference
description: | 
   Migrate a V0 Serverless Gateway to a V1.

beta: true

breadcrumbs:
  - /serverless-gateways/
tags:
  - serverless-gateways
  - hybrid-mode
  - data-plane
products:
  - gateway
works_on:
  - konnect
api_specs:
  - konnect/control-planes-config
  - konnect/cloud-gateways

related_resources:
  - text: Serverless Gateways reference
    url: /serverless-gateways/reference/
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Control plane and data plane communication
    url: /gateway/cp-dp-communication/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/

---

{:.warning}
> **Note**: Serverless Gateways V1 are currently available for {{site.konnect_short_name}} organizations running in US regions only.

Serverless Gateways V1 bring the following improvements to Serverless Gateways:
* Support for rate limiting and authentication plugins
* Custom domains and private networking (pre-shared key)
* API spec upload and seamless Developer Portal
* Metering, billing, and entitlements
* Architecture tuning and performance enhancements

You can upgrade to Serverless Gateways V1 using [decK](/deck/).

## Breaking changes between V0 and V1

Review the following breaking changes before migrating to V1:

{% table %}
columns:
  - title: Change
    key: change
  - title: V0 (old)
    key: v0
  - title: V1 (new)
    key: v1
rows:
  - change: Change in proxy URL format
    v0: "`https://kong-0122456789.kongcloud.dev`"
    v1: "`https://01234567.us.serverless.gateways.konggateway.com`"
  - change: Change to control plane type
    v0: "`CLUSTER_TYPE_SERVERLESS`"
    v1: "`CLUSTER_TYPE_CLOUD_API_GATEWAY`"
  - change: Change to data plane type
    v0: "`serverless.v0`"
    v1: "`serverless.v1`"
{% endtable %}

## Migration steps

1. Set your {{site.konnect_short_name}} environment information:

   ```sh
   export DECK_KONNECT_ADDR=https://us.api.konghq.com
   export DECK_KONNECT_TOKEN=YOUR_ACCESS_TOKEN
   export DECK_KONNECT_CONTROL_PLANE=YOUR_SERVERLESS_V0_CONTROL_PLANE_ID
   ```
  
    Where:
    * `DECK_KONNECT_ADDR`: The {{site.konnect_short_name}} API URL, in this case, only for the `us` region.
    * `DECK_KONNECT_TOKEN`: A  {{site.konnect_short_name}} [personal access token](/konnect-api/#konnect-api-authentication).
    * `DECK_KONNECT_CONTROL_PLANE`: ID of the control plane you'd like to upgrade.

1. Export your current Serverless V0 control plane configuration into a decK file:

   ```sh
   deck gateway dump > kong.yml
   ```

1. Create a new Serverless Gateway using the {{site.konnect_short_name}} UI:
    1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
    1. Click the **New** button, then select **New API Gateway**.
    1. Select Serverless.
    1. Give your Gateway a name and an optional description.
    1. Click **Create** to save.

    This creates a control plane and deploys a data plane node so that you don't have to run one yourself.

1. Copy the ID of your new control plane and adjust the `DECK_KONNECT_CONTROL_PLANE` environment variable:

   ```sh
   export DECK_KONNECT_CONTROL_PLANE=YOUR_SERVERLESS_V1_CONTROL_PLANE_ID
   ```

1. Import the control plane configuration to your new Serverless V1 gateway. First, check the configuration diff:
    
   ```sh
   deck gateway diff ./kong.yml
   ```

1. If you're satisfied with the update, run a sync to update your control plane:
    
   ```sh
   deck gateway sync ./kong.yml
   ```