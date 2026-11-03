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
  - on-prem

breadcrumbs:
  - /ai-gateway/
  - /ai-management/
  - /ai-cost-management/

tags:
  - ai
  - governance
  - cost-management

description: "The price catalog holds the price of each model that {{site.ai_cost_management}} can price, and rate overrides let you adjust those prices to the terms you negotiated with a provider."

related_resources:
  - text: Analytics and debugging in {{site.ai_cost_management}}
    url: /ai-cost-management/analytics-and-debugging/
  - text: Model cost management
    url: /ai-gateway/model-cost-management/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/

faqs:
  - q: Why isn't my rate override applied?
    a: |
      If your override isn't being applied, check the following:

      * **Target cost management settings:** If the target has any cost management setting defined, for example `input_cost`, {{site.ai_gateway}} prices that target from its own settings and ignores the price catalog.
        Remove the setting from the target to use the override.
      * **Dynamic pricing:** If `dynamic_pricing` is `off`, {{site.ai_gateway}} doesn't use the price catalog or its overrides.
        Set dynamic pricing to `on` to use the override.
      * **Effective from time:** The override is scheduled for a future time, which you can see as a `Scheduled` badge on the **Provider overrides** tab.
        You can wait for that time, or delete the override and create a new one with an earlier time.

  - q: Can a provider have both a percentage off override and a custom rate?
    a: |
      Yes. A provider can have a percentage off override and custom rates for individual models at the same time.
      A model with a custom rate uses the custom rate, and the percentage off override applies to the provider's other models.

  - q: Do rate overrides apply to every {{site.ai_gateway}} in my organization?
    a: |
      Yes. A rate override applies to every {{site.ai_gateway}} in your organization.

  - q: Can I apply an override in my on-prem {{site.ai_gateway}} price catalog?
    a: |
      You can't use the {{site.konnect_short_name}} UI to apply overrides on-prem. 
      
      However, if you're using the `dynamic_pricing_uri` setting to provide a catalog instead of using {{site.konnect_short_name}}'s price catalog, you can set any prices you like in that file.
---

{{site.ai_cost_management}} reports the cost of each AI request that passes through {{site.ai_gateway}}. 
Cost depends on the price of the model that served the request. 
Usage queries, forecasts, and budgets all need to calculate their totals from accurate model prices.

The price catalog holds provider list prices and shows the price history of each model, including when each change took effect.
{{site.ai_gateway}} models can pull prices from the price catalog dynamically.

