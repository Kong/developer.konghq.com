---
title: Get started with Entitlement Enforcement
description: Learn how to enforce per-customer entitlements on {{site.base_gateway}} traffic with the Entitlement Enforcement plugin and {{site.metering_and_billing}} in {{site.konnect_short_name}}.
content_type: how_to

permalink: /metering-and-billing/entitlement-enforcement/get-started/
breadcrumbs:
  - /metering-and-billing/

products:
    - gateway
    - metering-and-billing

works_on:
    - konnect

min_version:
  gateway: '3.16'

tags:
    - get-started

tldr:
  q: How do I use the Entitlement Enforcement plugin to enforce {{site.metering_and_billing}} entitlements on {{site.base_gateway}} traffic?
  a: |
    The Entitlement Enforcement plugin enforces per-customer, per-feature access by polling the {{site.metering_and_billing}} Entitlement Access API and blocking requests when a customer has no access or has exhausted a usage limit.

    In this tutorial you'll set up the full {{site.metering_and_billing}} product catalog needed for enforcement — a meter, a metered feature, a plan with an entitlement, a customer, and a subscription — and then enable the Entitlement Enforcement plugin on a {{site.base_gateway}} Route to enforce that entitlement.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: "{{site.konnect_short_name}} roles"
      content: |
        You need the [{{site.metering_and_billing}} Admin role](/konnect-platform/teams-and-roles/#metering-billing) in {{site.konnect_short_name}} to configure {{site.metering_and_billing}}.
      icon_url: /assets/icons/kogo-white.svg
    - title: "{{site.konnect_short_name}} system account token (Ingest)"
      include_content: prereqs/metering-and-billing-spat
      icon_url: /assets/icons/kogo-white.svg
    - title: "{{site.konnect_short_name}} system account token (Entitlement Access)"
      include_content: prereqs/metering-and-billing-entitlement-access-spat
      icon_url: /assets/icons/kogo-white.svg
    - title: "Redis"
      include_content: prereqs/redis
      icon_url: /assets/icons/gateway.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: "{{site.metering_and_billing}} plugin"
    url: /plugins/metering-and-billing/
  - text: Product Catalog reference
    url: /metering-and-billing/product-catalog/
  - text: Entitlements
    url: /metering-and-billing/entitlements/
  - text: Customers and usage attribution
    url: /metering-and-billing/customer/
  - text: Get started with {{site.metering_and_billing}}
    url: /metering-and-billing/get-started/

next_steps:
  - text: See all {{site.base_gateway}} tutorials
    url: /how-to/?products=gateway
  - text: Learn about {{site.base_gateway}} entities
    url: /gateway/entities/
  - text: Learn about entitlements
    url: /metering-and-billing/entitlements/

automated_tests: false
---

This guide shows how to enforce {{site.metering_and_billing}} entitlements on {{site.base_gateway}} API traffic with the Entitlement Enforcement plugin. Unlike the {{site.metering_and_billing}} plugin, which only meters usage, the Entitlement Enforcement plugin actively **blocks** requests: it polls the {{site.metering_and_billing}} Entitlement Access API for each customer and returns an error when the customer has no access to a feature or has exhausted a usage limit.

In this guide, you'll:
* Create a {{site.base_gateway}} Consumer that you'll map to a customer
* Set up a meter for {{site.base_gateway}} API requests
* Create a metered feature
* Create a plan that grants that feature as an entitlement, and publish it
* Create a customer and start a subscription so the entitlement is active
* Enable the {{site.metering_and_billing}} plugin to report usage, and the Entitlement Enforcement plugin to enforce the entitlements
* Verify that traffic is allowed within the limit and blocked once the limit is reached

The following diagram shows how {{site.base_gateway}} entities and {{site.metering_and_billing}} entities are associated:

{% mermaid %}
flowchart TB
  subgraph gateway["<b>Kong Gateway</b>"]
    direction LR
        service["example-service"]
        route["example-route"]
        consumer1["Consumer-Kong Air"]
        metering["Metering & Billing plugin"]
        enforcement["Entitlement Enforcement plugin"]
  end
  subgraph mb["<b>Konnect {{site.metering_and_billing}}</b>"]
    direction LR
        meter["Meter"]
    subgraph plan["Premium Plan"]
      direction LR
          feature2["Metered feature + entitlement (limit)"]
    end
    subgraph subscription["Premium Subscription"]
      direction LR
          customer1["Customer (Kong Air)"]
    end
    access["Entitlement Access API"]
  end
    service --> meter
    meter --> feature2
    consumer1 --> customer1
    subscription --> plan
    metering -->|usage events| meter
    enforcement -->|polls access| access
    access --> customer1

{% endmermaid %}

## Create a Consumer

Before you configure {{site.metering_and_billing}}, set up a Consumer, Kong Air. [Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. Later in this guide, you'll map this Consumer to a customer in {{site.metering_and_billing}}.

The Entitlement Enforcement plugin identifies the customer from the request's Consumer and sends the subject key `consumer:<consumer-id>` to the Entitlement Access API. To keep that subject key predictable, this guide sets an explicit `id` on the Consumer so you can reference it directly when you create the customer.

You're going to use key [authentication](/gateway/authentication/) in this tutorial, so the Consumer needs an API key to access any {{site.base_gateway}} Services.

<!--vale off-->
{% entity_examples %}
entities:
  consumers:
    - id: a3d1f5e2-1b2c-4d3e-9f80-000000000001
      username: kong-air
      keyauth_credentials:
        - key: air-key
{% endentity_examples %}
<!--vale on-->

## Enable authentication

Authentication lets you identify a Consumer so you can enforce their entitlements as a customer.
This example uses the [Key Authentication](/plugins/key-auth/) plugin, but you can use any [authentication plugin](/plugins/?category=authentication) that you prefer.

Enable the plugin globally, which means it applies to all {{site.base_gateway}} Services and Routes:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}
<!--vale on-->

## Create a meter

In {{site.metering_and_billing}}, [meters](/metering-and-billing/metering/) track and record the consumption of a resource over time. Create a meter to count API requests. The command captures the new meter's ID so you can reference it when you create the metered feature:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/meters
method: POST
body:
  name: API requests
  key: api_requests_total
  description: Number of API requests
  event_type: kong.api_request
  aggregation: count
  dimensions:
    request_method: $.request_method
    route_name: $.route_name
    service_name: $.service_name
capture:
  - variable: METER_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

## Create a feature

Meters collect raw usage, but [features](/metering-and-billing/product-catalog/#features) make that usage enforceable. Create a metered feature that references the meter, so its entitlement can carry the usage limit that the Entitlement Enforcement plugin enforces. The command captures the new feature's ID so you can reference it when you create the plan:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/features
method: POST
body:
  name: Premium API access
  key: premium_api_access
  meter:
    id: $METER_ID
capture:
  - variable: METERED_FEATURE_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

## Enable the {{site.metering_and_billing}} plugin

The Entitlement Enforcement plugin enforces a usage limit, but something has to report the usage that counts against it. Configure the [{{site.metering_and_billing}} plugin](/plugins/metering-and-billing/) on `example-service` to emit an API request event for every request. Because both plugins use `consumer` lookup, the usage the {{site.metering_and_billing}} plugin reports is attributed to the same `consumer:<consumer-id>` subject that the Entitlement Enforcement plugin checks.

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: metering-and-billing
      service: example-service
      config:
        ingest_endpoint: https://us.api.konghq.com/v3/openmeter/events
        api_token: ${AUTH_TOKEN}
        meter_api_requests: true
        meter_ai_token_usage: false
        subject:
          look_up_value_in: consumer
variables:
  AUTH_TOKEN:
    value: $AUTH_TOKEN
    description: A {{site.konnect_short_name}} system account token (`spat_`) with the Metering Ingest role.
{% endentity_examples %}
<!--vale on-->

## Create a plan with entitlements

Plans are the core building blocks of your [product catalog](/metering-and-billing/product-catalog/). A plan is a collection of [rate cards](/metering-and-billing/product-catalog/#rate-cards), where each rate card ties a feature to a price and an optional [entitlement](/metering-and-billing/entitlements/). The entitlement is what the Entitlement Enforcement plugin reads to decide access.

Create a Premium plan with one rate card: the metered feature, granted a limit of 5 requests per month. The rate card uses a free price, because enforcement depends only on the entitlement, not on price:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans
method: POST
body:
  name: Premium
  key: premium
  currency: USD
  billing_cadence: P1M
  phases:
    - name: Main
      key: main
      rate_cards:
        - name: Premium API access
          key: premium_api_access
          feature:
            id: $METERED_FEATURE_ID
          billing_cadence: P1M
          price:
            type: free
          entitlement:
            type: metered
            is_soft_limit: false
            usage_period: P1M
            limit: 5
capture:
  - variable: PLAN_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

Publish the plan so you can subscribe customers to it:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans/$PLAN_ID/publish
method: POST
{% endkonnect_api_request %}
<!--vale on-->

## Create a customer and subscription

A [customer](/metering-and-billing/customer/) is the entity whose access is enforced. The customer's usage-attribution subject key must match the subject the Entitlement Enforcement plugin sends, which is `consumer:` followed by the Consumer ID you set earlier.

{:.info}
> This guide creates the customer through the API so that the subject key can be set to the exact `consumer:<consumer-id>` value. In the {{site.metering_and_billing}} UI, the **Include usage from** dropdown only lists subjects that have already sent events, so a freshly created subject key isn't selectable yet.

Create the customer with the matching subject key:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers
method: POST
body:
  name: Kong Air
  key: kong-air
  currency: USD
  usage_attribution:
    subject_keys:
      - consumer:a3d1f5e2-1b2c-4d3e-9f80-000000000001
{% endkonnect_api_request %}
<!--vale on-->

Now subscribe the customer to the Premium plan. Starting the subscription materializes the metered entitlement onto the customer:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Kong Air**.
1. Click the **Subscriptions** tab.
1. Click **Create a Subscription**.
1. From the **Subscribed Plan** dropdown, select "Premium".
1. Click **Next Step**.
1. Click **Start Subscription**.

## Enable the Entitlement Enforcement plugin

Enable the Entitlement Enforcement plugin on `example-route`. It points at the Entitlement Access API, enforces the `premium_api_access` feature, reads the customer from the request's Consumer, and uses your Redis instance as its enforcement cache at `config.redis`. Note that `api_token` uses the **Entitlement Access** token, not the **Ingest** token the {{site.metering_and_billing}} plugin uses:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: entitlement-enforcement
      route: example-route
      config:
        entitlement_access_endpoint: https://us.api.konghq.com/v3/openmeter/entitlement-access/query
        api_token: ${ENTITLEMENT_ACCESS_TOKEN}
        feature:
          key: premium_api_access
        customer:
          look_up_value_in: consumer
        refresh_interval: 3
        redis:
          host: ${REDIS_HOST}
          port: 6379
variables:
  ENTITLEMENT_ACCESS_TOKEN:
    value: $ENTITLEMENT_ACCESS_TOKEN
    description: A {{site.konnect_short_name}} system account token (`spat_`) with the **Entitlement Access** role for Metering.
  REDIS_HOST:
    value: $REDIS_HOST
    description: The host of your Redis instance. Use `host.docker.internal` if Redis runs on your host and the Data Plane runs in Docker.
{% endentity_examples %}
<!--vale on-->

This configuration relies on the plugin's defaults for the rest of its behavior:

* `deny_unknown_customers` defaults to `true`, so a request whose customer can't be resolved is blocked.
* `fail_policy` defaults to `allow`, so if the enforcement state can't be retrieved, requests are allowed through.
* `response_codes` defaults return `429` when a usage limit is reached, `402` when there's no credit available, and `403` for feature or customer errors.

Each plugin instance enforces exactly one `feature.key`. Boolean entitlements are evaluated the same way as metered ones: if the customer doesn't have the feature, the request is denied with `403` and a `reason.code` of `feature_unavailable`. To enforce more than one feature, enable a plugin instance per feature on the Routes that serve it.

{:.info}
> `refresh_interval` is set to `3` seconds here so the tutorial responds quickly. In production, use a higher interval to reduce load on the Entitlement Access API.

## Validate

Send requests to your Route with the Kong Air API key:

<!--vale off-->
```sh
for _ in {1..8}; do
  curl -i $KONNECT_PROXY_URL/anything \
       -H "apikey:air-key"
  echo
  sleep 1
done
```
<!--vale on-->

Expect the following progression:

* **Cold start:** the first requests may return `403` with `"Customer is not found by subject."` The Entitlement Enforcement plugin hasn't polled the customer's state yet. It records the subject and fetches its entitlements on the next poll (every `refresh_interval` seconds), so retry for up to a minute.
* **Within the limit:** once the state is loaded, requests return `200`. The customer has access to `premium_api_access` and hasn't reached the limit of 5.
* **Limit reached:** as the {{site.metering_and_billing}} plugin reports usage and it crosses 5 requests in the period, the Entitlement Enforcement plugin blocks further requests with `429` and `"Customer has reached usage limit for feature."`

{:.info}
> There's a short delay between metering a request and the Entitlement Access API reflecting the new usage, and another delay while the plugin polls the updated state. If you don't see `429` immediately after the sixth request, keep sending requests for a few more seconds.

### Query the Entitlement Access API directly

To confirm the customer's access independent of the plugin's cache, you can call the same endpoint the plugin uses. This reports `has_access` per feature for the subject:

{:.warning}
> The Entitlement Access query endpoint is an internal, unstable API. It may change without notice — use it for verification, not for production integrations.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/entitlement-access/query
method: POST
body:
  customer:
    keys:
      - consumer:a3d1f5e2-1b2c-4d3e-9f80-000000000001
  feature:
    keys:
      - premium_api_access
  include_credits: true
{% endkonnect_api_request %}
<!--vale on-->

In the response, `data[0].features.premium_api_access.has_access` is `true` while the customer is within the limit and `false` once the limit is reached, with a `reason.code` of `usage_limit_reached`.

{:.info}
> **Entitlement Enforcement enforces, metering doesn't:** the {{site.metering_and_billing}} plugin only reports usage, but the Entitlement Enforcement plugin blocks traffic based on entitlements. Customize the `response_codes` in the plugin configuration to control the status code and message returned for each denial reason.
