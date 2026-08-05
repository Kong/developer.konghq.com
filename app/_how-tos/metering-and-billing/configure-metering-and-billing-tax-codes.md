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
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
    - title: "{{site.konnect_short_name}} roles"
      content: |
        You need the [{{site.metering_and_billing}} Admin role](/konnect-platform/teams-and-roles/#metering-billing) in {{site.konnect_short_name}} to configure {{site.metering_and_billing}}.
      icon_url: /assets/icons/kogo-white.svg
    - title: "Plan and subscription"
      include_content: prereqs/metering-and-billing-plan-subscription
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

List all tax codes in your organization:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/tax-codes
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

If a system-managed code covers your needs and you want to set it as the default, update the organization defaults.
Replace `TAX_CODE_ID` with the `id` from the list response:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/defaults/tax-codes
method: PUT
status_code: 200
body:
  invoicing_tax_code:
    id: TAX_CODE_ID
{% endkonnect_api_request %}
<!--vale on-->

Use `credit_grant_tax_code` instead of `invoicing_tax_code` to set the credit grant default.

If the system-managed codes cover your needs, you can skip the next step and go directly to [Apply a tax code to a rate card](#apply-a-tax-code-to-a-rate-card).

## Create a tax code

If none of the system-managed codes match your product category, you can create a custom tax code.

For Stripe, the `app_mappings` value must follow the `txcd_XXXXXXXX` format.
You can browse available values in the [Stripe Tax Code reference](https://docs.stripe.com/tax/tax-codes).

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/tax-codes
method: POST
status_code: 201
body:
  name: Software as a Service
  key: saas
  description: Tax code for SaaS products
  app_mappings:
    - app_type: stripe
      tax_code: txcd_10000000
capture:
  - variable: TAX_CODE_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

To set the new code as the invoicing default:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/defaults/tax-codes
method: PUT
status_code: 200
body:
  invoicing_tax_code:
    id: $TAX_CODE_ID
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> **Note:** Only one tax code can be set as the default per category at a time.
> You can't delete a default tax code.
> To delete it, first set a different code as the default, then delete the original.

## Apply a tax code to a rate card

You can apply a tax code at two levels within your product catalog.

### Apply a tax code on a plan or add-on rate card

This sets the tax code for a specific product or fee, overriding the organization default.

Update the plan using `$PLAN_ID` from the prerequisites.
The `PUT` endpoint replaces the entire plan, so include all existing rate cards in the request:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans/$PLAN_ID
method: PUT
status_code: 200
body:
  name: Example Plan
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
          tax_config:
            behavior: exclusive
            code:
              id: $TAX_CODE_ID
{% endkonnect_api_request %}
<!--vale on-->

### Apply a tax code on a subscription rate card

This overrides the tax code for a specific customer's subscription, without changing the underlying plan.
Subscription rate card overrides are only available through the {{site.konnect_short_name}} UI.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing** > **Billing**.
1. Click a customer.
1. Click the **Subscription** tab.
1. Click **Manage** and expand **Advanced Settings**.
1. Enable **Advanced Customization**.
1. Click **Next**.
1. Edit or create a rate card.
1. In the **Pricing Model** configuration, expand **Advanced Settings**.
1. In the **Tax Behavior** dropdown, select the behavior you want to apply.
1. In the **Tax Code** dropdown, select your custom code.
1. Save the rate card.
