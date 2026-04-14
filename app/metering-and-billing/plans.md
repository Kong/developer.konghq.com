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

### Grants

A grant is a record of usage allowance issued to a specific customer via a metered entitlement. Grants determine how much of a feature a customer is allowed to consume. You can interact with grants directly for precise control over how usage allowances are issued and managed.

A metered entitlement tracks a running balance. When usage is reported, it is burnt down (deducted) from the grants issued for that entitlement. When issuing a grant, you can configure multiple behaviors that affect how it participates in this balance calculation.

To automatically issue grants after each reset, set the `issueAfterReset` property on the entitlement.

#### Effective date and expiration

You can issue grants to be active in the past, present, or future (with the limit that it has to be later than the last reset time of the entitlement). The `effectiveAt` property of the grant determines when the grant becomes active; after that point the grant's balance can be burnt down by feature usage. You must define an expiration setting for the grant from which an `expiresAt` is calculated, after which no more usage can be burnt down from that grant. If a grant expires, any remaining balance it might have is lost.

{% mermaid %}
sequenceDiagram
    participant E as Entitlement
    participant G1 as Grant1
    participant G2 as Grant2
    participant U as Usage

    Note over E,G1: Balance: 100
    U->>E: Use 70
    E->>G1: Burn 70
    Note over E,G1: Balance 30
    Note over G2: Takes Effect
    Note over G2: Balance 50
    Note over E,G2: Balance 80
    Note over G1: Expires
    Note over E,G1: Balance 50
{% endmermaid %}

#### Voiding

Grants can be voided, which has the same effect as if their `expiresAt` has been reached. Voiding a grant will immediately stop any further usage from being burnt down from that grant. The remaining balance of the grant is lost.

#### Priority

Grants are burnt down in a deterministic order during balance calculation. Only grants that have a remaining balance can be burnt down; once a grant is fully consumed it is no longer considered for balance calculation. This order is reflected in `burnDownHistory`: a history segment ends either when the burn-down order changes (grant fully consumed, or becoming active/inactive) or when the entitlement is reset. The burn-down order is determined as follows:

1. First, grants with higher priority are burnt down before grants with lower priority.
1. In case of grants with the same priority, the grant that is closest to its expiration date is burnt down first.
1. In case of grants with the same priority and expiration, the grant that was created first is burnt down first.

A lower number indicates a higher priority. Priority is a single byte integer, so the range is from 0 to 255 with 0 being the highest priority.

{% mermaid %}
sequenceDiagram
    participant E as Entitlement
    participant G1 as Grant1
    participant G2 as Grant2
    participant G3 as Grant3
    participant U as Usage

    Note over G1: Priority: 1<br/>Balance: 100<br/>Expires: Today
    Note over G2: Priority: 2<br/>Balance: 100<br/>Expires: Today
    Note over G3: Priority: 2<br/>Balance: 100<br/>Expires: Tomorrow

    rect rgb(200, 220, 240)
        Note over E,U: Burn Down Sequence
        U->>E: Usage 120
        E->>G1: Burn 100
        E->>G2: Burn 20
    end
{% endmermaid %}

#### Rollover

Rollover is a special behavior determining what happens to grants at a reset. You have two properties to control rollover: `minRolloverAmount` and `maxRolloverAmount`. At a reset the grant's balance is updated using the following calculation:

```
Balance After Reset = MIN(Max Rollover Amount, MAX(Balance Before Reset, Min Rollover Amount))
```

The balance is floored at `minRolloverAmount` and capped at `maxRolloverAmount`.

Rollover lets you define how grant balance behaves across resets, which provides two sets of capabilities: first, it lets you grant usage that can roll over across resets, and second, you can issue grants that "top up" the balance after each reset. For example, if you wanted to issue additional 1000 usage from a one-time purchase that can be used for a year, you can issue a grant with `amount` and `maxRolloverAmount` set to 1000 and expiration set to 1 year. Alternatively, if you wanted to set up a starting balance of 5000 based on the usage period, you could create a grant with `amount`, `minRolloverAmount`, and `maxRolloverAmount` set to 5000, so after each reset the balance is topped up to 5000.

#### Recurrence

Recurrence is a special behavior that lets you define grants that top up their balance at a regular interval. The way this is different from configuring `minRolloverAmount` in the above example is that it's independent of the usage period and resets. For example, if you've already set up the starting balance of 5000 in the above example, but want to grant an additional 300 usage each day, you can create a grant with `amount` set to 300 and recurrence set to 1 day.

#### Example

If a system is metered by token on usage, then as part of their subscription each customer gets 10,000 tokens/month. Certain users require more tokens than this, so we are granting them an additional 100,000 tokens/year for extra fees.

We would want the customer to first use their available balance from the 10,000 tokens/month allowed balance, and if they have used all of that, then they should start using the 100,000 tokens/year balance.

This can be achieved by creating two grants:

1. Grant 1: 10,000 tokens that rolls over each month with the usage period, `priority=5`
1. Grant 2: 100,000 tokens recurring each year, `priority=10`

#### Timestamp precision

The entitlement engine stores historical usage data pre-aggregated in minute-sized chunks. Due to this, events changing the entitlement balance (issuing grants, grants recurring, executing a reset...) cannot have sub-minute precision. This is achieved by flooring the relevant timestamps when executing the actions, so they can be stored in history. This means that if you issue a grant with an `effectiveAt` of `2024-01-01T00:00:13Z`, it will be rounded to `2024-01-01T00:00:00Z` and the grant will be active from that point onwards. The same applies to expiration and recurrence settings, as well as reset `effectiveAt`.

This has some potentially unexpected consequences when using entitlements, here are some examples:

1. You do a reset on an entitlement, some usage is registered, and then you want to do another reset all in the same minute. The second reset will return an error, as due to truncation it would register at the same time as the first one, which is not allowed (you can only reset after the last reset took place).
1. You issue a grant with `effectiveAt` now and then do a reset with `effectiveAt` now, within the same minute. The reset and the grant register for the same time, so even though the grant was created before reset was called, the reset won't operate on that grant as it will be part of the next usage period, not the previous one.

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
