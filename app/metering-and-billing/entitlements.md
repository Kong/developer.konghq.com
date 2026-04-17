---
title: "Entitlements"
content_type: reference
description: "Use entitlements to control customer access to features, enforce usage limits, and implement pricing strategies like prepaid billing and custom quotes."
layout: reference
products:
  - metering-and-billing
tools:
  - konnect-api
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
  - /metering-and-billing/product-catalog/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: "Rate cards"
    url: /metering-and-billing/product-catalog/#rate-cards
  - text: Notifications
    url: /metering-and-billing/notifications/

---

Entitlements let you control customer access to features defined on a [rate card](/metering-and-billing/product-catalog/#rate-cards), making it possible to implement complex pricing scenarios such as monthly quotas, prepaid billing, and per-customer pricing.

Entitlements are an attribute of rate cards. You must configure entitlements when configuring a rate card.

## Use cases

{{site.metering_and_billing}} entitlements can help implement various monetization strategies:

{% table %}
columns:
  - title: Use Case
    key: case
  - title: Description
    key: description
rows:
  - case: Usage limits
    description: Enforce usage limits like monthly token allowances.
  - case: Plan variance
    description: Offer tiered plans with different feature sets.
  - case: Custom quotes
    description: Offer custom quotes and per-customer pricing.
  - case: Prepaid billing
    description: Adopt prepaid billing and handle top-ups.
  - case: Commitments
    description: Define and track pre-purchase commitments.
{% endtable %}

## Entitlement types

There are three different types of entitlements:

{% table %}
columns:
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - type: "[Metered](#metered-entitlements)"
    description: |
      Allow customers to consume features up to a certain usage limit. For example, 10 million monthly tokens.
      <br><br>
      This is useful when the underlying resources are expensive, as is the case for most AI products. 
      Metered entitlements leverage the usage information collected by {{site.metering_and_billing}} and give you the ability to do real-time usage enforcement, as well as historical queries and access checks.
      <br><br>
      When configuring a metered entitlement, you can set the following:

      * **Usage period**: Daily, weekly, monthly, or a custom [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) duration.
      * **Allowance for period**: Number of grants automatically issued on creation and in each usage period.
      * **Preserve overage**: Enable to deduct accumulated overage from the starting balance in the next period. Off by default.
      * **Soft limit**: Enable to always grant access to the feature, even when balance is zero. Off by default.
  - type: "[Static](#static-entitlements)"
    description: |
      Define customer-specific configurations as a JSON value. 
      <br><br>
      For example, you could give free users access to a subset of AI models. 
      With static entitlements, you can specify which models the customer can use based on their tier: `{ "enabledModels": ["gpt-3", "gpt-4"] }`.
  - type: "[Boolean](#boolean-entitlements)"
    description: |
      Describe access to specific features, like SAML SSO, without needing configuration or metering.
      <br><br>
      In cases where you don't need to set up usage limits or configure customer-level settings,
      you can use boolean entitlements. 
      These are simple `true` or `false` access grants to a feature.
{% endtable %}

### Metered entitlements

Metered entitlements control access to features where you want to impose usage limits. 
They leverage the usage information collected by {{site.metering_and_billing}} to enable real-time usage enforcement.

#### Usage period

Metered entitlements require a usage period setting that defines the interval over which usage is calculated. This is typically a day, week, or month. In most cases, this should match your customers' billing cycles. 

The start of each period is marked by a reset: at reset, a new marker is set from which usage is queried and aggregated.
{{site.metering_and_billing}} automatically executes the reset when a new usage period starts, based on the entitlement configuration.

If you want to maintain a continuous running balance where overage carries forward rather than being forgiven at the end of each period, set the **Preserve Overage** field on the entitlement.
When this is enabled, overage accumulated in the previous period is deducted from the starting balance of the new period.

### Static entitlements

Static entitlements let you define customer- or plan-specific configuration for a given feature as a JSON value. 
For example, you could give free trial users access to only a subset of AI models by specifying which models are available based on their tier.

The configuration you pass has to be a JSON-parsable string in object format. 
For example:

```json
{ "enabledModels": ["gpt-3", "gpt-4"] }
```

### Boolean entitlements

Boolean entitlements are simple true or false access grants to a feature. 
Use them when you don't need usage limits or customer-level configuration. 
For example, you could use a boolean entitlement to grant or deny access to a SAML SSO feature.

## Configuring and checking entitlements

Entitlements must be configured as part of rate cards in {{site.konnect_short_name}}. 
See the [{{site.metering_and_billing}} getting started guide](/metering-and-billing/get-started/) for setup steps.

Once configured, you can check entitlements for a customer through the {{site.konnect_short_name}} UI, or using the {{site.metering_and_billing}} `/entitlement-access` API:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/{customerId}/entitlement-access
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

## Entitlement enforcement

{{site.metering_and_billing}} tracks entitlement balances in real time, but does not automatically enforce limits at the Kong Gateway level.

{:.info}
> **Kong Gateway enforcement is not yet available.** Automatic entitlement enforcement via a Kong Gateway plugin is planned for a future release. Until then, use [{{site.metering_and_billing}} Notifications](/metering-and-billing/notifications/) to receive a webhook when a customer reaches their entitlement threshold, and enforce access restrictions manually in your own infrastructure (for example, by removing a consumer from a consumer group or returning a `403` response from your application).