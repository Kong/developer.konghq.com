---
title: "Correctness guarantees"
content_type: reference
beta: true
description: "{{site.konnect_short_name}} {{site.metering_and_billing}} keeps credit balances correct through a double-entry ledger, immutable movements, and deterministic consumption order."
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
  - text: "Credit consumption and expiration"
    url: /metering-and-billing/credits/consumption-and-expiration/
  - text: "Credit transaction history"
    url: /metering-and-billing/credits/transaction-history/
  - text: "Operational flows"
    url: /metering-and-billing/credits/operational-flows/
  - text: "Get started with prepaid credits"
    url: /how-to/get-started-with-prepaid-credits/
next_steps:
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---

{{site.metering_and_billing}} keeps credit balances correct by booking every credit movement on an internal double-entry ledger.
The public credit balance is not a mutable counter.
It's derived from ledger movements that are balanced, ordered, and preserved over time.

This matters for customers and operators because the same rules explain every balance change:

* Grants add credits.
* Charges consume credits.
* Expiration removes unused credits.
* Corrections add follow-up movements instead of changing the past.
* Transaction history shows the customer-facing result of those movements.

## Double-entry ledger

Every credit movement is backed by balanced ledger entries. 
When credits move into or out of a customer balance, {{site.metering_and_billing}} records the matching side of the movement in another account.

At a high level, the credit ledger contains customer accounts and business accounts:

{% mermaid %}
flowchart LR
  subgraph Customer["Customer accounts"]
    FBO["Customer credit balance"]
    REC["Customer receivable"]
    ACC["Customer accrued"]
  end

  subgraph Business["Business accounts"]
    WASH["Settlement boundary"]
    EARN["Earnings"]
    BRK["Expiration / breakage"]
  end

  REC --> FBO
  FBO --> ACC
  ACC --> EARN
  FBO --> BRK
  WASH --> REC
{% endmermaid %}

The customer credit balance is the customer-facing account. 
Receivable and accrued accounts exist so {{site.metering_and_billing}} can represent payment state, consumed usage, and recognition separately. 
Business accounts represent the other side of settlement, earnings, and expiration.

## Movements

A settled balance is calculated from committed credit movements. If a customer receives 100 credits and uses 30, the settled balance is 70.

```text
+100 funded
 -30 consumed
----
  70 settled balance
```
{:.no-copy-code}

Because the balance comes from movements, {{site.metering_and_billing}} can also answer point-in-time balance questions. 
A balance read before an expiration doesn't include that expiration, while a balance read at or after the expiration does.

### Movement immutability

Credit history is immutable. 
When usage changes, a charge is canceled, or a billing workflow reverses previously consumed credits, {{site.metering_and_billing}} books a correction movement. 
{{site.metering_and_billing}} doesn't rewrite the original movement.

This gives transaction history a stable audit shape:

```text
T1: +100 funded
T2:  -40 consumed
T3:  +10 correction
```
{:.no-copy-code}

The customer can still see that 40 credits were consumed at T2. The later correction explains why 10 credits returned at T3.

## Deterministic consumption

When a customer has multiple grants in the same currency, {{site.metering_and_billing}} consumes credits in a deterministic order:

```text
priority asc
expires_at asc
stable movement order asc
```
{:.no-copy-code}

Lower priority values are consumed first. 
For equal priority, earlier-expiring credits are consumed first. If both are equal, {{site.metering_and_billing}} uses stable movement order.

This rule keeps consumption predictable and also protects expiration correctness. When credits are consumed, {{site.metering_and_billing}} knows which future expiration should be reduced.

## Credit expiration

Expiration removes only unused credits. 
If a customer uses part of an expiring grant, the used portion doesn't expire later.

```text
T1:  +100 funded, expires at T10
T5:   -30 consumed
T10:  -70 expired
```
{:.no-copy-code}

The original grant was 100 credits, but only 70 credits remained unused at expiration. The consumed 30 credits were already spent, so they are not expired.

## Transaction history is a projection

The double-entry ledger contains the accounting detail needed for correctness. Customer credit transaction history shows the customer-facing movement:

<!--vale off-->
{% table %}
columns:
  - title: Type
    key: type
  - title: Meaning
    key: meaning
rows:
  - type: "`funded`"
    meaning: "credits were added"
  - type: "`consumed`"
    meaning: "credits were used by charges"
  - type: "`expired`"
    meaning: "unused credits expired"
{% endtable %}
<!--vale on-->

This projection keeps the public history understandable while preserving accounting correctness underneath.
