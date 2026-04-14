---
title: "Plans"
content_type: reference
description: "Learn how Plans work in {{site.konnect_short_name}} {{site.metering_and_billing}}, including rate cards, entitlements, pricing models, and billing cadence."
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
  - text: "Features"
    url: /metering-and-billing/features/

---

Plans are a core component of the Product Catalog. Plans define the pricing and entitlements your customers receive in {{site.konnect_short_name}} {{site.metering_and_billing}}. They act as reusable templates that describe what a customer gets and how they are charged. Each plan can include multiple phases, prices, and entitlements, and can be versioned. 

Plans can take different forms, for example: 

* $99 per month for 1 million API requests
* 10 GB storage included
* SAML or SSO support

## Rate cards

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

### Add-ons

Add-ons let you extend your plans with optional features or capacity that customers can purchase on demand. They are versioned and consist of one or more rate cards defining pricing, entitlements, and billing cadence independently of the base plan. Add-ons allow you to sell extra features, overage packs, or services without changing the core plan.

### Pricing models

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

### Tax calculations

{% include_cached /konnect/metering-and-billing/tax.md %}

### Entitlements

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

### Billing cadence

Rate cards include a billing cadence property that determines the billing frequency for the associated feature. For instance, when a usage-based rate card specifies a billing cadence of one month (`P1M`), the system generates monthly invoices reflecting that period's usage.

For flat fee rate cards, the billing cadence can be omitted. In this case, the specified fee is charged once per subscription phase rather than recurring at regular intervals.

### Price

The price property defines the price the feature is sold at. See the [Pricing models section](#pricing-models) for more details.

Free items can be implemented using three distinct approaches:

* Omitting the price setting
* Setting an explicit price of $0
* Applying a 100% discount to the standard price

Each approach has different implications:

When no price is set across all rate cards, subscriptions can be initiated without payment method information, making it suitable for free plans.

If any rate card has an explicit $0 price, payment method information is still required during subscription setup.

Using a 100% discount on the standard price provides transparency to users by displaying the original value of the feature before the discount.

## Plan versions

Plans are versioned to allow you to make changes without affecting running subscriptions. Each plan can have one published and one draft version. Editing already published plans will create a new draft version. Once you are ready, you can publish the draft version.

Subscriptions are bound to a specific version of the plan and can be migrated to a new version.

## Plan phases

A plan can have multiple phases, such as a free trial for the first 30 days and then converting to a paid plan after the 30 days are up. Each phase can have a different price and entitlement. Phases can be used to create automatic time-based offering changes, like trials, reverse trials, ramp-up phases.

Example for reverse trials with plan phases:

* Phase 1 (Trial): limited to 100,000 tokens, premium features included
* Phase 2 (Free): limited to 1,000 tokens


{% include_cached /konnect/metering-and-billing/discounts.md %}
