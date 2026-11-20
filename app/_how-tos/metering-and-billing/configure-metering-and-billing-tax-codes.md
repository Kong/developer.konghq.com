---
title: Create and apply {{site.metering_and_billing}} tax codes
permalink: /how-to/configure-metering-and-billing-tax-codes/
description: Learn how to review system-managed tax codes, create custom tax codes, and apply them at the organization and rate-card level in {{site.konnect_short_name}} {{site.metering_and_billing}}.
content_type: how_to

breadcrumbs:
  - /metering-and-billing/

products:
    - metering-and-billing

works_on:
    - konnect

tags:
    - metering
    - billing

prereqs:
  skip_product: true
  show_works_on: false
  inline:
    - title: "{{site.konnect_short_name}} access token"
      include_content: prereqs/metering-and-billing-konnect-token
      icon_url: /assets/icons/kogo-white.svg
    - title: "Meter and feature"
      include_content: prereqs/metering-and-billing-meter-feature
      icon_url: /assets/icons/money.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

tldr:
  q: How do I configure tax codes in {{site.konnect_short_name}} {{site.metering_and_billing}}?
  a: |
    {{site.metering_and_billing}} pre-provisions the most commonly used Stripe tax codes and sets two organization defaults (invoicing and credit grant) when your organization is created.
    Review those defaults, create custom tax codes if needed, and apply them at the organization level or on individual rate cards.

related_resources:
  - text: Tax codes reference
    url: /metering-and-billing/tax-codes/
  - text: Billing and invoicing
    url: /metering-and-billing/billing-invoicing/
  - text: Product Catalog reference
    url: /metering-and-billing/product-catalog/

faqs:
  - q: Why can't I edit or delete a tax code?
    a: |
      Edit and delete actions are only available for user-managed codes.
      System-managed codes are read-only and can't be modified.

automated_tests: false
---

Tax codes classify goods and services so that your payment provider can calculate tax correctly on invoices.
{{site.metering_and_billing}} pre-provisions the most commonly used Stripe tax codes for every organization and sets two defaults at org creation time.

In this guide, you'll:

* Review your system-managed defaults
* Create a custom tax code
* Apply a tax code at the organization or rate-card level

For background on how tax codes work and how the fallback chain is evaluated, see [Tax codes](/metering-and-billing/tax-codes/).

## Review default organization tax codes

When your organization is created, {{site.metering_and_billing}} sets up two defaults: one for invoicing and one for credit grants.
Review these before creating custom codes, as the pre-provisioned codes may already cover your needs.

List the tax codes in your organization, both system-managed and user-created:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/tax-codes
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

Get the current organization defaults. The response contains the IDs of the invoicing and credit grant tax codes:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/defaults/tax-codes
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

To change which code is the default, see [Set a default tax code](#set-a-default-tax-code).

If the system-managed codes cover your needs, you can skip the next step and go directly to [Apply a tax code to a rate card](#apply-a-tax-code-to-a-rate-card).

## Create a tax code

If none of the system-managed codes match your product category, you can create a custom tax code:

Create a tax code with a name, a key, and one or more app mappings. For Stripe, the `tax_code` value must follow the `txcd_XXXXXXXX` format. You can browse available values in the [Stripe Tax Code reference](https://docs.stripe.com/tax/tax-codes).

The request captures the new tax code's ID so you can reference it later:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/tax-codes
method: POST
status_code: 201
body:
  name: SaaS
  key: saas
  description: Business use software as a service
  app_mappings:
    - app_type: stripe
      tax_code: txcd_10103001
capture:
  - variable: TAX_CODE_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

### Set a default tax code

To make a tax code the default for invoices or credit grants, update the organization defaults. The request sets both defaults, so include the ID of the code you want to keep for each category. This example keeps your current credit grant default and sets the new code as the invoicing default:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/defaults/tax-codes
method: PUT
status_code: 200
body:
  invoicing_tax_code:
    id: $TAX_CODE_ID
  credit_grant_tax_code:
    id: YOUR_CREDIT_GRANT_TAX_CODE_ID
{% endkonnect_api_request %}
<!--vale on-->

Replace `YOUR_CREDIT_GRANT_TAX_CODE_ID` with the `credit_grant_tax_code.id` value from the defaults response.

{:.info}
> **Note:** Only one tax code can be set as the default per category at a time.
> You can't delete a default tax code.
> To delete it, first set a different code as the default, then delete the original.

## Apply a tax code to a rate card

You can apply a tax code at two levels within your product catalog.

### Apply a tax code on a plan or add-on rate card

This sets the tax code for a specific product or fee, overriding the organization default. Set `tax_config` on the rate card, where `behavior` is `inclusive` or `exclusive` and `code.id` is the ID of your tax code.

The following request creates a plan with a rate card that uses your custom tax code, and captures the plan's ID:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans
method: POST
status_code: 201
body:
  name: Standard
  key: standard
  currency: USD
  billing_cadence: P1M
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
          tax_config:
            behavior: exclusive
            code:
              id: $TAX_CODE_ID
capture:
  - variable: PLAN_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

You can set `tax_config` the same way on the rate cards of an add-on, in the body of `POST /v3/openmeter/addons`.

To use this plan in the next section, publish it, then create a customer and subscribe them to it:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans/$PLAN_ID/publish
method: POST
status_code: 200
{% endkonnect_api_request %}

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
{% endkonnect_api_request %}

{% konnect_api_request %}
url: /v3/openmeter/subscriptions
method: POST
status_code: 201
capture:
  - variable: SUBSCRIPTION_ID
    jq: .id
body:
  customer:
    key: acme-inc
  plan:
    key: standard
{% endkonnect_api_request %}
<!--vale on-->

### Apply a tax code on a subscription rate card

This overrides the tax code for a specific customer's subscription, without changing the underlying plan.

Edit the running subscription by removing the rate card from its phase and adding it back with a different `tax_config`. In this example, the rate card switches to inclusive tax behavior:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/subscriptions/$SUBSCRIPTION_ID/edit
method: POST
status_code: 200
body:
  timing: immediate
  customizations:
    - type: remove_item
      phase_key: main
      item_key: api_requests
    - type: add_item
      phase_key: main
      rate_card:
        name: API requests
        key: api_requests
        feature:
          id: $FEATURE_ID
        billing_cadence: P1M
        price:
          type: unit
          amount: "1"
        tax_config:
          behavior: inclusive
          code:
            id: $TAX_CODE_ID
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> To do any of these steps in the {{site.konnect_short_name}} UI instead, see [Tax codes](/metering-and-billing/tax-codes/#apply-a-tax-code).
