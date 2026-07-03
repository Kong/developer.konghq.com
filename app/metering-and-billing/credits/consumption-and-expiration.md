---
title: "Credit consumption and expiration"
content_type: reference
beta: true
description: "Learn how credits are consumed by charges and how unused credits expire in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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
  - text: "Credit grants"
    url: /metering-and-billing/credits/grants/
  - text: "Credit transaction history"
    url: /metering-and-billing/credits/transaction-history/
  - text: "Operational flows"
    url: /metering-and-billing/credits/operational-flows/
  - text: "Correctness guarantees"
    url: /metering-and-billing/credits/correctness-guarantee/
  - text: "Get started with prepaid credits"
    url: /how-to/get-started-with-prepaid-credits/
next_steps:
  - text: Learn about credit transaction history
    url: /metering-and-billing/credits/transaction-history/
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---

Credits are consumed by charges.
A charge can represent a flat fee, usage-based spend, or another billable item configured to settle with customer credits.

## Credit settlement modes

The rate card's settlement mode controls whether {{site.metering_and_billing}} consumes credits, invoices the customer, or both.

### Credit then invoice

With `credit_then_invoice`, {{site.metering_and_billing}} applies credits first.
If the customer does not have enough credits, the remaining amount is invoiced.

```text
charge amount:       100 USD
credit balance:       40 USD
credits consumed:     40 USD
invoice remainder:    60 USD
```
{:.no-copy-code}

This is the common prepaid-plus-overage model.
Customers can use prepaid credits, but usage is not blocked if credits run out.

### Credit only

With `credit_only`, the charge is settled exclusively against credits.
If the credit balance is insufficient, the charge is blocked and no invoice overage is generated.

```text
charge amount:       100 USD
credit balance:      100 USD
credits consumed:    100 USD
invoice remainder:     0 USD
```
{:.no-copy-code}

## Draw-down order

When a customer has multiple grants in the same currency, {{site.metering_and_billing}} consumes credits in a deterministic order:

```text
priority asc
expires_at asc
stable movement order asc
```
{:.no-copy-code}

This means:

1. Grants with lower priority values are consumed first.
1. For equal priority, credits that expire earlier are consumed first.
1. If both are equal, {{site.metering_and_billing}} uses stable movement order.

This order makes the result predictable and prevents avoidable expiration: if two grants have the same priority, the one expiring sooner is used first.

## Draw-down example

Assume a customer has three grants:

<!--vale off-->
{% table %}
columns:
  - title: Grant
    key: grant
  - title: Priority
    key: priority
  - title: Expires
    key: expires
  - title: Available amount
    key: amount
rows:
  - grant: "A"
    priority: "1"
    expires: "T10"
    amount: "50"
  - grant: "B"
    priority: "1"
    expires: "T20"
    amount: "80"
  - grant: "C"
    priority: "2"
    expires: "never"
    amount: "100"
{% endtable %}
<!--vale on-->

The customer incurs a 90 credit charge. {{site.metering_and_billing}} consumes:

<!--vale off-->
{% table %}
columns:
  - title: Grant
    key: grant
  - title: Consumed
    key: consumed
rows:
  - grant: "A"
    consumed: "50"
  - grant: "B"
    consumed: "40"
  - grant: "C"
    consumed: "0"
{% endtable %}
<!--vale on-->

Grant A is consumed first because it has the same priority as B but expires earlier.
Grant C is untouched because its priority value is higher.

## Credit expiration

Credit expiration removes unused credits from a customer balance at the grant's expiration time.
Credits that were already consumed don't expire later, because they are no longer part of the customer's remaining balance.

### Basic expiration

Assume a customer receives 100 credits that expire at T10.
If the customer does not use any credits before T10, all 100 credits expire at T10.

```text
T1:  +100 funded
T10: -100 expired
```
{:.no-copy-code}

The settled balance is 100 before T10 and 0 at T10.

### Partial usage before expiration

If the customer uses some credits before expiration, only the unused amount expires.

```text
T1:  +100 funded
T5:   -30 consumed
T10:  -70 expired
```
{:.no-copy-code}

The customer used 30 credits, so those 30 credits don't expire.
The remaining 70 credits expire at T10.

### Why expiration follows consumption order

When multiple grants exist, {{site.metering_and_billing}} consumes credits in a deterministic order.
That order also determines which future expiration is reduced when credits are used.

If one grant expires earlier than another grant with the same priority, the earlier-expiring grant is consumed first.
That means its future expiration is reduced first.

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
    amount: "50"
  - grant: "B"
    priority: "1"
    expires: "T20"
    amount: "50"
{% endtable %}
<!--vale on-->

If the customer consumes 30 credits before T10, those credits come from grant A. At T10, only 20 credits from A expire.

```text
T1:  grant A +50, expires T10
T1:  grant B +50, expires T20
T5:  consume 30 from A
T10: expire 20 from A
```
{:.no-copy-code}

Grant B is still available because A had the same priority and an earlier expiration.

## Transaction history

When a charge is processed, a `consumed` movement is recorded for each grant drawn from.
When a grant expires, an `expired` movement is recorded for the remaining unused amount.

Both movement types appear as negative values in [credit transaction history](/metering-and-billing/credits/transaction-history/).
Expiration is visible only when the expiration time is visible to the query: a balance read before the expiration timestamp doesn't include that future expiration.
