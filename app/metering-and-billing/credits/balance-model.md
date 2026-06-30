---
title: "Credit balance model"
content_type: reference
beta: true
description: "Understand the two credit balance types in {{site.konnect_short_name}} {{site.metering_and_billing}}: settled and pending."
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
  - text: "Credit grants"
    url: /metering-and-billing/credits/grants/
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
  - text: Learn about credit grants
    url: /metering-and-billing/credits/grants/
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---


There are two concepts to a credit balance:

* **Settled balance** is the balance from committed ledger movements. It is the durable record of what has happened.
* **Pending balance** is a live view that starts from the settled balance and accounts for open charges that may still consume credits.

## Settled balance

Settled balance comes from committed credit movements. If a customer receives 100 USD and consumes 30 USD, the settled balance is 70 USD.

```text
+ 100 funded 
 - 30 consumed
--------------
   70 settled balance
```
{:.no-copy-code}

If you query a balance at a timestamp, {{site.metering_and_billing}} includes movements visible at or before that timestamp, because a settled balance references a point in time.
Future movements, including future expiration, don't affect an earlier balance.

Example:

```text
T1: grant 100 credits
T5: consume 30 credits
T10: expire unused credits
```
{:.no-copy-code}

The settled balance changes depending on the query timestamp:

<!--vale off-->
{% table %}
columns:
  - title: Query time
    key: time
  - title: Settled balance
    key: balance
rows:
  - time: "T1"
    balance: "100"
  - time: "T5"
    balance: "70"
  - time: "T10"
    balance: "0"
{% endtable %}
<!--vale on-->

Settled balance is the right model for audit and history: the same timestamp always reflects the same visible ledger state.

## Pending balance

Pending balance is a pessimistic operational view. 
It accounts for open charges that may still consume credits, even before those charge movements are finalized into the settled balance.

For example, assume a customer has 100 USD settled credits and an open charge is expected to consume 25 USD. 
The settled balance is still 100 USD, but the pending balance is 75 USD, so the system doesn't overstate usable credit.

```text
settled balance:         100
open charge impact:      -25
pending balance:          75
```
{:.no-copy-code}

This distinction matters when you display balances:

* Use settled balance when the user needs an audit-style view of committed movements.
* Use pending balance when the user needs a conservative "can this customer spend more?" view.

## Currency

Credit balances are currency-specific. 
For example, a USD grant increases the customer's USD credit balance, while a EUR charge consumes from the customer's EUR credit balance.

**Do not** merge currencies in user-facing balance displays unless your product explicitly converts them. 
Treat each credit balance as one balance per currency.

## Expiration and balance reads

Expiration is visible only when the expiration time is visible to the query.

If a customer receives 100 credits at T1 and those credits expire at T10, the settled balance is still 100 before T10. At T10, any unused amount expires and the settled balance changes.

If the customer used 30 credits before expiration, only the remaining 70 credits expire.

```text
T1:  +100 funded
T5:   -30 consumed
T10:  -70 expired
```
{:.no-copy-code}

The consumed 30 credits don't expire because they were already applied.
