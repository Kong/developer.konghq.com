---
title: "Product Catalog"
content_type: reference
description: "Learn how the Product Catalog work in {{site.konnect_short_name}} {{site.metering_and_billing}} and how they relate to usage tracking and external billing systems."
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
  - text: "Subjects"
    url: /metering-and-billing/subjects/

---


{{site.konnect_short_name}} {{site.metering_and_billing}}'s Product Catalog lets you centrally define the different plans and plan features that make up your offering—so you can manage pricing, entitlements, and packaging in one place. 

Each Product Catalog plan consists of:
* [Features](#features) that you want to price or govern. Can be metered or static.
* [Rate cards](#rate-cards) that determine which features ([entitlements](#entitlements)) and how much of the feature a subscriber can access ([pricing models](#pricing-models))
* Optional [add-ons](#add-ons) that allow customers to purchase additional usage or features on demand

For example, say you're metering API Gateway requests for your API and you want to charge customers based on API usage, you might configure your plans like the following:

{% mermaid %}
flowchart TB
 subgraph free-plan["<b>Free Plan</b>"]
    direction TB
        subgraph feature-free["<b>Feature</b>"]
            direction TB
            meter-free["Meter<br/>(API requests)"]
        end
        rate-card-free["Rate Card<br/>(10 requests/month)"]
        entitlement-free["Entitlement (Metered)"]
  end
  
 subgraph premium-plan["<b>Premium Plan</b>"]
    direction TB
        subgraph feature-premium["<b>Feature</b>"]
            direction TB
            meter-premium["Meter<br/>(API requests)"]
        end
        rate-card-premium["Rate Card<br/>(1000 requests/month)"]
        entitlement-premium["Entitlement (Metered)"]
        addon["<b>Add-on</b><br> (1000 additional requests)"]
  end
  
    meter-free ~~~ rate-card-free
    rate-card-free ~~~ entitlement-free
    
    meter-premium ~~~ rate-card-premium
    rate-card-premium ~~~ entitlement-premium
    entitlement-premium ~~~ addon
{% endmermaid %}


## Features

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

## Plans

Plans are a core component of the Product Catalog. Plans define the pricing and entitlements your customers receive in {{site.konnect_short_name}} {{site.metering_and_billing}}. They act as reusable templates that describe what a customer gets and how they are charged. Each plan can include multiple phases, prices, and entitlements, and can be versioned. 

Plans can take different forms, for example: 

* $99 per month for 1 million API requests
* 10 GB storage included
* SAML or SSO support

### Rate cards

Plans are built from rate cards, which determine which features a plan can access, the price, and how much of a feature they can use (called entitlements). Rate Cards define the configuration of features that subscribers will be entitled to and charged for.

For example, to set up the previous example plan, you'd use the following rate cards:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Price
    key: price
  - title: Entitlement
    key: entitlement
rows:
  - feature: AI Tokens
    price: "$99/m"
    entitlement: "1,000,000 /m"
  - feature: Storage
    price: "$0/m"
    entitlement: "10 GB /m"
  - feature: SAML SSO
    price: "$0/m"
    entitlement: "True"
{% endtable %}

Rate cards can be configured with or without a feature:

* **With a feature:** Rate cards with features can be priced as recurring, one-time flat, or usage-based. Rate cards with features can have an entitlement to control access. When the associated feature has a meter, the rate card can describe usage limits.
* **Without a feature:** Rate cards without features can only have a flat-fee price. Rate cards without features don't have an entitlement to control access.

#### Add-ons

Add-ons let you extend your plans with optional features or capacity that customers can purchase on demand. They are versioned and consist of one or more rate cards defining pricing, entitlements, and billing cadence independently of the base plan. Add-ons allow you to sell extra features, overage packs, or services without changing the core plan.

#### Pricing models

Rate cards offer several different pricing models, listed in the following table:

{% table %}
columns:
  - title: Pricing model
    key: model
  - title: Description
    key: description
rows:
  - model: "Free"
    description: "Free pricing"
  - model: "Flat fee"
    description: "A one-time or recurring fee"
  - model: "Usage based"
    description: "Linear pricing based on metered usage"
  - model: "Tiered"
    description: "Tiered pricing based on metered usage"
  - model: "Package"
    description: "Pricing based on fixed-sized usage packages"
  - model: "Dynamic"
    description: "USD prices created dynamically from meter values"
{% endtable %}

Besides the **Free** pricing model, other models require configuration that you can see from the {{site.konnect_short_name}} UI. 

#### Tax calculations

{% include_cached /konnect/metering-and-billing/tax.md %}

#### Entitlements

Entitlements are used to control access to different features, they make it possible to implement complex pricing scenarios such as monthly quotas, prepaid billing, and per-customer pricing.

Entitlements can help you implement various monetization strategies:
* Enforce usage limits, like monthly token allowances.
* Sell plans with various feature sets.
* Offer custom quotes and per-customer pricing.
* Adopt prepaid billing and grant usage, and handle top-ups.
* Define and track pre-purchase commitments.

There are three different types of entitlements:

{% table %}
columns:
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - type: Metered
    description: |
      Allow customers to consume features up to a certain usage limit, e.g., 10 million monthly tokens.

      This is useful for example when the underlying resources are expensive, as is the case for most AI products. Metered entitlements leverage the usage information collected by {{site.metering_and_billing}} and give you the ability to do real time usage enforcement as well as historical queries and access checks.
  - type: Static
    description: |
      Define customer-specific configurations as a JSON value. e.g. `{ "enabledModels": ["gpt-3", "gpt-4"] }`

      For example, you may only give free users access to a subset of AI models. With static entitlements, you can specify which models the customer can use based on their tier.
  - type: Boolean
    description: |
      Describe access to specific features, like SAML SSO, without needing configuration or metering.

      In cases where you don't need to set up usage limits or configure customer level settings you can use boolean entitlements. These are simple true or false access grants to a feature. 
{% endtable %}

### Plan versions

Plans are versioned to allow you to make changes without affecting running subscriptions. Each plan can have one published and one draft version. Editing already published plans will create a new draft version. Once you are ready, you can publish the draft version.

Subscriptions are bound to a specific version of the plan and can be migrated to a new version.

### Plan phases

A plan can have multiple phases, such as a free trial for the first 30 days and then converting to a paid plan after the 30 days are up. Each phase can have a different price and entitlement. Phases can be used to create automatic time-based offering changes, like trials, reverse trials, ramp-up phases.

Example for reverse trials with plan phases:

* Phase 1 (Trial): limited to 100,000 tokens, premium features included
* Phase 2 (Free): limited to 1,000 tokens


{% include_cached /konnect/metering-and-billing/discounts.md %}


## Subscriptions

{{site.konnect_short_name}} {{site.metering_and_billing}} [subscriptions](/metering-and-billing/billing-invoicing-subscriptions/#subscriptions) link your [Customers](/metering-and-billing/customer/) to plans, and [meters](/metering-and-billing/metering/).
