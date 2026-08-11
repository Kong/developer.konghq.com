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

## Manage tax codes

### Review default tax codes

{% navtabs "review-tax-codes" %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Settings**.
1. Click the **Tax Codes** tab to view system-managed and user-created tax codes and the current organization defaults.

{% endnavtab %}
{% navtab "API" %}

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/tax-codes
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

### Create a tax code

If none of the system-managed codes match your product category, you can create a custom tax code.
For Stripe, the `app_mappings` value must follow the `txcd_XXXXXXXX` format.
You can browse available values in the [Stripe Tax Code reference](https://docs.stripe.com/tax/tax-codes).

{% navtabs "create-tax-code" %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Settings**.
1. Click the **Tax Codes** tab.
1. Click **Create Tax Code**.
1. Fill in the name, key, and optional description.
1. Add an app mapping for your payment provider (for example, a Stripe tax code ID).
1. Click **Save**.

{% endnavtab %}
{% navtab "API" %}

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
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

### Set organization defaults

{% navtabs "set-tax-code-default" %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Settings**.
1. Click the **Tax Codes** tab.
1. Find the tax code you want to set as default and click the **...** menu.
1. Select **Set as invoicing default** or **Set as credit grant default**.

{% endnavtab %}
{% navtab "API" %}

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/defaults/tax-codes
method: PUT
status_code: 200
body:
  invoicing_tax_code:
    id: YOUR_TAX_CODE_ID
{% endkonnect_api_request %}
<!--vale on-->

Replace `YOUR_TAX_CODE_ID` with the `id` of the tax code you want to set as default.
Use `credit_grant_tax_code` instead of `invoicing_tax_code` to set the credit grant default.

{:.info}
> **Note:** Only one tax code can be set as the default per category at a time.
> You can't delete a default tax code.
> To delete it, first set a different code as the default, then delete the original.

{% endnavtab %}
{% endnavtabs %}

For a complete tutorial including applying tax codes to rate cards, see [Create and apply {{site.metering_and_billing}} tax codes](/how-to/configure-metering-and-billing-tax-codes/).

## Fallback chain

{{site.metering_and_billing}} uses a fallback chain to determine which tax code to apply, in the following order of priority:

1. **Rate card tax code**: Set on the rate card or add-on.
1. **Organization default**: The invoicing or credit grant default for the org.
1. **Provider default**: Used when the tax code has no app mappings.
