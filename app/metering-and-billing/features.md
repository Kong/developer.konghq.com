---
title: "Features"
content_type: reference
description: "Learn how Features work in {{site.konnect_short_name}} {{site.metering_and_billing}} and how they relate to usage tracking and pricing."
layout: reference
products:
  - metering-and-billing
tools:
    - konnect-api
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: "Product Catalog"
    url: /metering-and-billing/product-catalog/
  - text: "Plans"
    url: /metering-and-billing/plans/

---

Features are part of your product offering and the building blocks of your plans and entitlements. They are the resource you want to govern and invoice for. For example, LLM Models, tokens, storage units. Features are associated with a meter, so that you can connect usage to a feature that you can then charge for.

Features are the building blocks of your product offering, they represent the various capabilities of your system. Practically speaking, they typically translate to line items on your pricing page and show up on the invoice.

The feature set between plans can vary in terms of what features are available, what configurations are available for a given feature, and what usage limits are enforced. 

The following table details an example for a fictional AI startup:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Free plan
    key: plan1
  - title: Premium plan
    key: plan2
rows:
  - feature: "GPT Tokens"
    plan1: "10,000 /m"
    plan2: "1,000,000 /m"
  - feature: "Available models"
    plan1: gpt-3
    plan2: "gpt-3, gpt-4"
  - feature: "SAML SSO auth"
    plan1: "-"
    plan2: "Yes"
{% endtable %}

Features can be archived, after which no new entitlements can be created for them, but the existing entitlement are left intact. You can think of this as deprecating a feature, removing it from the pricing page, or migrating it to a new name (key).

## Unit cost

You can attach a per-unit cost to a feature to calculate the total cost of usage. This is useful for tracking infrastructure costs, understanding margins, and analyzing spending across customers. Once configured, you can query and visualize costs in [Cost Analytics](/metering-and-billing/cost-analytics/).

{:.warning}
> **Unit Cost is your internal cost:** To invoice customers and collect revenue use [rate cards](/metering-and-billing/plans/#rate-cards).


There are two types of unit costs: manual and LLM.

### Manual unit cost

Manual unit cost is a fixed, per-unit cost amount in USD. 
Use this when the cost per unit is constant, for example:
* $0.005 per API request
* $0.10 per compute minute
* $1.00 per agent run

### LLM unit cost

LLM unit cost uses the built-in [LLM cost database](/metering-and-billing/cost-analytics/#llm-cost-database) to lookup the cost. 
The cost per token is automatically resolved based on the LLM provider, model, and token type. 
This is ideal for AI products where token pricing varies by model.

LLM unit costs can either be static or dynamic:

<!--vale off-->
{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
  - title: When to use
    key: when
rows:
  - mode: Static
    description: "Specify fixed values for provider, model, and/or token type. For example, set provider to `openai`, model to `gpt-4`, and token type to `input`."
    when: "The feature tracks a single provider, model, or token type."
  - mode: Dynamic
    description: "Map provider, model, and/or token type from meter group-by properties. For example, map provider from the meter's `provider` dimension and model from the `model` dimension."
    when: "The feature's meter tracks multiple providers or models via group-by dimensions."
{% endtable %}
<!--vale on-->

The following fields are available for LLM unit cost configuration:

{% table %}
columns:
  - title: Static field
    key: static
  - title: Dynamic field
    key: dynamic
  - title: Description
    key: description
rows:
  - static: Provider
    dynamic: Provider property
    description: "The LLM provider (for example, `openai`, `anthropic`). Static sets a fixed value, dynamic reads from a meter group-by dimension."
  - static: Model
    dynamic: Model property
    description: "The model ID (for example, `gpt-4`, `claude-3-5-sonnet`). Static sets a fixed value, dynamic reads from a meter group-by dimension."
  - static: Token type
    dynamic: Token type property
    description: "The token type (for example, `input`, `output`, `cache_read`, `reasoning`). Static sets a fixed value, dynamic reads from a meter group-by dimension."
{% endtable %}
