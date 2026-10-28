---
title: "Price catalog and overrides"
content_type: reference
layout: reference

products:
  - ai-cost-management
  - ai-gateway

min_version:
  ai-gateway: '2.3'

works_on:
  - konnect

breadcrumbs:
  - /ai-cost-management/

tags:
  - ai
  - governance
  - metering

description: "Reference for the {{site.ai_cost_management}} price catalog and rate overrides. Covers how {{site.ai_gateway}} prices a request, the dynamic pricing settings, and how to create overrides for negotiated rates."

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

The price catalog is where {{site.ai_cost_management}} brings those prices together. 
It holds provider list prices and shows the price history of each model, including when each change took effect.

List prices don't always match what you or your users pay.
If you negotiated a discount or a fixed rate with a provider, you can add a [rate override](#overrides).

## How a request is priced

{{site.ai_gateway}} can price a request from the cost management settings on an [AI Model](/ai-gateway/entities/ai-model/) target, or from the price catalog.
The price catalog allows {{site.ai_gateway}} models to use dynamic pricing, which adjusts automatically based on a price catalog that's always kept up to date with market prices.

The price catalog allows {{site.ai_gateway}} models to use dynamic pricing, which adjusts automatically based on a price catalog that's always kept up to date with market prices.

A target has cost management settings when any of its cost fields is set, for example `input_cost` or `output_cost`.
See [Model cost management](/ai-gateway/model-cost-management/) for the full list.

Dynamic pricing is on by default.
When dynamic pricing is on, {{site.ai_gateway}} prices each request in the following order:

1. If the AI Model target has any cost management settings, {{site.ai_gateway}} uses them and doesn't use the price catalog for that target.
1. If the target has no cost management settings, {{site.ai_gateway}} uses the model's [rate override](#overrides) from the price catalog.
1. If the model has no rate override, {{site.ai_gateway}} uses the model's list price from the [price catalog](#price-catalog).

If you turn dynamic pricing off, {{site.ai_gateway}} prices requests only from the target's cost management settings.
See [Dynamic pricing settings](#dynamic-pricing-settings).

<!-- TODO: Confirm with engineering that a rate override changes the cost that the data plane reports, and therefore the spend that budgets and dashboards sum. The spec describes reported_cost_usd as the producer's estimate at list price, and the engineers' docs say no override changes a cost figure. -->

### Dynamic pricing settings

Dynamic pricing has the following settings, which you can set in the `kong.conf` file of the data plane or as environment variables when you run the data plane:

* `KONG_DYNAMIC_PRICING`: `on` by default.
  If you set it to `off`, the data plane stops using the price catalog and prices requests only from target cost management settings.
  Only on-prem data planes can set a fallback, with `KONG_DYNAMIC_PRICING_URI`.
* `KONG_DYNAMIC_PRICING_URI`: For on-prem data planes only. The path to a local catalog file, for example `KONG_DYNAMIC_PRICING_URI=path/to/catalog.json`.
  The data plane uses the public catalog from that file. To set price overrides, configure them directly in the file.

<!-- TODO: Confirm the kong.conf property names and format for these settings, whether the fallback file applies to targets with no cost fields when KONG_DYNAMIC_PRICING is off and the format of the file. -->

## Price catalog

The price catalog lists the price of each model that {{site.ai_cost_management}} can price, organized into the following tabs:

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
      <br><br>
      Models without an override show `List price` in the **Override** column of the **Effective rates** tab.
      Models with a custom rate show `Custom rate`.
  - tab: "**Provider overrides**"
    description: |
      Your negotiated terms and the models they price. Each row shows the provider, the model, the override type, the value, and the date it takes effect.
{% endtable %}
<!--vale on-->

You can click **Refresh** to load the latest and most accurate list of effective rates.

### Price fields

All prices in the price catalog are in USD per million tokens.
The **Effective rates** tab shows the following fields for each model, and the custom rate form accepts them:

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
    description: "Optional prices for batch requests, service tiers, long inputs, and regions. See [Rate cards](#rate-cards)."
{% endtable %}
<!--vale on-->

A field that the catalog doesn't price shows `—`.

<!-- TODO: Confirm whether a Reasoning price replaces the output rate for reasoning tokens. The existing Model cost management page says reasoning tokens are billed at the output rate. -->

### Model details

Each model in the price catalog has a details page with its current price and price history.
You can open it from the **Effective rates** tab.
The details page shows the following:

<!--vale off-->
{% table %}
columns:
  - title: Section
    key: section
  - title: Description
    key: description
rows:
  - section: "**Override banner**"
    description: |
      Appears when an override applies to the model. The banner names the override and links to it.
  - section: "**Current price**"
    description: |
      Every price field the model carries, in USD per million tokens, with the source of the rate (`List price`, a percentage override, or `Custom rate`), the provider, and the **In force since** date. For a model with a percentage override, the page shows only the discounted price.
  - section: "**Rate cards**"
    description: |
      Appears only when the price has rate cards. Each row shows the base input, cache write, cache read, and output rates of one card. See [Rate cards](#rate-cards).
  - section: "**Price history**"
    description: |
      Every version of the model's price, newest first, up to the 50 most recent. Each row shows the effective date, the core rates, the change in base input from the previous version (`First published`, `No change`, or a signed percentage), and whether the version is `In force` or `Superseded`. A custom rate that takes effect later appears first, marked `Scheduled`.
{% endtable %}
<!--vale on-->

## Overrides

An override adjusts the list price so the catalog shows the price your organization actually pays.
A percentage override follows vendor price changes, and a custom rate stays fixed when the vendor changes its list price.
You can also schedule an override to start at a later date.

You can create a rate override with the **Add override** button on the [**Price Catalog**](https://cloud.konghq.com/us/ai-manager/cost-management/price-catalog) page.

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
      Takes the percentage off every list price of the provider. The percentage applies on top of whatever the catalog currently says, so it follows vendor price changes. A percentage is never applied on top of a custom rate.
  - type: "**Custom rate**"
    applies_to: "One model."
    effect: |
      Replaces the list price entirely. A custom rate fits a contract that fixes a price regardless of what the vendor publishes. A custom rate stays fixed when the vendor changes its list price.
{% endtable %}
<!--vale on-->

The **Provider overrides** tab lists overrides by creation time, newest first.
The **Value** column shows `10% off list` for a percentage override, or the input and output rates for a custom rate.
An override with a future effective date shows a `Scheduled` badge until it takes effect.
An override that has ended shows an `Ended` badge, and its details page shows **Effective until**.

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
    description: "Required. You can search for a provider or pick one from the most popular providers."
  - field: "**Override type**"
    applies_to: "All types"
    description: "`Percentage off list` or `Custom rate`."
  - field: "**Percent off (%)**"
    applies_to: "Percentage off list"
    description: "Required. The percentage taken off every system price of the provider."
  - field: "**Model**"
    applies_to: "Custom rate"
    description: |
      Required. You can choose a model or enter a model ID. For a custom model, you can enter its ID and confirm it with the `Use` option.
  - field: "**Base input**, **Output**"
    applies_to: "Custom rate"
    description: "Required. Prices in USD per million tokens."
  - field: "**Cache reads**, **Cache writes**, **1-hour cache writes**, **Reasoning**"
    applies_to: "Custom rate"
    description: "Optional prices in USD per million tokens. See [Price fields](#price-fields)."
  - field: "**Rate cards**"
    applies_to: "Custom rate"
    description: |
      Optional prices in USD per million tokens for batch requests, service tiers, long inputs, and regions. You can add one with **Add rate card**. A custom rate carries only the rate cards you add here, so the rate cards from the model's list price don't carry over.
  - field: "**Effective from**"
    applies_to: "All types"
    description: "The date and time the override takes effect, in UTC. The default is the current time, and a later time schedules the override."
  - field: "**Note**"
    applies_to: "All types"
    description: "Optional free-text note about the override."
{% endtable %}
<!--vale on-->

### Rate cards

A rate card sets prices for requests that are served differently from the standard rates.
A custom rate carries only the rate cards you add to it, so the model's list-price rate cards don't carry over.
You can add one of the following kinds of rate card with **Add rate card**:

<!--vale off-->
{% table %}
columns:
  - title: Rate card
    key: card
  - title: Applies to
    key: applies_to
rows:
  - card: "**Batch**"
    applies_to: "Batch requests."
  - card: "**Flex tier**"
    applies_to: "Requests on the flex service tier."
  - card: "**Priority tier**"
    applies_to: "Requests on the priority service tier."
  - card: "**Long context**"
    applies_to: |
      Requests with inputs above a token threshold. You can enter the threshold as a whole number of tokens and choose whether the card applies to standard, batch, flex tier, or priority tier requests.
  - card: "**Region**"
    applies_to: |
      Requests served in one inference region. You can choose a region code (`us`, `eu`, `us-gov`, `global`, or `au`) or enter another code.
{% endtable %}
<!--vale on-->

Each rate card needs at least one of the base input, output, cache read, and cache write prices.
You can add each of the batch, flex tier, and priority tier cards once, and each region once.
You can't add two long-context cards with the same threshold and the same requests.

### Override rules

The following rules apply when you create a rate override:

* A percentage must be greater than 0 and at most 100.
* A provider can have only one active percentage override. {{site.ai_cost_management}} rejects a second one.
* A new custom rate for a model ends the model's earlier custom rate at the time the new one takes effect.
* You can't edit an override, so to change one, you can delete it and create a new one.

## Set up an override

To create a rate override in the {{site.konnect_short_name}} UI:

1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**.
1. Click **Price Catalog**.
1. Click **Add override**.
1. From the **Provider** dropdown menu, select your provider.
1. Select **Percentage off list** or **Custom rate**.
1. Enter the values for your override type:
   * For **Percentage off list**, in the **Percent off (%)** field, enter a percentage, for example `10`.
   * For **Custom rate**, in the **Model** field, choose or enter a model ID. Then, in the **Base input** and **Output** fields, enter your contracted prices in USD per million tokens.
1. *(Optional)* To schedule the override, in the **Effective from** field, pick a later date and time in UTC.
1. Click **Add override**.

The new override appears on the **Provider overrides** tab.
To check the resulting price, click the **Effective rates** tab and find the model.

You can remove an override by opening it from the **Provider overrides** tab and deleting it, or by using **Revert to list price** on the page of a model.
Removing a percentage override returns every model of the provider to its list price, and removing a custom rate returns the model to the vendor's list price.
You can't undo a deletion.
