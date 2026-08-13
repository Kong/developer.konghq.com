---
title: Enforce entitlements on LLM traffic
description: Learn how to cap per-customer LLM token usage with the Entitlement Enforcement plugin and {{site.metering_and_billing}} in {{site.konnect_short_name}}.
content_type: how_to

permalink: /how-to/enforce-entitlements-on-llm-traffic/
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
  q: How do I stop a customer from consuming more LLM tokens than their plan allows?
  a: |
    Meter LLM token usage with the {{site.metering_and_billing}} plugin, grant the customer a token allowance as a metered entitlement, and enable the Entitlement Enforcement plugin on the Route.

    The plugin polls the {{site.metering_and_billing}} Entitlement Access API for the customer's remaining allowance and blocks requests once the token limit is reached, so enforcement happens at the gateway instead of in your own infrastructure.

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
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/ai.svg
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
  - text: Monetize LLM traffic in {{site.konnect_short_name}}
    url: /how-to/meter-llm-traffic/
  - text: Get started with Entitlement Enforcement
    url: /metering-and-billing/entitlement-enforcement/get-started/
  - text: Entitlements
    url: /metering-and-billing/entitlements/
  - text: Product Catalog reference
    url: /metering-and-billing/product-catalog/
  - text: Customers and usage attribution
    url: /metering-and-billing/customer/

next_steps:
  - text: See all {{site.ai_gateway}} tutorials
    url: /how-to/?products=ai-gateway
  - text: Learn about entitlements
    url: /metering-and-billing/entitlements/
  - text: Meter and bill {{site.base_gateway}} API requests
    url: /metering-and-billing/get-started/

automated_tests: false
---

This guide shows how to enforce an LLM token allowance on {{site.ai_gateway}} traffic. [Metering LLM traffic](/how-to/meter-llm-traffic/) tells you what a customer consumed, but it doesn't stop them consuming more. The Entitlement Enforcement plugin closes that gap: it polls the {{site.metering_and_billing}} Entitlement Access API for the customer's remaining token allowance and blocks requests once the allowance is spent.

In this guide, you'll:
* Create a {{site.base_gateway}} Consumer that you'll map to a customer
* Route LLM traffic through the {{site.ai_gateway}} AI Proxy plugin
* Set up a meter for LLM tokens and a feature that counts only prompt tokens
* Create a plan that grants a token allowance as a metered entitlement, and publish it
* Create a customer and start a subscription so the entitlement is active
* Enable the {{site.metering_and_billing}} plugin to report token usage, and the Entitlement Enforcement plugin to enforce the allowance
* Verify that LLM requests are allowed until the token allowance runs out, then blocked

The following diagram shows how {{site.base_gateway}} entities and {{site.metering_and_billing}} entities are associated:

{% mermaid %}
flowchart TB
  subgraph gateway["<b>Kong Gateway</b>"]
    direction LR
        service["example-service"]
        route["example-route"]
        consumer1["Consumer-Kong Air"]
        proxy["AI Proxy plugin"]
        metering["Metering & Billing plugin"]
        enforcement["Entitlement Enforcement plugin"]
  end
  subgraph mb["<b>Konnect {{site.metering_and_billing}}</b>"]
    direction LR
        meter["Meter (LLM tokens)"]
    subgraph plan["Token Plan"]
      direction LR
          feature2["Metered feature + entitlement (token limit)"]
    end
    subgraph subscription["Token Subscription"]
      direction LR
          customer1["Customer (Kong Air)"]
    end
    access["Entitlement Access API"]
  end
    proxy --> service
    service --> meter
    meter --> feature2
    consumer1 --> customer1
    subscription --> plan
    metering -->|token usage events| meter
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

## Configure the AI Proxy plugin

To set up [AI Proxy](/plugins/ai-proxy/) with OpenAI, specify the [model](https://platform.openai.com/docs/models) and set the appropriate authentication header. You must also enable `log_payloads` and `log_statistics`, because the token counts that {{site.metering_and_billing}} meters come from the AI Proxy statistics:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      service: example-service
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: gpt-4o
        logging:
          log_payloads: true
          log_statistics: true
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}
<!--vale on-->

## Create a meter

In {{site.metering_and_billing}}, [meters](/metering-and-billing/metering/) track and record the consumption of a resource over time. Create a meter that sums the tokens reported for each LLM request. The command captures the new meter's ID so you can reference it when you create the feature:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/meters
method: POST
body:
  name: LLM Tokens
  key: llm_tokens_total
  description: Number of input and output tokens across models
  event_type: kong.llm_request
  aggregation: sum
  value_property: $.tokens
  dimensions:
    model: $.model
    provider: $.provider
    type: $.type
capture:
  - variable: METER_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

## Create a feature

