---
title: "Tax codes"
content_type: reference
description: "Learn how tax codes work in {{site.konnect_short_name}} {{site.metering_and_billing}}, including tax behavior, organization defaults, and the fallback chain."
layout: reference
products:
  - metering-and-billing
tools:
  - konnect-api
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
related_resources:
  - text: "Billing and invoicing"
    url: /metering-and-billing/billing-invoicing/
  - text: "Configure tax codes"
    url: /how-to/configure-metering-and-billing-tax-codes/
  - text: "Stripe Tax Code reference"
    url: https://docs.stripe.com/tax/tax-codes
---

Tax codes classify goods and services for tax purposes.
{{site.konnect_short_name}} {{site.metering_and_billing}} uses them to pass structured tax information to payment providers so that tax is calculated correctly on invoices.

## What is a tax code?

A tax code is a named, reusable object in your organization that maps a product category to provider-specific identifiers.
Each tax code has:

* A human-readable key and name (for example, key: `saas_software`, name: `SaaS Software`).
* An optional description.
* One or more app mappings, which are the provider-specific code strings for each connected payment app.

If you've [integrated Stripe](/metering-and-billing/stripe-integration/) with {{site.metering_and_billing}}, app mapping values follow Stripe's tax code format: `txcd_XXXXXXXX` (for example, `txcd_10000000`).
You can browse available codes in the [Stripe Tax Code reference](https://docs.stripe.com/tax/tax-codes).

{:.info}
> **Note:** {{site.metering_and_billing}} pre-provisions the most commonly used Stripe tax codes for every organization.
> These system-managed codes are read-only and can't be edited or deleted.
> You can set a system-managed code as the organization default.

## Tax behavior

Every taxable object carries a tax behavior that controls how the listed price is interpreted:

<!--vale off-->
{% table %}
columns:
  - title: Value
    key: value
  - title: Meaning
    key: meaning
rows:
  - value: "`exclusive`"
    meaning: Tax is added on top of the stated price.
  - value: "`inclusive`"
    meaning: Tax is included in the stated price.
  - value: "`empty`"
    meaning: Falls back to the provider's default behavior.
{% endtable %}
<!--vale on-->

## Default organization tax codes

Default organization tax codes act as a safety net, guaranteeing that every taxable item has a tax code even when there's no specific setting configured.
Tax code defaults are defined once per organization and apply across all billing profiles, customers, plans, and invoices.

{{site.metering_and_billing}} sets two defaults when your organization is created:

<!--vale off-->
{% table %}
columns:
  - title: Default
    key: default
  - title: Applies to
    key: applies_to
  - title: Used when
    key: used_when
  - title: Name
    key: name
  - title: Value
    key: value
rows:
  - default: Invoicing default
    applies_to: Flat-fee charges and usage-based charges
    used_when: The charge doesn't have a tax code from a more specific layer.
    name: Provider default
    value: No app mappings. Falls back to the provider's default behavior.
  - default: Credit grant default
    applies_to: Credit purchase charges (credit grants)
    used_when: The credit purchase has no explicit tax code.
    name: Nontaxable
    value: "Stripe: `txcd_00000000`"
{% endtable %}
<!--vale on-->

## View tax codes

To view your default and user-created tax codes, use the following:

{% navtabs "view-tax-codes" %}
{% navtab "UI" %}

Navigate to **Metering & Billing** > **Settings** and click the **Tax Codes** tab.

{% endnavtab %}
{% navtab "API" %}

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

{% endnavtab %}
{% endnavtabs %}

## Apply a tax code

To apply tax codes other than the default, set a tax code on the rate card of any plan, add-on, or customer subscription:

{% navtabs "apply-tax-code" %}
{% navtab "UI" %}

Navigate to the rate card on any plan, add-on, or customer subscription, and expand the advanced settings for the pricing model.

{% endnavtab %}
{% navtab "API" %}

Set `tax_config` on the rate card, where `behavior` is `inclusive` or `exclusive` and `code.id` is the ID of your tax code.

To apply a tax code to a plan rate card, include `tax_config` in the rate card when you create the plan:

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
            id: YOUR_FEATURE_ID
          billing_cadence: P1M
          price:
            type: unit
            amount: "1"
          tax_config:
            behavior: exclusive
            code:
              id: YOUR_TAX_CODE_ID
{% endkonnect_api_request %}
<!--vale on-->

Replace `YOUR_FEATURE_ID` with the ID of the feature and `YOUR_TAX_CODE_ID` with the ID of the tax code.

To apply a tax code to a rate card on a running subscription, edit the subscription by removing the rate card from its phase and adding it back with a different `tax_config`:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/subscriptions/YOUR_SUBSCRIPTION_ID/edit
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
          id: YOUR_FEATURE_ID
        billing_cadence: P1M
        price:
          type: unit
          amount: "1"
        tax_config:
          behavior: inclusive
          code:
            id: YOUR_TAX_CODE_ID
{% endkonnect_api_request %}
<!--vale on-->

Replace `YOUR_SUBSCRIPTION_ID` with the ID of the subscription, and use the same feature and tax code IDs as in the previous request.

{% endnavtab %}
{% endnavtabs %}

For a complete tutorial, see [Create and apply {{site.metering_and_billing}} tax codes](/how-to/configure-metering-and-billing-tax-codes/).

## Fallback chain

{{site.metering_and_billing}} uses a fallback chain to determine which tax code to apply, in the following order of priority:

1. **Rate card tax code**: Set on the rate card or add-on.
1. **Organization default**: The invoicing or credit grant default for the org.
1. **Provider default**: Used when the tax code has no app mappings.
