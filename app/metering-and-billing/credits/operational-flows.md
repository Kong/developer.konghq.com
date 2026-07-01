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

Common use case include:
* Giving a new customer onboarding credit.
* Compensating a customer.
* Migrating an existing balance from another system.
* Manually granting trial credit.

The flow looks like this:

{% mermaid %}
flowchart LR
    A["Create credit grant\n(promotional)"] --> B["Set amount, currency,\npriority, expiration"]
    B --> C["Credit available\nimmediately"]
    C --> D["Confirm: read\ncustomer balance"]
    D --> E["Verify: funded\nmovement in history"]
{% endmermaid %}

1. Create a credit grant for the customer with the promotional funding method.
1. Set the amount, currency, priority, and optional expiration date.
1. Read the customer's balance to confirm the credit was added.
1. List transaction history to see the `funded` movement.

Promotional credits are immediately usable after they are created.

## Sell credits by invoice

Use invoice-funded credits when the customer buys credits through {{site.metering_and_billing}} billing.

The flow looks like this:

{% mermaid %}
flowchart LR
    A["Create credit grant\n(invoice)"] --> B["Set credit amount,\npurchase terms"]
    B --> C["Invoice lifecycle:\nauthorize & settle payment"]
    C --> D["Credits available\nafter settlement"]
    D --> E["Show customer\ngrant & balance"]
{% endmermaid %}

1. Create a credit grant for the customer with the invoice funding method.
1. Set the granted credit amount and currency.
1. Set purchase terms, including the purchase currency and per-unit cost.
1. Let the invoice lifecycle handle payment authorization and settlement.
1. Show the customer their credit grant and credit balance.

The credit amount and the invoice amount are different values.
A customer might receive 1,000 credits but pay a negotiated amount based on the per-unit cost.

## Record externally funded credits

Use externally funded credits when invoicing and payment happen outside {{site.metering_and_billing}} through custom invoicing.

The flow looks like this:

{% mermaid %}
flowchart LR
    A["Create credit grant\n(external funding)"] --> B["Set purchase terms"]
    B --> C["External system:\nhandles invoice & payment"]
    C --> D["Update external\nsettlement state"]
    D --> E["Confirm via\nbalance & history"]
{% endmermaid %}

1. Create a credit grant for the customer with the external funding method.
1. Set purchase terms.
1. Update the external settlement state as your external system changes.
1. Use balance and history to confirm credit availability and movement.

This flow is useful when {{site.metering_and_billing}} tracks the credit balance, but your own invoicing system handles the commercial invoice and payment.

## Check a customer's credit balance

Use balance reads when you need to show credit availability or decide whether a customer can continue using a credit-backed feature.

The flow looks like this:

{% mermaid %}
flowchart LR
    A["Resolve customer"] --> B["Query credit balance"]
    B --> C{"Currency-specific?"}
    C -->|Yes| D["Filter by currency"]
    C -->|No| E["Use full balance"]
    D & E --> F["Settled balance:\ncommitted value"]
    D & E --> G["Pending balance:\nconservative value"]
{% endmermaid %}

1. Resolve the customer.
1. Query the customer's credit balance.
1. If the product surface is currency-specific, then filter by currency 
1. Use the settled balance for committed historical value.
1. Use the pending balance for conservative operational decisions.

The pending balance can differ from the settled balance because open charges may still consume credits.
See [Credit balance model](/metering-and-billing/credits/balance-model/) for details.

## Consume credits through charges

Credit consumption happens through billing charges and rate card settlement modes.

The flow looks like this:

{% mermaid %}
flowchart LR
    A["Configure rate card\nwith credit settlement mode"] --> B["Charge is created\nfor customer"]
    B --> C{"Settlement mode"}
    C -->|credit_only| D["Credits settle\nthe full charge"]
    C -->|credit_then_invoice| E["Credits reduce\ninvoiced amount"]
    D & E --> F["consumed movement\nin transaction history"]
    F --> G["Updated balance\nreflects remaining credits"]
{% endmermaid %}

1. Configure the relevant rate card with a credit settlement mode.
1. Create or run charges for the customer.
1. {{site.metering_and_billing}} applies credits according to the settlement mode.
1. Read transaction history to inspect consumed credits.
1. Read balance to inspect the remaining customer credit.

For `credit_then_invoice`, credits reduce the invoiced amount.
For `credit_only`, credits are the sole settlement mechanism for the charge.

## Review credit history

Use transaction history when a customer or operator asks why a balance changed.

The flow looks like this:

{% mermaid %}
flowchart LR
    A["List credit transactions\nfor customer"] --> B["Apply filters:\ncurrency, movement type"]
    B --> C["Display each movement:\nsigned amount, balance before/after"]
    C --> D{"More history?"}
    D -->|Yes| E["Use pagination\ncursor"]
    E --> C
    D -->|No| F["Done"]
{% endmermaid %}

1. List credit transactions for the customer.
1. Filter by currency when needed.
1. Filter by movement type when investigating a specific change.
1. Display signed amount and balance before and after each movement.
1. Use pagination cursors to move through older or newer history.

Good support tooling shows transaction history next to grants and charges:
* The history explains balance movement
* Grants explain where credit came from
* Charges explain why credit was consumed

See [Credit transaction history](/metering-and-billing/credits/transaction-history/) for field definitions and pagination.
