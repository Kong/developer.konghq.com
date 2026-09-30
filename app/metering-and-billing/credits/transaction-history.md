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
  - text: "Feature filters"
    url: /metering-and-billing/credits/feature-filters/
  - text: "Operational flows"
    url: /metering-and-billing/credits/operational-flows/
  - text: "Correctness guarantees"
    url: /metering-and-billing/credits/correctness-guarantee/
  - text: "Get started with prepaid credits"
    url: /how-to/get-started-with-prepaid-credits/
next_steps:
  - text: Learn about feature filters
    url: /metering-and-billing/credits/feature-filters/
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---

Changes to a customer's credit balance are recorded as movements in the transaction history.
The history is the customer-facing view of the ledger, not a raw ledger log.
Internal accounting movements aren't shown, and a future expiration only appears once its time has passed.
For the authoritative current balance, read the customer's credit balance.

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
    description: "Recorded when credits are applied to a charge."
  - type: "`expired`"
    sign: "Negative (-)"
    description: "Recorded when unused credits from a grant pass their expiration date."
  - type: "`voided`"
    sign: "Negative (-)"
    description: "Recorded when a grant is voided. Represents the unused credit that was forfeited."
{% endtable %}
<!--vale on-->

Amounts are expressed from the customer's perspective.
* A `funded` movement of +100 USD means the customer gained 100 USD in credit.
* A `consumed` movement of -30 USD means 30 USD of credits were applied to reduce a charge.

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
  - field: "`id`"
    description: "The ID of the movement."
  - field: "`name`, `description`"
    description: "A display name and optional description for the movement."
  - field: "`type`"
    description: "The movement type: `funded`, `consumed`, `expired`, or `voided`."
  - field: "`amount`"
    description: "The signed amount of the movement. Positive for funded, negative for consumed, expired, and voided."
  - field: "`currency`"
    description: "The currency of the balance the movement affects."
  - field: "`custom_currency`"
    description: "A reference to the custom currency. Present only for movements in a custom currency."
  - field: "`available_balance.before`, `available_balance.after`"
    description: "The customer's available credit balance immediately before and after this movement."
  - field: "`booked_at`"
    description: "The time the movement takes effect on the balance. Movements are ordered by this time."
  - field: "`created_at`"
    description: "The time the movement was recorded."
  - field: "`labels`"
    description: "System-set references to related resources, such as `charge_id`, `subscription_id`, and `feature_id`. A `funded` movement for a voided grant carries the label `voided`."
{% endtable %}
<!--vale on-->

A movement doesn't carry a grant ID field.
To relate movements to a grant or charge, use the `charge_id` label: on a `funded` movement, it's the ID of the grant.

## Filtering by feature

You can filter the transaction history by product feature using `filter[feature_key]`.
This returns only the transactions relevant to a specific feature, including shared unrestricted credits.

For the full reference on transaction filters, see [Feature filters](/metering-and-billing/credits/feature-filters/).

## Ordering and pagination

Movements are returned newest first, ordered by `booked_at`, then `created_at`, then ID, so the order is stable.
The API uses cursor-based pagination to ensure consistent results even when new movements are added while you're paginating.

Use `page[size]` to set the page size.
To fetch the next page, pass the cursor from the previous response's `meta.page.next` field as `page[after]`.
To go back, pass `meta.page.previous` as `page[before]`.

You can also filter the history by movement type with `filter[type]` and by currency with `filter[currency]`.

## Corrections

Movements are immutable and can't be edited or deleted.
Grant amounts must be positive, so you can't offset a grant with a negative grant.

If a grant was issued for the wrong amount, void it and issue a new grant for the correct amount.
For example, if a grant of 100 USD was issued but should have been 80 USD:

1. In the customer's **Credits** tab, open the actions menu of the grant's `funded` movement in **Transaction History** and click **Void**.
1. Confirm in the **Void Grant** dialog.
   The unused remainder of the grant is forfeited and recorded as a `voided` movement.
1. Grant 80 USD of credits.

Keep the following in mind when you void a grant:

* Voiding is irreversible.
* Only active grants can be voided. You can't void a grant that is pending, expired, or fully consumed.
* Credits already consumed by usage aren't affected. Only the unused remainder is forfeited.
* Voiding doesn't adjust invoices or payments. If the grant was funded by an invoice, the original invoiced amount may still be collected.

The full history, including the original movement and the void, remains visible in transaction history.
This preserves the complete audit trail.
