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
    - title: "Meter and feature"
      include_content: prereqs/metering-and-billing-meter-feature-credits
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

To charge customers via prepaid credits, define a plan and set `settlement_mode: credit_only` on the subscription.
All usage settles against credits.
If a customer runs out of credits, uncovered usage creates a negative credit balance on the ledger rather than generating an overage invoice.

First, create the plan with a rate card:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans
method: POST
status_code: 201
body:
  name: Credits Plan
  key: credits_plan
  currency: USD
  billing_cadence: P1M
  phases:
    - name: default
      key: default
      rate_cards:
        - name: API requests
          key: api_requests
          feature:
            id: $FEATURE_ID
          price:
            type: unit
            amount: "1"
          entitlement:
            type: boolean
capture:
  - variable: PLAN_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Then publish the plan:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans/$PLAN_ID/publish
method: POST
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

## Create a customer

Customers represent the individuals or organizations that subscribe to plans and consume your metered features.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers
method: POST
status_code: 201
body:
  name: Acme Inc
  key: acme-inc
  usage_attribution:
    subject_keys:
      - acme-inc
capture:
  - variable: CUSTOMER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Start a subscription

Subscriptions link customers to a pricing model and track their usage against rate cards.
Setting `settlement_mode: credit_only` ensures all usage is settled against the customer's credit balance.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/subscriptions
method: POST
status_code: 201
body:
  customer:
    id: $CUSTOMER_ID
  plan:
    key: credits_plan
  settlement_mode: credit_only
capture:
  - variable: SUBSCRIPTION_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Grant prepaid credits

Prepaid credits burn down as the customer incurs usage.
Issue a grant directly to the customer's balance.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID/credits/grants
method: POST
status_code: 201
body:
  name: Initial credit grant
  currency: USD
  amount: "100"
  funding_method: none
{% endkonnect_api_request %}
<!--vale on-->

Setting `funding_method: none` issues the grant as promotional/free credits with no charge.
A `funded` movement is recorded in the customer's transaction history and their settled balance increases immediately.

## Monitor the credit ledger

After the grant is issued, the customer's available balance reflects the new credits.
Because this customer is on a `credit_only` subscription, metered usage automatically deducts from this balance.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID/credits/transactions
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

The response includes:

* A `funded` movement with a positive amount for the grant you issued.
* `consumed` movements with negative amounts as usage charges are applied.
* The running balance before and after each movement.

For more on movement types, pagination, and corrections, see [Credit transaction history](/metering-and-billing/credits/transaction-history/).
