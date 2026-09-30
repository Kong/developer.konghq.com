---
title: "Credit grants"
content_type: reference
beta: true
description: "Learn how credit grants work in {{site.konnect_short_name}} {{site.metering_and_billing}}: funding methods, priority, and expiration."
layout: reference
products:
  - metering-and-billing
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
  - /metering-and-billing/credits/
tags:
  - billing
  - credits
related_resources:
  - text: "Prepaid credits overview"
    url: /metering-and-billing/credits/
  - text: "Currencies"
    url: /metering-and-billing/currencies/
  - text: "Credit balance model"
    url: /metering-and-billing/credits/balance-model/
  - text: "Credit consumption and expiration"
    url: /metering-and-billing/credits/consumption-and-expiration/
  - text: "Credit transaction history"
    url: /metering-and-billing/credits/transaction-history/
  - text: "Feature filters"
    url: /metering-and-billing/credits/feature-filters/
  - text: "Operational flows"
    url: /metering-and-billing/credits/operational-flows/
  - text: "Correctness guarantees"
    url: /metering-and-billing/credits/correctness-guarantee/
  - text: "Get started with prepaid credits"
    url: /how-to/get-started-with-prepaid-credits/
next_steps:
  - text: Learn about credit consumption and expiration
    url: /metering-and-billing/credits/consumption-and-expiration/
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---

A credit grant adds credits to a customer balance.
Grants are the main way to create prepaid or promotional credit.

Every grant has an amount and a [currency](/metering-and-billing/currencies/).
The currency can be a fiat currency or a [custom currency](/metering-and-billing/currencies/#custom-currencies), such as credits or tokens you define for your organization.
A grant can also define how it's funded, when unused credits expire, and how {{site.metering_and_billing}} prioritizes it against other grants during consumption.

## Funding methods

The funding method describes how the customer receives or pays for the credits.

### Promotional credits

Use promotional credits when no payment workflow applies.
Common examples include onboarding credit, compensation credit, migration credit, or admin-created credit.

Promotional credits don't involve any payment.

### Invoice-funded credits

Use invoice-funded credits when a customer buys credits through {{site.metering_and_billing}} billing.

In this flow, the grant represents the credits the customer receives, and the invoice represents the payment workflow for those credits.
The credits are available as soon as the grant takes effect.
They don't wait for the invoice to be paid.
The credit amount and the purchase amount are related but not necessarily identical.

For example, if a customer receives 100 credits with a per-unit cost of 0.50 USD, the invoice amount is 50 USD.

```text
credit amount:       100 credits
per-unit cost:      0.50 USD
purchase amount:   50.00 USD
```
{:.no-copy-code}

This distinction is important for discounts, commitments, negotiated rates, and cases where the commercial price of a credit differs from its face value.

### Externally funded credits

Use externally funded credits when invoicing and payment happen outside {{site.metering_and_billing}} through custom invoicing.

The grant records the credits in {{site.metering_and_billing}}.
Your integration is responsible for updating {{site.metering_and_billing}} when the external payment state changes.

## Priority

Priority controls which credits are consumed first when a customer has multiple grants in the same currency.

Priority is a number from 1 to 1000 through the API, or from 1 to 100 in the {{site.konnect_short_name}} UI. The default is 10.
Lower priority values are consumed first.
If two grants have the same priority, a grant restricted to specific features or plans is consumed before an unrestricted grant.
Then credits that expire earlier are consumed first.
If priority, restrictions, and expiration are equal, {{site.metering_and_billing}} uses stable movement order.

Example:

<!--vale off-->
{% table %}
columns:
  - title: Grant
    key: grant
  - title: Priority
    key: priority
  - title: Expires
    key: expires
  - title: Amount
    key: amount
rows:
  - grant: "A"
    priority: "1"
    expires: "T10"
    amount: "100"
  - grant: "B"
    priority: "1"
    expires: "T20"
    amount: "100"
  - grant: "C"
    priority: "2"
    expires: "never"
    amount: "100"
{% endtable %}
<!--vale on-->

If the customer consumes 150 credits, {{site.metering_and_billing}} consumes all of A, then 50 from B.
C is not touched because its priority value is higher.

## Expiration

A grant can expire after a configured duration.
Expiration applies only to unused credits.
If a customer uses part of the grant before expiration, only the remaining unused amount expires.

For example, a 100 credit grant expires after 30 days.
If the customer uses 40 credits before then, the remaining 60 credits expire at the expiration time.

```text
grant:      +100
consumed:    -40
expired:     -60
```
{:.no-copy-code}

## Feature restrictions

You can restrict a grant to one or more product features using the feature filters through the `filters.features` field.
Restricted credits can only be consumed by charges for the specified features.
Credits without a feature restriction are shared and available to all features.

For details on how feature restrictions affect balance and transaction queries, see [Feature filters](/metering-and-billing/credits/feature-filters/).

## Purchase and tax context

Purchase terms describe how the credits are funded.
They define the purchase currency and the per-unit cost used to calculate the purchase amount.

The purchase currency must be a fiat currency.
For a paid fiat-currency grant, it must be the same as the grant currency.
For a custom-currency grant, it must be the same as the fiat currency of the grant's cost basis.
The {{site.konnect_short_name}} UI uses the customer's currency as the purchase currency.

When the granted credits are in a custom currency, the purchase converts the custom-currency amount into the fiat purchase amount through a cost basis:

```text
grant currency:     100 credits (custom currency)
cost basis rate:    1 credit = 0.50 USD
purchase amount:   50.00 USD
```
{:.no-copy-code}

A purchase that funds a custom-currency grant needs an explicit cost basis in `purchase.cost_basis`, with `fiat_currency` set to the purchase currency.
You can define the cost basis in one of the following ways:

<!--vale off-->
{% table %}
columns:
  - title: Cost basis type
    key: type
  - title: Description
    key: description
rows:
  - type: "`dynamic`"
    description: "The rate is resolved from the custom currency's cost basis that is effective at the grant's effective time. That cost basis must already be effective by then. Use this when you want the purchase to follow the currency's current rate."
  - type: "`pinned`"
    description: "The rate is pinned to a specific cost basis of the custom currency, set with `cost_basis_id`, so later rate changes don't affect the purchase."
  - type: "`manual`"
    description: "You provide an explicit `rate` for this purchase, independent of the currency's cost bases."
{% endtable %}
<!--vale on-->

For a custom-currency grant, the {{site.konnect_short_name}} UI sends a `dynamic` cost basis when you keep the currency's current rate, and a `manual` one when you change the rate.

For a fiat-currency grant, `purchase.cost_basis` only accepts the `manual` type, without `fiat_currency`, where `rate` is the fiat cost per credit.
If you omit it, the rate defaults to 1.

{:.info}
> The older `purchase.per_unit_cost_basis` field is deprecated.
> It only applies to fiat-currency grants and can't be combined with `purchase.cost_basis`.
> Use `purchase.cost_basis` with the `manual` type instead.

Tax configuration is relevant for revenue recognition on usage charges that consume credits.
Set [tax configuration](/metering-and-billing/tax-codes/) on all usage charges that need to be classified correctly for revenue recognition.
