---
title: "Pricing catalog and overrides"
content_type: reference
layout: reference

products:
  - ai-cost-management

works_on:
  - konnect

breadcrumbs:
  - /ai-cost-management/

tags:
  - ai
  - governance
  - metering

description: "Reference for the {{site.ai_cost_management}} Price Catalog and rate overrides."

related_resources:
  - text: "{{site.ai_cost_management}}"
    url: /ai-cost-management/
  - text: Model cost management
    url: /ai-gateway/model-cost-management/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
---

{{site.ai_cost_management}} reports the cost of each AI request that passes through {{site.ai_gateway}}. 
Cost depends on the price of the model that served the request, and usage queries, forecasts, and budgets all sum that cost. 
Accurate prices therefore matter for every report and budget you build.

The Price Catalog is where {{site.ai_cost_management}} brings those prices together. 
It holds provider list prices and shows the price history of each model, including when each change took effect.

List prices don't always match what you pay. 
If you negotiated a discount or a fixed rate with a provider, you can add a rate override. 
An override adjusts the list price so the catalog shows the price your organization actually pays. 
A percentage override follows vendor price changes, and a custom rate stays fixed when the vendor changes its list price. 
You can also schedule an override to start at a later date.

This page describes the Price Catalog and how to create rate overrides.

## How a request is priced

Prices can come from the following sources:

<!--vale off-->
{% table %}
columns:
  - title: Source
    key: source
  - title: Where you configure it
    key: where
  - title: Unit
    key: unit
rows:
  - source: "Price Catalog, including rate overrides"
    where: "**Cost Management** > **Price Catalog** in {{site.konnect_short_name}}. See [Pricing catalog](#pricing-catalog) and [Overrides](#overrides)."
    unit: "USD per million tokens"
  - source: "Target prices"
    where: "`input_cost`, `output_cost`, and related fields on a model target. See [Model cost management](/ai-gateway/model-cost-management/)."
    unit: "USD per million tokens"
{% endtable %}
<!--vale on-->

If a model has both a rate override in the Price Catalog and a price configured on the gateway, the rate override takes precedence.

<!-- TODO: Confirm with engineering that Price Catalog overrides take precedence over gateway-side prices, and document how overrides reach the cost that budgets and dashboards sum. The spec describes reported_cost_usd as the producer's estimate at list price, and the budgets list says spend is the stored gateway-reported cost. -->

## Pricing catalog

The Price Catalog lists the price of each model that {{site.ai_cost_management}} can price, organized into the following tabs:

<!--vale off-->
{% table %}
columns:
  - title: Tab
    key: tab
  - title: Description
    key: description
rows:
  - tab: "**Effective rates**"
    description: |
      The price you pay per million tokens for each model, after your overrides. You can filter the list by exact model ID or by provider, and open a model to see its price history.
  - tab: "**Provider overrides**"
    description: |
      Your negotiated terms and the models they price. Each row shows the provider, the model, the override type, the value, and the date it takes effect.
{% endtable %}
<!--vale on-->

The page shows when the catalog was last synced. Models without an override show `List price` in the **Override** column of the **Effective rates** tab. Models with a custom rate show `Custom rate`.

Click **Refresh** to load the latest and most accurate list of effective rates.

<!-- TODO: Document how often the catalog syncs on its own. The screenshots show the Refresh button and a Last synced timestamp only. -->

### Price fields

All prices in the Price Catalog are in USD per million tokens. The **Effective rates** tab shows the following fields for each model, and the custom rate form accepts them:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "Base input"
    description: "Price per million input tokens. Required for a custom rate."
  - field: "Output"
    description: "Price per million output tokens. Required for a custom rate."
  - field: "Cache reads"
    description: "Price per million tokens served from the provider's prompt cache."
  - field: "Cache writes"
    description: "Price per million tokens written to the provider's prompt cache."
  - field: "1-hour cache writes"
    description: "Price per million tokens written to the prompt cache with a one-hour lifetime. Available in the custom rate form."
  - field: "Reasoning"
    description: "Price per million reasoning tokens."
  - field: "Rate cards"
    description: "Optional prices for batch requests, service tiers, long inputs, and regions."
{% endtable %}
<!--vale on-->

