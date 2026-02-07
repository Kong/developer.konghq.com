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

Serverless Gateways V1 bring updates to the API, increased data plane provisioning speeds, and Terraform support.

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
  - change: Proxy URL format
    v0: "`https://kong-0122456789.kongcloud.dev`"
    v1: "`https://0123456789.us.serverless.gateways.konggateway.com`"
  - change: Control plane type
    v0: "`CLUSTER_TYPE_SERVERLESS`"
    v1: "`CLUSTER_TYPE_SERVERLESS_V1`"
  - change: Data plane kind
    v0: "`serverless.v0`"
    v1: "`serverless.v1`"
{% endtable %}

## Migration steps

1. Create a [personal access token](/konnect-api/#konnect-api-authentication) in {{site.konnect_short_name}} and export it as an environment variable:

   ```sh
   export KONNECT_TOKEN=YOUR_ACCESS_TOKEN
   ```

1. Export your current Serverless V0 control plane configuration into a decK file:

   ```sh
   deck gateway dump -o kong.yaml \
    --konnect-token "$KONNECT_TOKEN" \
    --konnect-control-plane-name "MY_SERVERLESS_V0_CP"
   ```

1. Create a new Serverless Gateway using the {{site.konnect_short_name}} UI:
    
    1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
    1. Click the **New** button, then select **New API Gateway**.
    1. Select Serverless.
    1. Give your Gateway a name and an optional description.
    1. Click **Create** to save.

    This creates a control plane and deploys a data plane node so that you don't have to run one yourself.
    
    If you prefer to use the API to create control planes and data planes, see the [Serverless Gateway reference](/serverless-gateways/reference/#konnect-apis).

1. Import the control plane configuration to your new Serverless V1 gateway, making sure to target the new control plane.
First, check the configuration diff:
    
   ```sh
   deck gateway diff ./kong.yaml \
    --konnect-token "$KONNECT_TOKEN" \
    --konnect-control-plane-name "MY_NEW_SERVERLESS_V1_CP"
   ```

1. If you're satisfied with the update, run a sync to update your control plane:
    
   ```sh
   deck gateway sync ./kong.yml \
    --konnect-token "$KONNECT_TOKEN" \
    --konnect-control-plane-name "MY_NEW_SERVERLESS_V1_CP"
   ```