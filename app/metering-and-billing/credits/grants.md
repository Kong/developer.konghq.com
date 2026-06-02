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
  - text: "Credit balance model"
    url: /metering-and-billing/credits/balance-model/
  - text: "Credit consumption and expiration"
    url: /metering-and-billing/credits/consumption-and-expiration/
  - text: "Credit transaction history"
    url: /metering-and-billing/credits/transaction-history/
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

Every grant has an amount and a currency.
A grant can also define how it is funded, when unused credits expire, and how {{site.metering_and_billing}} prioritizes it against other grants during consumption.

## Funding methods

The funding method describes how the customer receives or pays for the credits.

### Promotional credits

Use promotional credits when no payment workflow applies.
Common examples include onboarding credit, compensation credit, migration credit, or admin-created credit.

Promotional credits are available without waiting for an invoice or external payment reconciliation.

### Invoice-funded credits

Use invoice-funded credits when a customer buys credits through {{site.metering_and_billing}} billing.

In this flow, the grant represents the credits the customer receives, and the invoice represents the payment workflow for those credits.
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

Lower priority values are consumed first.
If two grants have the same priority, credits that expire earlier are consumed first.
If priority and expiration are the same, {{site.metering_and_billing}} uses stable movement order.

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

## Purchase and tax context

Purchase terms describe how the credits are funded.
They define the purchase currency and the per-unit cost used to calculate the purchase amount.

Tax configuration is relevant for revenue recognition on the usage charges that consume credits.
Set tax configuration on all usage charges that need to be classified correctly for revenue recognition.