Meters collect raw usage, but [features](/metering-and-billing/product-catalog/#features) make that usage enforceable. Create a metered feature that references the meter, and filter it so that only OpenAI prompt tokens count against the allowance.

The `type` dimension on a `kong.llm_request` event is either `request` or `response`. Filtering on `request` means the allowance is spent by what the customer sends, which is predictable, rather than by how long the model's answer happens to be:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/features
method: POST
body:
  name: LLM token access
  key: llm_token_access
  meter:
    id: $METER_ID
    filters:
      provider:
        eq: openai
      type:
        eq: request
capture:
  - variable: FEATURE_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

## Enable the {{site.metering_and_billing}} plugin

The Entitlement Enforcement plugin enforces the token allowance, but something has to report the tokens that count against it. Configure the [{{site.metering_and_billing}} plugin](/plugins/metering-and-billing/) on `example-service` to emit an LLM token event for every request. Because both plugins use `consumer` lookup, the usage the {{site.metering_and_billing}} plugin reports is attributed to the same `consumer:<consumer-id>` subject that the Entitlement Enforcement plugin checks.

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: metering-and-billing
      service: example-service
      config:
        ingest_endpoint: https://us.api.konghq.com/v3/openmeter/events
        api_token: ${AUTH_TOKEN}
        meter_api_requests: false
        meter_ai_token_usage: true
        subject:
          look_up_value_in: consumer
variables:
  AUTH_TOKEN:
    value: $AUTH_TOKEN
    description: A {{site.konnect_short_name}} system account token (`spat_`) with the Metering Ingest role.
{% endentity_examples %}
<!--vale on-->

## Create a plan with a token entitlement

Plans are the core building blocks of your [product catalog](/metering-and-billing/product-catalog/). A plan is a collection of [rate cards](/metering-and-billing/product-catalog/#rate-cards), where each rate card ties a feature to a price and an optional [entitlement](/metering-and-billing/entitlements/). The entitlement is what the Entitlement Enforcement plugin reads to decide access.

Create a Token plan with one rate card that grants 100 prompt tokens per hour. The rate card uses a free price, because enforcement depends only on the entitlement, not on price:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans
method: POST
body:
  name: Token
  key: token
  currency: USD
  billing_cadence: P1M
  phases:
    - name: Main
      key: main
      rate_cards:
        - name: LLM token access
          key: llm_token_access
          feature:
            id: $FEATURE_ID
          billing_cadence: P1M
          price:
            type: free
          entitlement:
            type: metered
            is_soft_limit: false
            usage_period: PT1H
            limit: 100
capture:
  - variable: PLAN_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> The `limit` is expressed in the meter's own unit, which is tokens here. A short chat request like the one in the validation step below costs roughly 20 prompt tokens, so 100 tokens is spent after about five requests: long enough to see traffic pass, short enough to see it blocked. `usage_period` is set to `PT1H` because one hour is the shortest usage period the API accepts.

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

Now subscribe the customer to the Token plan. Starting the subscription materializes the token entitlement onto the customer:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Kong Air**.
1. Click the **Subscriptions** tab.
1. Click **Create a Subscription**.
1. From the **Subscribed Plan** dropdown, select "Token".
1. Click **Next Step**.
1. Click **Start Subscription**.

## Enable the Entitlement Enforcement plugin

Enable the Entitlement Enforcement plugin on `example-route`. It points at the Entitlement Access API, enforces the `llm_token_access` feature, reads the customer from the request's Consumer, and uses your Redis instance as its enforcement cache at `config.redis`. Note that `api_token` uses the **Entitlement Access** token, not the **Ingest** token the {{site.metering_and_billing}} plugin uses:

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
          key: llm_token_access
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

{:.info}
> `refresh_interval` is set to `3` seconds here so the tutorial responds quickly. In production, use a higher interval to reduce load on the Entitlement Access API.

## Validate

Send a chat request to your Route with the Kong Air API key:

<!--vale off-->
{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'apikey: air-key'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}
<!--vale on-->

Now repeat the same request until the token allowance runs out:

<!--vale off-->
```sh
for _ in {1..10}; do
  curl -i $KONNECT_PROXY_URL/anything \
       -H "apikey:air-key" \
       -H "Content-Type: application/json" \
       -d '{"messages":[{"role":"system","content":"You are a mathematician"},{"role":"user","content":"What is 1+1?"}]}'
  echo
  sleep 10
done
```
<!--vale on-->

Expect the following progression:

* **Cold start:** the first requests may return `403` with `"Customer is not found by subject."` The Entitlement Enforcement plugin hasn't polled the customer's state yet. It records the subject and fetches its entitlements on the next poll (every `refresh_interval` seconds), so retry for up to a minute.
* **Within the allowance:** once the state is loaded, requests return `200` and reach the model. Each one spends prompt tokens against the 100-token entitlement.
* **Allowance spent:** once the reported prompt tokens cross 100 in the usage period, the Entitlement Enforcement plugin blocks further requests with `429` and `"Customer has reached usage limit for feature."`

{:.info}
> Blocking is not instant, which is why the loop above sleeps between requests. Two delays stack up: {{site.metering_and_billing}} aggregates entitlement usage at one-minute granularity, so tokens you just spent take up to a minute to count, and the plugin then needs another `refresh_interval` seconds to poll the updated state. If you don't see `429` right after the allowance should have run out, keep sending requests for another minute.

### Query the Entitlement Access API directly

To confirm the customer's remaining allowance independent of the plugin's cache, you can call the same endpoint the plugin uses. This reports `has_access` per feature for the subject:

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
      - llm_token_access
  include_credits: true
{% endkonnect_api_request %}
<!--vale on-->

In the response, `data[0].features.llm_token_access.has_access` is `true` while the customer still has tokens left and `false` once the allowance is spent, with a `reason.code` of `usage_limit_reached`.

{:.info}
> **Enforce at the gateway, not downstream:** without the Entitlement Enforcement plugin, an exhausted entitlement only shows up in reporting and notifications, and the LLM request still reaches the model — and still costs you. With the plugin on the Route, the request is rejected before it's proxied. Customize the `response_codes` in the plugin configuration to control the status code and message returned for each denial reason.
