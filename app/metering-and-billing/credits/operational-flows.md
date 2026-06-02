---
title: "Prepaid credit operational flows"
content_type: reference
beta: true
description: "Reference for common prepaid credit workflows in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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
  - text: "Correctness guarantees"
    url: /metering-and-billing/credits/correctness-guarantee/
  - text: "Get started with prepaid credits"
    url: /how-to/get-started-with-prepaid-credits/
next_steps:
  - text: Learn about the correctness guarantee approach
    url: /metering-and-billing/credits/correctness-guarantee/
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---

This reference covers the common workflows for managing prepaid credits.

## Create promotional credits

Use promotional credits when you want to add value without a payment workflow.

Common cases:

- Give a new customer onboarding credit.
- Compensate a customer.
- Migrate an existing balance from another system.
- Manually grant trial credit.

The flow:

1. Create a credit grant for the customer.
2. Use the promotional funding method.
3. Set the amount, currency, priority, and optional expiration date.
4. Read the customer's balance to confirm the credit was added.
5. List transaction history to see the `funded` movement.

Promotional credits are immediately usable after they are created.

## Sell credits by invoice

Use invoice-funded credits when the customer buys credits through {{site.metering_and_billing}} billing.

The flow:

1. Create a credit grant for the customer.
2. Use the invoice funding method.
3. Set the granted credit amount and currency.
4. Set purchase terms, including the purchase currency and per-unit cost.
5. Let the invoice lifecycle handle payment authorization and settlement.
6. Show the customer their credit grant and credit balance.

The credit amount and the invoice amount are different values.
A customer might receive 1,000 credits but pay a negotiated amount based on the per-unit cost.

## Record externally funded credits

Use externally funded credits when invoicing and payment happen outside {{site.metering_and_billing}} through custom invoicing.

The flow:

1. Create a credit grant for the customer.
2. Use the external funding method.
3. Set purchase terms.
4. Update the external settlement state as your external system changes.
5. Use balance and history to confirm credit availability and movement.

This flow is useful when {{site.metering_and_billing}} tracks the credit balance, but your own invoicing system handles the commercial invoice and payment.

## Check a customer's credit balance

Use balance reads when you need to show credit availability or decide whether a customer can continue using a credit-backed feature.

The flow:

1. Resolve the customer.
2. Query the customer's credit balance.
3. Filter by currency if the product surface is currency-specific.
4. Use the settled balance for committed historical value.
5. Use the pending balance for conservative operational decisions.

The pending balance can differ from the settled balance because open charges may still consume credits.
See [Credit balance model](/metering-and-billing/credits/balance-model/) for details.

## Consume credits through charges

Credit consumption happens through billing charges and rate card settlement modes.

The flow:

1. Configure the relevant rate card with a credit settlement mode.
2. Create or run charges for the customer.
3. {{site.metering_and_billing}} applies credits according to the settlement mode.
4. Read transaction history to inspect consumed credits.
5. Read balance to inspect the remaining customer credit.

For `credit_then_invoice`, credits reduce the amount to invoice.
For `credit_only`, credits are the settlement mechanism for the charge.

## Review credit history

Use transaction history when a customer or operator asks why a balance changed.

The flow:

1. List credit transactions for the customer.
2. Filter by currency when needed.
3. Filter by movement type when investigating a specific change.
4. Display signed amount and balance before and after each movement.
5. Use pagination cursors to move through older or newer history.

Good support tooling shows transaction history next to grants and charges:
* The history explains balance movement
* Grants explain where credit came from
* Charges explain why credit was consumed

See [Credit transaction history](/metering-and-billing/credits/transaction-history/) for field definitions and pagination.
