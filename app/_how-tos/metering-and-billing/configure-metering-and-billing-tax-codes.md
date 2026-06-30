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
  inline:
    - title: "{{site.konnect_short_name}} roles"
      content: |
        You need the [{{site.metering_and_billing}} Admin role](/konnect-platform/teams-and-roles/#metering-billing) in {{site.konnect_short_name}} to configure {{site.metering_and_billing}}.
      icon_url: /assets/icons/kogo-white.svg

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

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing** > **Settings**.
1. Click the **Tax Codes** tab.
1. Review the list of system-managed and user-created tax codes and the current defaults.
1. To change which code is the default, click the action menu on any row and select **Set as Invoicing Default** or **Set as Credit Grant Default**.

If the system-managed codes cover your needs, you can skip the next step and go directly to [Apply a tax code to a rate card](#apply-a-tax-code-to-a-rate-card).

## Create a tax code

If none of the system-managed codes match your product category, you can create a custom tax code:

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing** > **Settings**.
1. Click the **Tax Codes** tab.
1. Click **Create tax code**.
1. Enter a name, key, and optional description.
1. Add one or more app mappings.
   For Stripe, the value must follow the `txcd_XXXXXXXX` format.
   You can browse available values in the [Stripe Tax Code reference](https://docs.stripe.com/tax/tax-codes).
1. Optionally, set the code as the **Invoicing Default** or **Credit Grant Default**.
1. Click **Save**.

{:.info}
> **Note:** Only one tax code can be set as the default per category at a time.
> You can't delete a default tax code.
> To delete it, first set a different code as the default, then delete the original.

## Apply a tax code to a rate card

You can apply a tax code at two levels within your product catalog.

### Apply a tax code on a plan or add-on rate card

This sets the tax code for a specific product or fee, overriding the organization default.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing** > **Product Catalog**.
1. Click **Plans** or **Add-ons** and select a plan or add-on.
1. Open or create a rate card.
1. In the **Pricing Model** configuration, expand **Advanced Settings**.
1. Select the **Tax Behavior**.
1. Set the **Tax Code** to your custom code.
1. Save the rate card.

### Apply a tax code on a subscription rate card

This overrides the tax code for a specific customer's subscription, without changing the underlying plan.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing** > **Billing**.
1. Click a customer.
1. Click the **Subscription** tab.
1. Click **Manage** and expand **Advanced Settings**.
1. Enable **Advanced Customization**.
1. Click **Next**.
1. Open or create a rate card.
1. In the **Pricing Model** configuration, expand **Advanced Settings**.
1. Select the **Tax Behavior**.
1. Set the **Tax Code** to your custom code.
1. Save the rate card.