<!-- TODO: Confirm whether a Reasoning price replaces the output rate for reasoning tokens. The existing Model cost management page says reasoning tokens are billed at the output rate. -->
<!-- TODO: Confirm the unit and meaning of each cache field in the catalog. The descriptions here are inferred from the field labels and the beta guide. -->

## Overrides

A rate override records the price terms you negotiated with a provider, so the Price Catalog reflects what you actually pay. Create one with the **Add override** button on the **Price Catalog** page.

Rate overrides come in the following types:

<!--vale off-->
{% table %}
columns:
  - title: Override type
    key: type
  - title: Applies to
    key: applies_to
  - title: Effect
    key: effect
rows:
  - type: "**Percentage off list**"
    applies_to: "Every model of the provider."
    effect: |
      Takes the percentage off every system price of the provider. The percentage applies on top of whatever the catalog currently says, so it follows vendor price changes. A percentage is never applied on top of a custom rate.
  - type: "**Custom rate**"
    applies_to: "One model."
    effect: |
      Replaces the list price entirely. Use a custom rate when a contract fixes a price regardless of what the vendor publishes. A custom rate stays fixed when the vendor changes its list price.
{% endtable %}
<!--vale on-->

If a model has a custom rate, {{site.ai_cost_management}} uses the custom rate for that model and doesn't apply the provider's percentage to it.

### Override form fields

The **Add rate override** form has the following fields:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Applies to
    key: applies_to
  - title: Description
    key: description
rows:
  - field: "**Provider**"
    applies_to: "All types"
    description: "Required. Search for a provider, or pick one from the list of most popular providers."
  - field: "**Override type**"
    applies_to: "All types"
    description: "`Percentage off list` or `Custom rate`."
  - field: "**Percent off (%)**"
    applies_to: "Percentage off list"
    description: "Required. The percentage taken off every system price of the provider."
  - field: "**Model**"
    applies_to: "Custom rate"
    description: |
      Required. Choose a model or enter a model ID. For a custom model, type its ID and select the `Use` option to confirm it.
  - field: "**Base input**, **Output**"
    applies_to: "Custom rate"
    description: "Required. Prices in USD per million tokens."
  - field: "**Cache reads**, **Cache writes**, **1-hour cache writes**, **Reasoning**"
    applies_to: "Custom rate"
    description: "Optional prices in USD per million tokens. See [Price fields](#price-fields)."
  - field: "**Rate cards**"
    applies_to: "Custom rate"
    description: |
      Optional prices in USD per million tokens for batch requests, service tiers, long inputs, and regions. Select **Add rate card** to add one. A custom rate carries only the rate cards you add here. The rate cards from the model's list price don't carry over.
  - field: "**Effective from**"
    applies_to: "All types"
    description: "The date and time the override takes effect, in UTC. Pick a later time to schedule the override."
  - field: "**Note**"
    applies_to: "All types"
    description: "Optional free-text note about the override."
{% endtable %}
<!--vale on-->

## Setting up an override

<!-- TODO: Add a link to the Price Catalog page in the Konnect sidebar step once the URL is confirmed. -->

To create a rate override in the {{site.konnect_short_name}} UI:

1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**.
1. Click **Price Catalog**.
1. Click **Add override**.
1. From the **Provider** dropdown menu, select your provider.
1. Select **Percentage off list** or **Custom rate**.
1. Enter the values for your override type:
   * For **Percentage off list**, in the **Percent off (%)** field, enter a percentage, for example `10`.
   * For **Custom rate**, in the **Model** field, choose or enter a model ID. Then, in the **Base input** and **Output** fields, enter your contracted prices in USD per million tokens.
1. Optional: To schedule the override, in the **Effective from** field, pick a later date and time in UTC.
1. Click **Add override**.

The new override appears on the **Provider overrides** tab. To check the resulting price, click the **Effective rates** tab and find the model.
