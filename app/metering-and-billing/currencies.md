---
title: "Currencies"
content_type: reference
description: "Learn how fiat and custom currencies work in {{site.konnect_short_name}} {{site.metering_and_billing}}, including cost bases, precision, and where each currency is set."
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
  - text: "Billing and invoicing"
    url: /metering-and-billing/billing-invoicing/
  - text: "Pricing models"
    url: /metering-and-billing/pricing-models/
  - text: "Create a custom currency"
    url: /how-to/configure-metering-and-billing-custom-currencies/
  - text: "Credit grants"
    url: /metering-and-billing/credits/grants/
---

Every monetary amount in {{site.konnect_short_name}} {{site.metering_and_billing}} carries a currency.
{{site.metering_and_billing}} supports two kinds: fiat currencies, which are the real-world currencies defined by the ISO 4217 standard, and custom currencies, which you define yourself to price and grant units of value that aren't money.

Invoices are always issued in a fiat currency.
A custom currency becomes billable only once you give it a cost basis, which is an explicit rate against a fiat currency.

## Fiat currencies

A fiat currency is identified by its three-letter ISO 4217 code, such as `USD`, `EUR`, or `JPY`.
Any code defined by the standard is accepted.

The standard supplies each currency's display name, symbol, precision, decimal mark, and thousands separator, so you don't configure any of these.
Precision is the number of decimal places the currency uses.
Most currencies use two, and zero-decimal currencies such as `JPY` use none, which means amounts in those currencies are rounded to whole units.

Only a fiat currency can be invoiced and settled through a payment provider.

## Custom currencies

A custom currency is a unit of value that you define for your organization.
Use one when you price in something other than money, such as credits, tokens, or compute units.

Unlike a fiat currency, a custom currency has no standard definition, so you supply its display properties yourself, and it has no intrinsic value until you attach a cost basis to it.

A custom currency has the following properties:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - property: "Code"
    required: "Yes"
    description: |
      The identifier for the currency, between 4 and 24 characters.
      It must not match an ISO 4217 code, must not contain the `|` character, and must not have leading or trailing spaces.
      The length is what distinguishes a custom currency from a fiat one, so a four-character minimum keeps the two sets from colliding.
  - property: "Name"
    required: "Yes"
    description: "The display name, between 1 and 256 characters."
  - property: "Symbol"
    required: "No"
    description: "The symbol shown next to amounts in this currency."
  - property: "Precision"
    required: "Yes"
    description: "The number of decimal places, from 0 to 12."
  - property: "Decimal mark"
    required: "Yes"
    description: "The single character that separates the whole and fractional parts of an amount."
  - property: "Thousand separator"
    required: "Yes"
    description: "The single character that groups digits in the whole part of an amount."
{% endtable %}
<!--vale on-->

{:.info}
> **Note:** A custom currency is immutable. After you create one, you can't change its properties or delete it.
> Its cost bases are separate resources that you can keep adding to over time.

## Cost basis

A cost basis is a rate that converts one unit of a custom currency into an amount of a fiat currency.
It's the only conversion mechanism in {{site.metering_and_billing}}.
There is no automatic foreign exchange, and no conversion between two fiat currencies or between two custom currencies.

Each cost basis records the following:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "Fiat currency"
    description: "The fiat currency that the rate converts into."
  - field: "Rate"
    description: "The fiat amount that one unit of the custom currency is worth. Rate amounts are expressed and formatted in the fiat currency, not the custom one."
  - field: "Effective from"
    description: "When the rate starts applying. Defaults to the time you create the cost basis."
  - field: "Effective to"
    description: "When the rate stops applying. Leave it empty for an open-ended rate."
{% endtable %}
<!--vale on-->

Cost bases are append-only.
To change a rate, add a new cost basis with a later effective date rather than editing the existing one, which keeps the historical rates intact for past invoices.
A single custom currency can carry several cost bases at once, either against different fiat currencies or across different time windows for the same fiat currency.

## Where currency is set

