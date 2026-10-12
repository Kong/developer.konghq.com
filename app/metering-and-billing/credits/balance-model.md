---
title: "Credit balance model"
content_type: reference
description: "Understand the three credit balance types in {{site.konnect_short_name}} {{site.metering_and_billing}}: settled, live, and pending."
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
  - text: "Feature filters"
    url: /metering-and-billing/credits/feature-filters/
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


A credit balance read returns three values:

* **Settled balance** is the balance from committed ledger movements. It is the durable record of what has happened.
* **Live balance** starts from the settled balance and accounts for open charges that may still consume credits.
* **Pending balance** is the total of granted credits that don't count toward the settled balance yet, such as grants with a future effective time. It's a sum of grants, not a spendable balance.

## Settled balance

Settled balance comes from committed credit movements. If a customer receives 100 USD and consumes 30 USD, the settled balance is 70 USD.

```text
+ 100 funded 
 - 30 consumed
--------------
   70 settled balance
```
{:.no-copy-code}

If you query a balance at a timestamp, {{site.metering_and_billing}} includes the movements booked at or before that timestamp, because a settled balance references a point in time.
The booking time is when a movement takes effect on the balance, which isn't always when it's recorded.
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

Movements can be booked with a time in the past.
For example, usage-based consumption can be recorded after the usage it covers, once late usage events have been collected.
If you query the same past timestamp again later, the settled balance can be different. This is expected: the balance reflects every movement booked at or before that time, including movements recorded since your earlier query.

Settled balance is the right model for audit and history, because every change to it is a recorded movement.

The settled balance can be negative.
This happens when `credit_only` usage exceeds the available credits, as described in [Negative balances](/metering-and-billing/credits/consumption-and-expiration/#negative-balances).

## Live balance

Live balance is a pessimistic operational view. 
It accounts for open charges that may still consume credits, even before those charge movements are finalized into the settled balance.

For example, assume a customer has 100 USD settled credits and an open charge is expected to consume 25 USD. 
The settled balance is still 100 USD, but the live balance is 75 USD, so the system doesn't overstate usable credit.

```text
settled balance:         100
open charge impact:      -25
live balance:             75
```
{:.no-copy-code}

The settlement mode affects how low the live balance can go.
Open `credit_then_invoice` charges only consume available credit, so they never lower the live balance below 0, and the rest is invoiced.
A balance that is already negative stays as it is.
Open `credit_only` charges can take the live balance below 0.

The live balance reflects open charges only as they are now, so it's only available for current reads.
If you query a balance at a timestamp, the live balance is always 0.

This distinction matters when you display balances:

* Use settled balance when the user needs an audit-style view of committed movements.
* Use live balance when the user needs a conservative "can this customer spend more?" view.

## Pending balance

The pending balance is the total amount of granted credits that don't count toward the settled balance yet.
It's a sum of grants in a pending state, not a balance you can spend, and it respects the same filters as the rest of the balance read, such as a feature filter.
This includes grants that aren't written to the ledger yet, and grants written to the ledger with a future booked time, such as a grant with a future effective time.
When a pending grant takes effect, its amount moves into the settled balance.

## Currency

Credit balances are currency-specific. 
A customer's fiat credits are held in the customer's currency, for example USD, and the customer can also hold balances in [custom currencies](/metering-and-billing/currencies/).
A USD grant increases the customer's USD credit balance, and a charge in a custom currency consumes from the balance in that custom currency.

Charges are only ever in the customer's currency or in a custom currency, because a subscription's invoice currency must match the customer's currency.
The API accepts a grant in another fiat currency, but no charge can consume it.

One case crosses currencies: when a `credit_then_invoice` charge in a custom currency isn't fully covered, the remainder is converted into the invoice's fiat currency, and the customer's credits in that fiat currency can cover part of it.

**Do not** merge currencies in user-facing balance displays unless your product explicitly converts them.
Treat each currency as a separate balance.

## Feature balance queries

You can query a customer's credit balance for a specific product feature using `filter[feature_key]`.
A feature balance includes unrestricted shared credits as well as any credits restricted to that feature.

For the full reference on balance filters and how feature restrictions affect balance views, see [Feature filters](/metering-and-billing/credits/feature-filters/).

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
