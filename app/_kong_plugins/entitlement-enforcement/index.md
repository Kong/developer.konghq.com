---
title: 'Entitlement Enforcement'
name: 'Entitlement Enforcement'

content_type: plugin

publisher: kong-inc
description: 'Allow or deny API requests based on customer entitlements. Checks feature access, usage limits, and credit balance against Metering & Billing before routing traffic.'

tier: enterprise

products:
    - gateway
    - metering-and-billing

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.16'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - monetization

search_aliases:
  - entitlement-enforcement
  - governance
  - metering and billing


icon: entitlement-enforcement.png

categories:
   - monetization

related_resources:
  - text: Get started with Entitlement Enforcement
    url: /metering-and-billing/entitlement-enforcement/get-started/
  - text: Enforce entitlements on LLM traffic
    url: /how-to/enforce-entitlements-on-llm-traffic/
  - text: Entitlements
    url: /metering-and-billing/entitlements/
  - text: Metering & Billing plugin
    url: /plugins/metering-and-billing/
---

{:.ai}
> {{site.metering_and_billing}} requires a separate purchase. [Contact Sales](https://konghq.com/contact-sales) for pricing and availability.

The Entitlement Enforcement plugin blocks API requests based on the customer entitlements defined in {{site.metering_and_billing}}.
It works alongside the [Metering & Billing plugin](/plugins/metering-and-billing/): Metering & Billing reports usage, and Entitlement Enforcement checks that usage against a customer's plan and blocks the request when the customer is over their limit.

The plugin blocks a request when a customer:
* Has no available credit balance for a prepaid feature.
* Has reached the usage limit for a metered feature.
* Doesn't have access to a boolean feature, for example because a subscription expired or a feature isn't included in their plan.

Requests from customers that are within their entitlements are allowed through.

## How it works

Each Entitlement Enforcement plugin instance attaches to a single feature, set with [`config.feature.key`](/plugins/entitlement-enforcement/reference/#schema--config-feature-key).

For each request, the plugin:

1. Resolves the customer's subject key from the configured source: a Consumer, a Dev Portal application, or a request header or query parameter.
   This is the same subject the Metering & Billing plugin uses to attribute usage, so both plugins agree on who's being billed.
2. Looks up the cached enforcement state for that subject in a local, per-worker cache.
3. If the feature is available and the customer's usage or credit balance is within their entitlement, allows the request.
4. If the feature is unavailable, the usage limit is reached, or credit is depleted, blocks the request with the configured HTTP status and message.

The plugin never calls the {{site.metering_and_billing}} Entitlement Access API directly from the request path. Instead, a background timer polls the endpoint on [`config.refresh_interval`](/plugins/entitlement-enforcement/reference/#schema--config-refresh-interval) and writes the result to Redis, and a second timer syncs Redis into each worker's local cache on [`config.sync_rate`](/plugins/entitlement-enforcement/reference/#schema--config-sync-rate). This two-tier cache keeps the request path fast and avoids calling the Entitlement Access API on every request.

Because enforcement state is cached and refreshed on an interval, it's eventually consistent, not real time. A customer's usage has to be reported and aggregated in {{site.metering_and_billing}}, then polled by the plugin, before enforcement reflects it. See [Cold start and fail policy](#cold-start-and-fail-policy) for what happens the first time the plugin sees a customer, and when it can't retrieve enforcement state at all.

## Enforcement decisions and response codes

When the plugin blocks a request, it returns an HTTP status and message based on the denial reason.
You can override the status and message for each reason with [`config.response_codes`](/plugins/entitlement-enforcement/reference/#schema--config-response-codes).

<!--vale off-->
{% table %}
columns:
  - title: Reason code
    key: code
  - title: Default HTTP status
    key: status
  - title: Default message
    key: message
  - title: When it happens
    key: when
rows:
  - code: "`NO_CREDIT_AVAILABLE`"
    status: "`402`"
    message: "Customer has no credit available."
    when: The customer's prepaid credit balance for the feature is depleted.
  - code: "`USAGE_LIMIT_REACHED`"
    status: "`429`"
    message: "Customer has reached usage limit for feature."
    when: The customer's usage of a metered feature has reached the limit defined in their plan.
  - code: "`FEATURE_UNAVAILABLE`"
    status: "`403`"
    message: "Feature is not available for the customer."
    when: The customer doesn't have access to a boolean feature, for example because their subscription ended or the feature isn't in their plan.
  - code: "`FEATURE_NOT_FOUND`"
    status: "`403`"
    message: "Feature not found."
    when: The configured `feature.key` doesn't match a feature returned for the customer.
  - code: "`CUSTOMER_NOT_FOUND`"
    status: "`403`"
    message: "Customer is not found by subject."
    when: The plugin can't resolve a customer for the request's subject key. This also covers unknown subjects when `deny_unknown_customers` is `true`.
{% endtable %}
<!--vale on-->

The response body for a blocked request contains the message and reason code, for example:

```json
{
  "message": "Customer has reached usage limit for feature.",
  "reason": "USAGE_LIMIT_REACHED"
}
```

## Configuring the customer

Set [`config.customer.look_up_value_in`](/plugins/entitlement-enforcement/reference/#schema--config-customer-look-up-value-in) to tell the plugin where to find the customer identifier in the request:

<!--vale off-->
{% table %}
columns:
  - title: Value
    key: value
  - title: Description
    key: description
rows:
  - value: "`consumer`"
    description: Use the authenticated Consumer's ID as the subject, sent as `consumer:<consumer-id>`. This is the default.
  - value: "`application`"
    description: Use the Dev Portal application ID as the subject, sent as `app:<application-id>`.
  - value: "`header`"
    description: Use the value of the request header named in `config.customer.field`.
  - value: "`query`"
    description: Use the value of the query parameter named in `config.customer.field`.
{% endtable %}
<!--vale on-->

Use the same subject source for both the Metering & Billing plugin and the Entitlement Enforcement plugin so usage and enforcement resolve to the same customer.

## Cold start and fail policy

The plugin can't enforce entitlements for a customer it hasn't cached yet.
The first request from a new subject is treated as unknown: the plugin records the subject and returns `CUSTOMER_NOT_FOUND` (if [`config.deny_unknown_customers`](/plugins/entitlement-enforcement/reference/#schema--config-deny-unknown-customers) is `true`), then fetches that customer's entitlements on the next poll of the Entitlement Access API. Retry the request after `config.refresh_interval` seconds to get an enforcement decision based on the customer's actual entitlements.

Set [`config.fail_policy`](/plugins/entitlement-enforcement/reference/#schema--config-fail-policy) to control what happens when the plugin can't retrieve enforcement state at all, for example if Redis is unreachable:
* `allow` (default): let the request through.
* `block`: block the request.

## Relationship to rate limiting

Entitlement Enforcement doesn't replace rate limiting.
[Rate limiting plugins](/plugins/?terms=rate%2520limiting) like [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) protect infrastructure and reset on a fixed schedule, such as requests per second or tokens per minute.
Entitlement Enforcement protects business logic, such as credit balances and plan limits, and resets on billing events.

You can use both together: for example, a customer might have a monthly token allowance enforced by this plugin, and a per-minute rate limit to prevent a single burst of traffic from consuming that allowance too quickly.