{{site.metering_and_billing}} derives the currency of an invoice from the plan, the customer, and any rate card overrides.
The following table describes where each currency value comes from:

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Who sets it
    key: who
  - title: Notes
    key: notes
rows:
  - entity: "Customer"
    who: "You, or {{site.metering_and_billing}} when the customer's first paid subscription starts"
    notes: |
      Must be a fiat currency.
      If the customer has no currency when you start their first paid subscription, {{site.metering_and_billing}} sets it to that subscription's invoice currency.
      A customer without a currency can't be granted credits.
  - entity: "Plan"
    who: "You, when you create the plan"
    notes: "Read-only after the plan exists. A plan can contain only one fiat currency."
  - entity: "Add-on"
    who: "You, when you create the add-on"
    notes: "Read-only after the add-on exists. Must match the currency of any plan it's attached to."
  - entity: "Rate card"
    who: "You, as an optional override"
    notes: "Inherits the plan or add-on currency unless you override it. Can only be overridden to a custom currency."
  - entity: "Subscription"
    who: "Derived from the plan, or from the customer for a custom-currency plan"
    notes: |
      The invoice currency is the plan's currency when the plan is priced in a fiat currency.
      When the plan is priced in a custom currency, the invoice currency comes from the customer instead, so the customer must already have a currency set.
      Either way, the invoice currency has to agree with the customer's currency, and it can't be changed after the subscription starts.
  - entity: "Invoice"
    who: "Derived from the subscription"
    notes: "Always a fiat currency. Custom-currency charges are converted through their cost basis before they reach the invoice."
  - entity: "Credit grant"
    who: "You, when you create the grant"
    notes: "The granted balance can be in a custom currency. The purchase that funds it always settles in a fiat currency."
{% endtable %}
<!--vale on-->

### Rate card overrides

A rate card can override the currency it inherits, within these rules:

* If the plan or add-on uses a fiat currency, you can override a rate card to a custom currency.
* You can't override one fiat currency with another fiat currency, because a plan can hold only one fiat currency.
* You can't override a rate card that already inherits a custom currency.
* The override must differ from the currency it replaces.
* The custom currency needs a cost basis that's active against the plan's fiat currency, unless the rate card settles in credits only.

## Rounding

{{site.metering_and_billing}} rounds every monetary amount to the precision of its currency, rounding halves away from zero.

Rounding is applied at each stage of the calculation, not only on the invoice total.
Individual line items, pricing tiers, and discount or commitment adjustments are each rounded to the currency's precision, and the resulting totals are rounded again.
A custom-currency amount is converted through its cost basis and then rounded to the precision of the fiat currency it converts into.

## Currency constraints

Keep the following constraints in mind when you plan your product catalog:

* An invoice covers a single currency. If a customer is migrated between currencies, they can have one gathering invoice per currency.
* A subscription's invoice currency is fixed for the life of the subscription.
* There is no exchange rate between fiat currencies. To sell in several fiat currencies, create one plan per currency.
* A custom currency is immutable and can't be deleted after you create it.

## Validation errors

The following errors are specific to currency configuration:

<!--vale off-->
{% table %}
columns:
  - title: Code
    key: code
  - title: Meaning
    key: meaning
rows:
  - code: "`currency_invalid`"
    meaning: "The currency code isn't a valid fiat or custom currency code."
  - code: "`currency_not_found`"
    meaning: "The referenced currency doesn't exist in your organization."
  - code: "`currency_cost_basis_not_found`"
    meaning: "The custom currency has no cost basis for the plan's fiat currency."
  - code: "`plan_multiple_fiat_currencies`"
    meaning: "A plan can't contain more than one fiat currency."
  - code: "`rate_card_currency_override_not_allowed`"
    meaning: "The rate card already uses a custom currency, so it can't be overridden."
  - code: "`rate_card_currency_override_redundant`"
    meaning: "The override matches the currency it would replace."
  - code: "`rate_card_currency_requires_price`"
    meaning: "A rate card with a currency override must define a price."
{% endtable %}
<!--vale on-->
