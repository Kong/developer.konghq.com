---
title: Get started with prepaid credits
permalink: /how-to/get-started-with-prepaid-credits/
description: Configure a credits-only billing plan, create a customer, start a subscription, and issue a prepaid credit grant in {{site.konnect_short_name}} {{site.metering_and_billing}}.
content_type: how_to
beta: true

breadcrumbs:
  - /metering-and-billing/
  - /metering-and-billing/credits/

products:
  - metering-and-billing

works_on:
  - konnect

tags:
  - billing
  - credits

prereqs:
  skip_product: true
  inline:
    - title: "{{site.konnect_short_name}} roles"
      content: |
        You need the [{{site.metering_and_billing}} Admin role](/konnect-platform/teams-and-roles/#metering-billing) in {{site.konnect_short_name}} to manage credits.
      icon_url: /assets/icons/kogo-white.svg
    - title: "Configured meter"
      content: |
        You need a [configured meter](/metering-and-billing/metering/#create-a-meter), such as API Gateway requests or AI Gateway tokens.
      icon_url: /assets/icons/money.svg

tldr:
  q: How do I set up prepaid credits for a customer?
  a: |
    To set up a prepaid billing model for a customer using credits, you need to:

    1. Create a credits-only plan
    2. Create a customer
    3. Start a subscription
    4. Grant prepaid credits
    5. Monitor the credit ledger

    Metered usage automatically draws down from the grant balance.

related_resources:
  - text: "Prepaid credits overview"
    url: /metering-and-billing/credits/
  - text: "Credit grants"
    url: /metering-and-billing/credits/grants/
  - text: "Credit balance model"
    url: /metering-and-billing/credits/balance-model/
  - text: "Credit consumption and expiration"
    url: /metering-and-billing/credits/consumption-and-expiration/
  - text: "Credit transaction history"
    url: /metering-and-billing/credits/transaction-history/
  - text: "Operational flows"
    url: /metering-and-billing/credits/operational-flows/

automated_tests: false
---

## Create a credits-only plan

To charge customers via prepaid credits, define a plan with the `credit_only` settlement mode.
All usage settles against credits.
If a customer runs out of credits, uncovered usage creates a negative credit balance on the ledger rather than generating an overage invoice.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. Click **Product Catalog**.
1. Click the **Plans** tab and create a new plan.
1. In the **Billing** section, configure the **Currency** (for example, `USD`) and set the **Settlement mode** to **Credits only**.
1. Click **Add Rate Card** and select the feature you want to price.
1. Configure a **Usage based** pricing model and set your price per unit.
1. Save the rate card and click **Publish Plan**.

## Create a customer

Customers represent the individuals or organizations that subscribe to plans and consume your metered features.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Create Customer**.
1. Enter the customer's **Name**.
1. Map the customer to a **Consumer**, **Application**, or **Subject** to ensure their usage is attributed correctly.
1. Click **Save**.

## Start a subscription

Subscriptions link customers to a pricing model and track their usage against rate cards.

1. On the customer's details page, click the **Subscriptions** tab.
1. Add a new subscription and select the credits-only plan you created.
1. Choose the start date and finalize the subscription.

## Grant prepaid credits

Prepaid credits burn down as the customer incurs usage.
Issue a grant directly to the customer's balance.

1. On the customer's page, click the **Credits** tab.
1. Click **Grant Credits** and select **New credit grant**.
1. In the **Grant** section, enter the **Credit amount**.
1. In the **Charge** section, select **Promotional / Free** as the charge type.
1. Set the **Credit availability** to **Available immediately on grant**.
1. Optionally, expand **Policies** to set a **Credit draw-down order** to control consumption priority if this customer has multiple grants.
1. Click **Next** to review the **Grant Summary**.
1. Click **Grant credits** to finalize.

A `funded` movement is recorded in the customer's transaction history and their settled balance increases immediately.

## Monitor the credit ledger

After the grant is issued, the customer's available balance reflects the new credits.
Because this customer is on a `credit_only` plan, metered usage automatically deducts from this balance.

1. On the customer's page, click the **Credits** tab.
1. Click **Transaction History**.

You'll see:

* A `funded` movement with a positive amount for the grant you issued.
* `consumed` movements with negative amounts as usage charges are applied.
* The running balance before and after each movement.

For more on movement types, pagination, and corrections, see [Credit transaction history](/metering-and-billing/credits/transaction-history/).
