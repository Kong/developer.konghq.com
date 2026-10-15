---
title: Create a {{site.metering_and_billing}} custom currency
permalink: /how-to/configure-metering-and-billing-custom-currencies/
description: Learn how to create a custom currency and give it a cost basis in {{site.konnect_short_name}} {{site.metering_and_billing}}.
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

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

tldr:
  q: How do I create a custom currency in {{site.konnect_short_name}} {{site.metering_and_billing}}?
  a: |
    Open **Metering & Billing** > **Settings** > **Currencies**, click **Create Custom Currency**, then define the currency's code, name, and formatting.
    Add a cost basis in the same form so that amounts in the new currency can be converted to a fiat currency for invoicing.

related_resources:
  - text: Currencies reference
    url: /metering-and-billing/currencies/
  - text: Billing and invoicing
    url: /metering-and-billing/billing-invoicing/
  - text: Product Catalog reference
    url: /metering-and-billing/product-catalog/

faqs:
  - q: Why can't I edit or delete a custom currency?
    a: |
      Custom currencies are immutable.
      After you create one, you can't change its code, name, or formatting, and you can't delete it.
      If you need different properties, create a new custom currency.

automated_tests: false
---

A custom currency is a unit of value that you define for your organization, such as credits, tokens, or compute units.
Because a custom currency isn't real money, it needs a cost basis, which is a rate that converts one unit of the currency into a fiat amount for invoicing.

In this guide, you'll create a custom currency, define its first cost basis, and then change its rate.

For background on how currencies and cost bases work, see [Currencies](/metering-and-billing/currencies/).

## Create a custom currency

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing** > **Settings**.
1. Click the **Currencies** tab.
1. Click **Create Custom Currency**.
1. In the **General Information** section, enter the following:
   * **Name**: The display name of the currency, up to 256 characters.
   * **Code**: The identifier for the currency, between 4 and 24 characters.
     It must be unique within your organization.
   * **Symbol**: An optional short symbol shown alongside amounts, up to 8 characters.
1. In the **Formatting** section, enter the following:
   * **Precision**: The number of decimal places, from 0 to 12.
   * **Decimal Mark**: A single character that separates the whole and fractional parts of an amount, such as `.`.
   * **Thousand Separator**: A single character that groups digits, such as `,`.
1. In the **Cost Basis** section, define what one unit of your currency is worth:
   * Enter the **rate** as a positive number.
   * Select the fiat currency the rate converts into.

   To price the same currency against more than one fiat currency, click **Add cost basis** and define another row.
   Each row must use a different fiat currency, because a currency can have only one active cost basis per fiat currency at a time.
1. Click **Save**.

## Validate

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing** > **Settings**.
1. Click the **Currencies** tab and confirm that your new currency is listed.
1. Click the currency and confirm that the cost basis you defined is listed with the expected rate.

## Change the rate

A cost basis can't be edited in place.
When you update a rate, {{site.metering_and_billing}} adds a new cost basis that takes effect immediately and ends the previous one.

1. On the currency's page, in the **Cost Basis** section, open the actions menu of the active cost basis and click **Update Rate**.
1. Enter the new rate.
1. Click **Save**.

The new cost basis is listed with the status **Active**.
Expand it to see the previous cost basis with the status **Superseded**, and confirm that its **Effective To** date matches the new cost basis's **Effective From** date.

To price the currency against another fiat currency, click **Add Cost Basis** on the currency's page instead.

## Next steps

To charge in your custom currency, use it as the currency of a plan, or override a rate card in a fiat-currency plan to use it.
For the rules that apply, see [Where currency is set](/metering-and-billing/currencies/#where-currency-is-set) and the [Product Catalog reference](/metering-and-billing/product-catalog/).
