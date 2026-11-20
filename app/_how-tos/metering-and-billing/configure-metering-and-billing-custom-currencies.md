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
    - title: "{{site.konnect_short_name}} access token"
      include_content: prereqs/metering-and-billing-konnect-token
      icon_url: /assets/icons/kogo-white.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

tldr:
  q: How do I create a custom currency in {{site.konnect_short_name}} {{site.metering_and_billing}}?
  a: |
    Send a `POST` request to the `/v3/openmeter/currencies/custom` endpoint to define the currency's code, name, and formatting.
    Then send a `POST` request to its `cost-bases` endpoint to add a cost basis, so that amounts in the new currency can be converted to a fiat currency for invoicing.

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

A custom currency is a unit of value that you define for your organization, such as tokens, API calls, or compute units.
Because a custom currency isn't real money, it needs a cost basis, which is a rate that converts one unit of the currency into a fiat amount for invoicing.

In this guide, you'll create a custom currency, define its first cost basis, and then change its rate.

For background on how currencies and cost bases work, see [Currencies](/metering-and-billing/currencies/).

## Create a custom currency

Create the custom currency. The request body has the following fields:
* `name`: The display name of the currency, up to 256 characters.
* `code`: The identifier for the currency, between 4 and 24 characters. It must be unique within your organization.
* `symbol`: An optional short symbol shown alongside amounts, up to 8 characters.
* `precision`: The number of decimal places, from 0 to 12.
* `decimal_mark`: A single character that separates the whole and fractional parts of an amount, such as `.`.
* `thousand_separator`: A single character that groups digits, such as `,`.

The request captures the new currency's ID so you can add a cost basis to it:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/currencies/custom
method: POST
status_code: 201
body:
  name: AI Credits
  code: AICREDITS
  symbol: AIC
  precision: 2
  decimal_mark: "."
  thousand_separator: ","
capture:
  - variable: CURRENCY_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->

Define what one unit of your currency is worth by adding a cost basis. The `rate` is a positive number as a string, and `fiat_code` is the fiat currency the rate converts into:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/currencies/custom/$CURRENCY_ID/cost-bases
method: POST
status_code: 201
body:
  fiat_code: USD
  rate: "0.01"
{% endkonnect_api_request %}
<!--vale on-->

To price the same currency against more than one fiat currency, add another cost basis with a different `fiat_code`.
A currency can have only one active cost basis per fiat currency at a time.

{:.info}
> To create a custom currency in the {{site.konnect_short_name}} UI instead, go to **Metering & Billing** > **Settings** > **Currencies** and click **Create Custom Currency**.

## Validate

List the cost bases of your currency and confirm that the cost basis you defined has the expected rate:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/currencies/custom/$CURRENCY_ID/cost-bases
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

You can also confirm that your currency is listed:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/currencies
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

## Change the rate

A cost basis can't be edited in place.
To update a rate, add a new cost basis for the same fiat currency. {{site.metering_and_billing}} makes it take effect immediately and ends the previous one.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/currencies/custom/$CURRENCY_ID/cost-bases
method: POST
status_code: 201
body:
  fiat_code: USD
  rate: "0.02"
{% endkonnect_api_request %}
<!--vale on-->

List the cost bases again. The new cost basis is the active one, and the previous cost basis has an `effective_to` date that matches the new cost basis's `effective_from` date.

To price the currency against another fiat currency, add a cost basis with a different `fiat_code` instead.

## Next steps

To charge in your custom currency, use it as the currency of a plan, or override a rate card in a fiat-currency plan to use it.
For the rules that apply, see [Where currency is set](/metering-and-billing/currencies/#where-currency-is-set) and the [Product Catalog reference](/metering-and-billing/product-catalog/).
