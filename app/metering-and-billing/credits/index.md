---
title: "Prepaid credits"
content_type: reference
beta: true
description: "Understand how prepaid credits work in {{site.konnect_short_name}} {{site.metering_and_billing}}: key concepts, terminology, and correctness guarantees."
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
  - text: "Correctness guarantees"
    url: /metering-and-billing/credits/correctness-guarantee/
  - text: "Get started with prepaid credits"
    url: /how-to/get-started-with-prepaid-credits/
next_steps:
  - text: Learn about the credit balance model
    url: /metering-and-billing/credits/balance-model/
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---

Credits are customer-specific value that can be used to pay for charges. 
They are useful for prepaid plans, promotional balances, migration credits, enterprise commitments, or any workflow where a customer consumes a balance before paying by invoice.

A credit balance is always tied to a customer and a currency.
For example, a customer can have a USD credit balance and an EUR credit balance.
Charges consume credits from the matching currency balance.

For an end-to-end tutorial on setting up prepaid credits, see [Get started with prepaid credits](/how-to/get-started-with-prepaid-credits/).

## How it works

The credit system works as follows:

* Credit grants add credits to a customer: A grant can be promotional, funded through a {{site.metering_and_billing}} invoice, or funded externally.
* Balances show how much credit the customer has. There is a settled balance from committed ledger movements, and a pending balance that pessimistically accounts for open charges.
* Charges consume credits: The settlement mode on the rate card decides whether credits are used before invoicing, or whether the charge must be paid entirely from credits.
* History explains balance changes: Credit transaction history shows customer-facing movements such as funded, consumed, and expired credits.

## Core concepts

Credits flow through a lifecycle of funding, consumption, and expiration.
The following terms describe the key entities and states involved:

<!--vale off-->
{% table %}
columns:
  - title: Term
    key: term
  - title: Definition
    key: definition
  - title: Reference
    key: reference
rows:
  - term: "**Credit**"
    definition: "A customer-specific monetary value that can be applied to charges to reduce the amount charged on an invoice."
    reference: "[Credit grants](/metering-and-billing/credits/grants/)"
  - term: "**Grant**"
    definition: "The object that adds credits to a customer balance."
    reference: "[Credit grants](/metering-and-billing/credits/grants/)"
  - term: "**Priority**"
    definition: "A numeric field on a grant that controls draw-down order. Grants with lower priority values are consumed first."
    reference: "[Credit grants](/metering-and-billing/credits/grants/)"
  - term: "**Settled balance**"
    definition: "The committed ledger balance at a given point in time. Reflects only finalized movements (funded, consumed, expired). Doesn't include open charges."
    reference: "[Credit balance model](/metering-and-billing/credits/balance-model/)"
  - term: "**Pending balance**"
    definition: "A pessimistic balance of available credits. Includes the settled balance minus any open (in-flight) charges that have not yet been finalized."
    reference: "[Credit balance model](/metering-and-billing/credits/balance-model/)"
  - term: "**Movement**"
    definition: "A record of a credit change. Movements are immutable: when something changes, a new movement is recorded instead of rewriting the old one. The balance is derived from the sum of all movements."
    reference: "[Credit transaction history](/metering-and-billing/credits/transaction-history/)"
  - term: "**Funded transaction**"
    definition: "A positive credit movement recorded when a grant is issued. Appears as a positive amount in transaction history."
    reference: "[Credit transaction history](/metering-and-billing/credits/transaction-history/)"
  - term: "**Consumed transaction**"
    definition: "A negative credit movement recorded when credits are applied to a charge. Appears as a negative amount in transaction history."
    reference: "[Credit transaction history](/metering-and-billing/credits/transaction-history/)"
  - term: "**Expiration**"
    definition: "Removal of unused credits at the grant's expiration time."
    reference: "[Credit consumption and expiration](/metering-and-billing/credits/consumption-and-expiration/)"
{% endtable %}
<!--vale on-->

## Movements and transaction history

Credits are not a mutable counter. 
{{site.metering_and_billing}} records credit movements over time. 
When something changes, such as usage being corrected or credit expiring, the system records another movement instead of rewriting the old one. 
The balance is the result of the movements that are visible at the time you query it.

Assume a customer receives 100 USD in credits:

```text
grant 100 USD credits
```
{:.no-copy-code}

The customer's settled credit balance becomes 100 USD. If the customer later uses 30 USD of credits, the balance becomes 70 USD:

```text
grant 100 USD credits
consume 30 USD credits
remaining settled balance: 70 USD
```
{:.no-copy-code}

If the original grant expires and 70 USD remains unused, the unused amount expires and the balance becomes 0 USD:

```text
grant 100 USD credits
consume 30 USD credits
expire 70 USD unused credits
remaining settled balance: 0 USD
```
{:.no-copy-code}

The customer-facing transaction history shows the same story as signed movements:

<!--vale off-->
{% table %}
columns:
  - title: Type
    key: type
  - title: Amount
    key: amount
  - title: Meaning
    key: meaning
rows:
  - type: "`funded`"
    amount: "+100 USD"
    meaning: "credits were granted"
  - type: "`consumed`"
    amount: "-30 USD"
    meaning: "credits were used"
  - type: "`expired`"
    amount: "-70 USD"
    meaning: "unused credits expired"
{% endtable %}
<!--vale on-->

To learn more about movements and transaction history, see [Credit transaction history](/metering-and-billing/credits/transaction-history/).

## Settlement modes

Billing charges apply credits.
When a charge is raised against a customer, {{site.metering_and_billing}} uses the settlement mode to determine how to apply credits:

<!--vale off-->
{% table %}
columns:
  - title: Settlement mode
    key: mode
  - title: Behavior
    key: behavior
rows:
  - mode: "`credit_then_invoice`"
    behavior: |
      Use available credits first.
      Any charge amount that exceeds the available credit balance is invoiced as a standard charge. This is the prepaid-plus-overage model.
  - mode: "`credit_only`"
    behavior: "Credits must cover the full charge. If the credit balance is insufficient, the charge is blocked. No invoice overage is generated."
{% endtable %}
<!--vale on-->

The customer's credit balance, the charge's settlement mode, and the grant's expiration and priority rules together determine how much credit is consumed.

For details on draw-down order and expiration behavior, see [Credit consumption and expiration](/metering-and-billing/credits/consumption-and-expiration/).

For details on how {{site.metering_and_billing}} keeps credit balances correct through a double-entry ledger, immutable movements, and deterministic consumption order, see [Correctness guarantees](/metering-and-billing/credits/correctness-guarantee/).
