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

Every monetary amount in {{site.konnect_short_name}} {{site.metering_and_billing}} has a currency.
{{site.metering_and_billing}} supports two kinds of currency: fiat currencies and custom currencies.

* Fiat currencies are the currencies defined by the [ISO 4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
* Custom currencies are units of value that you define yourself, such as LLM credits or tokens, so you can price and grant things that aren't money.

Invoices are always issued in a fiat currency.
A custom currency becomes billable only once you give it a cost basis, which is an explicit rate against a fiat currency.

## Fiat currencies

A fiat currency is identified by its three-letter ISO 4217 code, such as `USD`, `EUR`, or `JPY`.
{{site.metering_and_billing}} accepts any code defined by the standard.

The standard supplies each currency's display name, symbol, precision, decimal mark, and thousands separator, so you don't configure any of these.
For example, `USD` uses two decimal places and `JPY` uses none.

Only a fiat currency can be invoiced and settled through a payment provider.

## Custom currencies

A custom currency is a unit of value that you define for your organization.
Use one when you price in something other than money, such as LLM provider credits, tokens, or compute units.

Unlike a fiat currency, a custom currency has no standard definition, so you supply its display properties yourself.
A custom currency also has no intrinsic value until you attach a cost basis to it.

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
      The four-character minimum distinguishes custom currency codes from three-letter ISO 4217 codes, so the two can't overlap.
  - property: "Name"
    required: "Yes"
    description: "The display name, between 1 and 256 characters."
  - property: "Symbol"
    required: "No"
    description: "The symbol shown next to amounts in this currency."
  - property: "Precision"
    required: "Yes"
    description: |
      The number of decimal places, from 0 to 12.
      <br><br>
      Amounts in this currency round to this precision. For example, a precision of 0 rounds amounts to whole units.
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
    description: "The fiat amount that one unit of the custom currency is worth. The rate must be a positive number. Rate amounts are expressed and formatted in the fiat currency."
  - field: "Effective from"
    description: "When the rate starts applying. Defaults to the time you create the cost basis. If you set this field, the date must be in the future. The rate already applies at this exact time."
  - field: "Effective to"
    description: "When the rate stops applying. Leave it empty for an open-ended rate. The date must come after the effective from date. The rate no longer applies at this exact time."
{% endtable %}
<!--vale on-->

Cost bases are append-only.
To change a rate, add a new cost basis for the same fiat currency.
{{site.metering_and_billing}} ends the cost basis that's active at the new cost basis's effective date by setting its effective-to date to that time.
After that time passes, the {{site.konnect_short_name}} UI shows the earlier cost basis as **Superseded**.
The rate of the superseded cost basis doesn't change, so the historical rates stay intact.

A single custom currency can carry cost bases against several fiat currencies at once.
For any one fiat currency, only one cost basis is active at a time, and its successive cost bases cover consecutive time windows.

## Where currency is set

{{site.metering_and_billing}} derives the currency of an invoice from the plan, the customer, and any rate card overrides.
The following diagram follows a charge's currency from the product catalog to the invoice:

{% mermaid %}
flowchart TB
    subgraph define["<b>1. Define</b>"]
        direction LR
        plan["<b>Plan</b><br/>Currency: fiat or custom<br/>Settlement mode"]
        rate-card["<b>Rate card</b><br/>Inherits the plan currency,<br/>or overrides a fiat plan's<br/>currency to a custom one"]
        plan --> rate-card
    end

    subgraph subscribe["<b>2. Subscribe</b>"]
        direction LR
        customer["<b>Customer</b><br/>Currency: fiat"]
        subscription["<b>Subscription</b><br/>Fixes the invoice currency:<br/>the plan's, if it's fiat<br/>the customer's, if it's custom"]
        customer --> subscription
    end

    subgraph settle["<b>3. Settle each charge</b>"]
        direction LR
        credits["<b>Credit balance</b><br/>In the charge's currency"]
        cost-basis["<b>Cost basis</b><br/>Converts the custom<br/>currency into the<br/>invoice currency"]
    end

    invoice["<b>4. Invoice</b><br/>In the invoice currency<br/>Always fiat, rounded<br/>to its precision"]

    define --> subscribe
    subscribe -->|"Charges draw on credits first"| credits
    credits -->|"credit_only: settled here"| done(["No invoice line<br/>A shortfall becomes<br/>a negative balance"])
    credits -->|"credit_then_invoice:<br/>remaining custom amount"| cost-basis
    credits -->|"credit_then_invoice:<br/>remaining fiat amount"| invoice
    cost-basis --> invoice
{% endmermaid %}

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
    notes: |
      A plan's currency becomes read-only after you create the plan.
      The currency can be fiat or custom.
      <br>
      * A fiat-currency plan contains only that one fiat currency, though individual rate cards can override it to set a custom currency.
      * A custom-currency plan contains no fiat currency at all, and its subscriptions are invoiced in the customer's currency.

      <br><br>
      When the plan uses [`credit_then_invoice`](/metering-and-billing/credits/#settlement-modes) settlement, the custom currency needs a cost basis that's active against the customer's currency when the subscription starts.
      The custom currency's cost bases therefore determine which customers can subscribe.
  - entity: "Add-on"
    who: "You, when you create the add-on"
    notes: |
      An add-on's currency becomes read-only after you create the add-on.
      <br>
      * On a fiat-currency plan, the add-on can use the plan's fiat currency or a custom currency. Its rate cards can also use a custom currency under the same override rules as the plan's rate cards.
      * On a custom-currency plan, the add-on's priced rate cards must use the plan's custom currency.

      <br><br>
      A priced add-on rate card that shares its key with a priced plan rate card must keep that rate card's currency.
  - entity: "Rate card"
    who: "You, as an optional override"
    notes: |
      The rate card inherits the plan or add-on currency unless you override it.
      You can only override a fiat currency, and only with a custom currency.
  - entity: "Subscription"
    who: "Derived from the plan, or from the customer for a custom-currency plan"
    notes: |
      The invoice currency is the plan's currency when the plan is priced in a fiat currency.
      When the plan is priced in a custom currency, the invoice currency comes from the customer instead, so the customer must already have a currency set.
      Either way, the invoice currency has to agree with the customer's currency, and it can't be changed after the subscription starts.
  - entity: "Invoice"
    who: "Derived from the subscription"
    notes: |
      The invoice currency is always a fiat currency.
      {{site.metering_and_billing}} converts custom-currency charges through their cost basis before adding them to the invoice.
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
* The custom currency needs a cost basis that's active against the plan's fiat currency, unless the plan uses the `credit_only` settlement mode.

## Rounding

{{site.metering_and_billing}} rounds every monetary amount to the precision of its currency, rounding halves away from zero.

Rounding applies at each stage of the calculation, including the invoice total.
{{site.metering_and_billing}} rounds individual line items, pricing tiers, and discount or commitment adjustments to the currency's precision, and then rounds the resulting totals again.
For a custom-currency amount, {{site.metering_and_billing}} converts the amount through its cost basis and rounds the result to the precision of the fiat currency.

## Currency constraints

Keep the following constraints in mind when you plan your product catalog:

* An invoice covers a single currency. If a customer is migrated between currencies, they can have one gathering invoice per currency.
* A subscription's invoice currency is fixed for the life of the subscription.
* There is no exchange rate between fiat currencies. To sell in several fiat currencies, create one plan per currency, or price a plan in a custom currency that has a cost basis for each fiat currency you sell in.
* A custom currency is immutable and can't be deleted after you create it.
* Custom currencies are only available through the v3 API. The v1 API rejects resources that use a custom currency.

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
    meaning: "The custom currency has no active cost basis for the fiat currency it needs to convert into: the plan's currency for a rate card override, or the customer's currency for a subscription to a custom-currency plan."
  - code: "`plan_multiple_fiat_currencies`"
    meaning: "A plan can't contain more than one fiat currency."
  - code: "`plan_addon_currency_mismatch`"
    meaning: "An add-on rate card would change the currency of a plan rate card with the same key."
  - code: "`rate_card_currency_override_not_allowed`"
    meaning: "The rate card already uses a custom currency, so it can't be overridden."
  - code: "`rate_card_currency_override_redundant`"
    meaning: "The override matches the currency it would replace."
  - code: "`rate_card_currency_requires_price`"
    meaning: "A rate card with a currency override must define a price."
  - code: "`currency_not_representable`"
    meaning: "The resource uses a custom currency, which isn't supported by the v1 API."
  - code: "`rate_card_currency_not_representable`"
    meaning: "The rate card uses a custom-currency override, which isn't supported by the v1 API."
{% endtable %}
<!--vale on-->

Creating a custom currency with a code that already exists in your organization returns a conflict error instead of a validation error.