List prices don't always match what you pay.
If you negotiated a discount or a fixed rate with a provider, you can add a [rate override](#overrides).

## How a request is priced

The price catalog allows {{site.ai_gateway}} models to use dynamic pricing, which adjusts automatically based on public market prices and your own overrides.
A target on an [AI Model](/ai-gateway/entities/ai-model/) can also have its own [cost management settings](/ai-gateway/model-cost-management/).

Dynamic pricing is on by default.
When dynamic pricing is on, {{site.ai_gateway}} prices each request in the following order of precedence:

1. The cost management settings on the target, if it has any.
1. The model's [custom rate override](#custom-rate-overrides), if it has one.
1. The provider's [percentage off override](#percentage-off-overrides), if it has one.
1. The model's list price from the [price catalog](#price-catalog).

Since per-target cost fields take precedence over catalog overrides, this makes them useful when different targets using the same model need different prices.

For example, you a premium route at `/gold-tier-requests` and a standard route at `silver-tier-requests`.
In this case, both routes use the same model, but only the premium target has cost fields set:

* The standard route uses the catalog price or your negotiated override.
* The premium target uses its own fixed price.

Catalog overrides apply across every {{site.ai_gateway}} in your organization for a given model or provider, so they are a better fit for a negotiated discount that covers all usage.

You can turn dynamic pricing off to prevent {{site.ai_gateway}} from using the price catalog or overrides.
See [Dynamic pricing settings](#dynamic-pricing-settings).

### Dynamic pricing settings

You can configure dynamic pricing using the following settings, which are set in the data plane's `kong.conf` file or as environment variables:

* `dynamic_pricing` (`KONG_DYNAMIC_PRICING`): Turns dynamic pricing on or off. The default is `on`.
  When it's `off`, the data plane prices requests only from target cost management settings.
* `dynamic_pricing_uri` (`KONG_DYNAMIC_PRICING_URI`): The location of the catalog that the data plane uses, as a URL (starting with `http://` or `https://`) or a file path (starting with `file://`).
  The data plane re-reads the catalog every 60 seconds.
  When it's unset, a {{site.konnect_short_name}} data plane gets the catalog from its control plane.

     On-prem deployments can use this setting to point the data plane at a local copy of the price catalog, for example `KONG_DYNAMIC_PRICING_URI=file:///path/to/catalog.json`.
     The catalog file uses the same format as the Konnect-managed catalog, and you can configure price overrides directly in the file.
     
     {:.info}
     > **Note**: The dynamic pricing URI can't contain credentials.
  
## Price catalog

The price catalog lists the price of each model that {{site.ai_cost_management}} can price. 
You can find it by navigating to the AI view, then opening **Cost Management** > **Price Catalog** from the sidebar.

The price catalog shows effective rates, which include your overrides.
All prices in the price catalog are in USD per million tokens.
You can filter the list by exact model ID or by provider, and open a model to see its price history.

* Models without an override show `List price` in the **Override** column.
* Models with an override show `Custom rate` or `Provider discount`.

You can click **Refresh** to load the latest list of effective rates.

### Model details

Each model in the price catalog has details with its current price and price history (up to the 50 most recent versions).
For a model with a percentage off override, the current price only shows the discounted price.
If a [rate card](#rate-cards) is applied to a model, each row shows the base input, cache write, cache read, and output rates of one card.

## Overrides

An override adjusts the list price so the catalog shows the price your organization actually pays.

You can create a rate override with the **Add override** button on the [**Price Catalog**](https://cloud.konghq.com/us/ai-manager/cost-management/price-catalog) page.

Rate overrides come in the following types:

* A [percentage off override](#percentage-off-overrides): A discount on every model of a provider.
* A [custom rate override](#custom-rate-overrides): A fixed price for one model.

### Percentage off overrides

A percentage off override takes a percentage off every list price of a provider.
The percentage applies on top of the current catalog price, so the resulting price changes when the vendor changes its list price.
This type fits a negotiated discount that covers every model of the provider.

Models that have a custom rate use the custom rate instead.

Use the **Percent off (%)** field to set the percentage to take off the list price of every model of the provider.

### Custom rate overrides

A custom rate override replaces the list price of one specific model entirely.
The rate stays fixed when the vendor changes its list price, so this type fits a contract that fixes a price regardless of what the vendor publishes.

You configure a custom rate with the following parameters.
All prices are in USD per million tokens.

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "**Model**"
    required: "Yes"
    description: "The model that the rate applies to. You can choose a model from the provider's list, or enter the ID of a custom model and select “Use” to confirm it."
  - parameter: "**Base input**"
    required: "Yes"
    description: "The price per million input tokens."
  - parameter: "**Output**"
    required: "Yes"
    description: "The price per million output tokens."
  - parameter: "**Cache reads**"
    required: "No"
    description: "The price per million tokens served from the provider's prompt cache."
  - parameter: "**Cache writes**"
    required: "No"
    description: "The price per million tokens written to the provider's prompt cache."
  - parameter: "**1-hour cache writes**"
    required: "No"
    description: "The price per million tokens written to the prompt cache with a one-hour lifetime."
  - parameter: "**Reasoning**"
    required: "No"
    description: "The price per million reasoning tokens."
  - parameter: "**Rate cards**"
    required: "No"
    description: "Prices for requests that are served differently from the standard rates. See [Rate cards](#rate-cards)."
{% endtable %}
<!--vale on-->

### Rate cards

A rate card sets different prices for more granular categories.
You can add multiple rate cards to a custom rate override by selecting **Add rate card**, and each card has its own prices.

A custom rate includes only the rate cards you add to it, so the model's list-price rate cards don't apply.

The following rate card types are available:

<!--vale off-->
{% table %}
columns:
  - title: Rate card
    key: card
  - title: Applies to
    key: applies_to
rows:
  - card: "**Flex tier**"
    applies_to: "Requests on the flex service tier."
  - card: "**Priority tier**"
    applies_to: "Requests on the priority service tier."
  - card: "**Long context**"
    applies_to: "Requests with inputs above a token threshold."
{% endtable %}
<!--vale on-->

A rate card has the following parameters.
Prices are in USD per million tokens, and a rate card needs at least one price.

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Rate card
    key: card
  - title: Description
    key: description
rows:
  - parameter: "**Base input**"
    card: "All"
    description: "The price per million input tokens."
  - parameter: "**Output**"
    card: "All"
    description: "The price per million output tokens."
  - parameter: "**Cache reads**"
    card: "All"
    description: "The price per million tokens served from the provider's prompt cache."
  - parameter: "**Cache writes**"
    card: "All"
    description: "The price per million tokens written to the provider's prompt cache."
  - parameter: "**Input over (tokens)**"
    card: "Long context"
    description: "The input size above which the card applies, as a whole number of tokens."
  - parameter: "**Applies to**"
    card: "Long context"
    description: "The requests that the card prices, such as standard or batch requests. See the [rate card types](#rate-cards)."
{% endtable %}
<!--vale on-->

For example, a custom rate can include a flex tier card and a long context card, so flex requests and long-input requests can each have their own prices.

### Override limitations

The following limitations apply to rate overrides:

* A percentage must be greater than 0 and at most 100.
* A provider can have only one active percentage off override.
* A new custom rate for a model ends the model's earlier custom rate at the time the new one takes effect.
* A custom rate can have one flex tier and one priority tier rate card.
* A custom rate can't have two long-context rate cards with the same threshold and **Applies to** value.
* You can't edit an override, so to change one, you must delete the override and create a new one.

### Set up an override

To create a rate override in the {{site.konnect_short_name}} UI:

1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**.
1. In the Cost Management sidebar, click **Price Catalog**.
1. Click **Add override**.
1. From the **Provider** dropdown menu, select your provider.
1. Select **Percentage off list** or **Custom rate**.
1. Enter the values for your override type:
   * For **Percentage off list**, in the **Percent off (%)** field, enter a percentage, for example `10`.
   * For **Custom rate**, in the **Model** field, choose a model.
   * For **Custom rate**, in the **Base input** and **Output** fields, enter your contracted prices in USD per million tokens. 
   Fill out the remaining fields as needed.
1. *(Optional)* For a **Custom rate**, add a rate card. See [Rate cards](#rate-cards) for the parameters of each type:
   1. Click **Add rate card**.
   1. Select the rate card type.
   1. Enter the prices and any other parameters for the card.
1. *(Optional)* To schedule the override, in the **Effective from** field, pick a later date and time in UTC.
1. Click **Add override**.

The new override appears on the **Provider overrides** tab.
To check the resulting price, click the **Effective rates** tab and find the model.

You can remove an override by opening it from the **Provider overrides** tab and deleting it, or by using **Revert to list price** on a model's details page.
Removing a percentage off override returns every model of the provider to its list price, and removing a custom rate returns the model to the vendor's list price.
You can't undo a deletion.
