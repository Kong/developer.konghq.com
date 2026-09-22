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
  - q: How do I change the rate of an existing custom currency?
    a: |
      Open the currency and click **Update Rate** on the cost basis you want to supersede.
      The previous rate stays in the history so that past invoices keep the rate they were billed at.

automated_tests: false
---

A custom currency is a unit of value that you define for your organization, such as credits, tokens, or compute units.
Because a custom currency isn't real money, it needs a cost basis, which is a rate that converts one unit of the currency into a fiat amount for invoicing.

In this guide, you'll create a custom currency and define its first cost basis.

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

To add another rate later, click **Add Cost Basis** on the currency's page.
