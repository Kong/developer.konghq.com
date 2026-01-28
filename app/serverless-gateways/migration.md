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
  - text: Migrate from V0 to V1
    url: /serverless-gateways/migration/
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Control plane and data plane communication
    url: /gateway/cp-dp-communication/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/

---

{:.info}
> **Note**: Serverless Gateways V1 are currently available for {{site.konnect_short_name}} organizations running in US regions only.

Serverless Gateways V1 bring the following improvements to Serverless Gateways:
* Support for rate limiting and authentication plugins
* Custom domains and private networking (pre-shared key)
* API spec upload and seamless Developer Portal
* Metering, billing, and entitlements
* Architecture tuning and performance enhancements

You can upgrade to Serverless Gateways V1 using [decK](/deck/).

## Breaking changes between V0 and V1

Review the following changes before migrating to V1:

* Change in proxy URL: The proxy URL format changes from `https://kong-0122456789.kongcloud.dev` to `https://01234567.us.serverless.gateways.konggateway.com`
* Change to control plane type: The control plane type changes from `CLUSTER_TYPE_SERVERLESS` to `CLUSTER_TYPE_CLOUD_API_GATEWAY`.
* Data plane type: The data plane gateway type changes from `serverless.v0` to `serverless.v1`

## Migration 

1. Set your {{site.konnect_short_name}} environment information:

		```sh
		export DECK_KONNECT_ADDR=https://us.api.konghq.com
		export DECK_KONNECT_TOKEN=YOUR_ACCESS_TOKEN
		export DECK_KONNECT_CONTROL_PLANE=YOUR_SERVERLESS_V0_CONTROL_PLANE_ID
		```
    
		Set the `DECK_KONNECT_CONTROL_PLANE` variable to the ID of the control plane you'd like to upgrade.

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

1. Copy the ID of your new conrol plane and adjust the `DECK_KONNECT_CONTROL_PLANE` environment variable:

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