---
title: "Credit transaction history"
content_type: reference
beta: true
description: "Understand credit movements, transaction history structure, ordering, and corrections in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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
  - text: "Operational flows"
    url: /metering-and-billing/credits/operational-flows/
  - text: "Correctness guarantees"
    url: /metering-and-billing/credits/correctness-guarantee/
  - text: "Get started with prepaid credits"
    url: /how-to/get-started-with-prepaid-credits/
next_steps:
  - text: Learn about credit operational flows
    url: /metering-and-billing/credits/operational-flows/
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---

Every change to a customer's credit balance is recorded as a movement in the transaction history.
The history is a complete, ordered log of all credit activity for a customer and is the authoritative source for their balance.

## Movement types

<!--vale off-->
{% table %}
columns:
  - title: Type
    key: type
  - title: Sign
    key: sign
  - title: Description
    key: description
rows:
  - type: "`funded`"
    sign: "Positive (+)"
    description: "Recorded when a grant is issued. Represents credit added to the customer's balance."
  - type: "`consumed`"
    sign: "Negative (-)"
    description: "Recorded when credits are applied to a charge. One movement per grant drawn from in a single charge."
  - type: "`expired`"
    sign: "Negative (-)"
    description: "Recorded when unused credits from a grant pass their expiration date."
{% endtable %}
<!--vale on-->

Amounts are expressed from the customer's perspective.
* A `funded` movement of +100 USD means the customer gained 100 USD in credit.
* A `consumed` movement of -30 USD means 30 USD was applied to reduce a charge.

## Movement fields

Each movement in the transaction history includes the following fields:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`type`"
    description: "The movement type: `funded`, `consumed`, or `expired`."
  - field: "`amount`"
    description: "The signed amount of the movement. Positive for funded, negative for consumed and expired."
  - field: "`currency`"
    description: "The currency of the movement."
  - field: "`grant_id`"
    description: "The ID of the grant this movement is associated with."
  - field: "`balance_before`"
    description: "The customer's settled credit balance immediately before this movement."
  - field: "`balance_after`"
    description: "The customer's settled credit balance immediately after this movement."
  - field: "`created_at`"
    description: "The timestamp at which the movement was recorded."
  - field: "`metadata`"
    description: "Optional key-value metadata attached to the movement."
{% endtable %}
<!--vale on-->

## Ordering and pagination

Movements are returned in stable insertion order.
The API uses a cursor-based pagination scheme to ensure consistent results even when new movements are added while you are paginating.

Pass the cursor from the previous response's `next` field to fetch the next page.
Restarting pagination from the beginning always gives results in the same stable order.

## Corrections

Movements are immutable and can't be edited or deleted.
If a movement was recorded in error (for example, a grant was issued for the wrong amount), issue a correction by creating a new movement that offsets the error.

For example, if a grant of 100 USD was issued but should have been 80 USD:

1. The original `funded` movement of +100 USD remains in the ledger unchanged.
2. Issue a new correction grant of -20 USD (or void the original and reissue the correct amount using the appropriate API operation).

The full history, including the original movement and the correction, remains visible in transaction history.
This preserves the complete audit trail.
