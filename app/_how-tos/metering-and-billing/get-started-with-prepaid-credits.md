---
title: Get started with prepaid credits
permalink: /how-to/get-started-with-prepaid-credits/
description: Configure a credits-only billing plan, create a customer, start a subscription, and issue a prepaid credit grant in {{site.konnect_short_name}} {{site.metering_and_billing}}.
content_type: how_to

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
    - title: "{{site.konnect_short_name}} access token"
      include_content: prereqs/metering-and-billing-konnect-token
      icon_url: /assets/icons/kogo-white.svg
    - title: "Meter and feature"
      include_content: prereqs/metering-and-billing-meter-feature
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

Create a plan with `settlement_mode` set to `credit_only`, a currency, and a usage-based rate card for your feature. The request captures the plan's ID:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans
method: POST
status_code: 201
body:
  name: Prepaid
  key: prepaid
  currency: USD
  billing_cadence: P1M
  settlement_mode: credit_only
  phases:
    - name: Main
      key: main
      rate_cards:
        - name: API requests
          key: api_requests
          feature:
            id: $FEATURE_ID
          billing_cadence: P1M
          price:
            type: unit
            amount: "1"
capture:
  - variable: PLAN_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> **Note:** Besides fiat currencies, you can set `currency` to a [custom currency](/metering-and-billing/currencies/) that you defined for your organization.

Publish the plan so you can subscribe customers to it:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans/$PLAN_ID/publish
method: POST
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

## Create a customer

Customers represent the individuals or organizations that subscribe to plans and consume your metered features.

Create a customer with a name, a key, and the subject keys whose usage belongs to this customer. The request captures the customer's ID:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers
method: POST
status_code: 201
body:
  name: Acme Inc
  key: acme-inc
  currency: USD
  usage_attribution:
    subject_keys:
      - acme-inc
capture:
  - variable: CUSTOMER_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> To attribute usage from Gateway Consumers, {{site.ai_gateway}} Consumers, or Dev Portal Applications in the {{site.konnect_short_name}} UI instead, use the **Include usage from** dropdown when you create the customer. For details, see [Customers and usage attribution](/metering-and-billing/customer/).

## Start a subscription

Subscriptions link customers to a pricing model and track their usage against rate cards.

Subscribe the customer to the credits-only plan. The subscription inherits the settlement mode from the plan, and `timing` set to `immediate` starts it right away. To start it later, set `timing` to a date and time instead.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/subscriptions
method: POST
status_code: 201
body:
  customer:
    key: acme-inc
  plan:
    key: prepaid
  timing: immediate
{% endkonnect_api_request %}
<!--vale on-->

## Grant prepaid credits

Prepaid credits burn down as the customer's usage is billed.
Issue a grant directly to the customer's balance.

Create a grant with `funding_method` set to `none`, which issues promotional credits that the customer doesn't pay for. Set `priority`, from 1 to 1000, to control consumption order if this customer has multiple grants. Lower numbers are consumed first.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID/credits/grants
method: POST
status_code: 201
body:
  name: Welcome credits
  funding_method: none
  currency: USD
  amount: "100"
  priority: 5
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> The {{site.konnect_short_name}} UI limits **Credit draw-down priority** to a range of 1 to 100.

A `funded` movement is recorded in the customer's transaction history and their settled balance increases immediately.

## Monitor the credit ledger

After the grant is issued, the customer's available balance reflects the new credits.
Because this customer is on a `credit_only` plan, metered usage automatically deducts from this balance.
`consumed` movements appear when usage charges are booked.
Before that, the **Live balance** on the **Credits** tab already reflects the expected consumption.

Get the customer's credit balance. The response shows the settled, live, and pending balances:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID/credits/balance
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

Then list the transaction history:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID/credits/transactions
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

You can also review the balances and transactions on the customer's **Credits** tab in the {{site.konnect_short_name}} UI.

You'll see:

* A `funded` movement with a positive amount for the grant you issued.
* `consumed` movements with negative amounts as usage charges are booked.
* The running balance before and after each movement.

For more on movement types, pagination, and corrections, see [Credit transaction history](/metering-and-billing/credits/transaction-history/).
