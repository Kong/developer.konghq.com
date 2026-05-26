---
title: "Pricing models"
content_type: reference
description: "Reference for the pricing models available in {{site.metering_and_billing}}, including flat fee, usage-based, tiered, package, and dynamic pricing."
layout: reference
products:
  - metering-and-billing
tools:
  - konnect-api
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
  - /metering-and-billing/product-catalog/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: "Rate Cards"
    url: /metering-and-billing/product-catalog/#rate-cards

---

With {{site.metering_and_billing}}, you can implement various pricing strategies to meet your business needs.

The currency for all pricing models is set based on the related plan.

## Free

The free pricing model doesn't require configuring rate card details and doesn't generate invoices.

If you want your plan to generate invoices, use a different pricing type and apply a 100% discount.

## Flat fee

Flat fee pricing is a simple pricing model where you charge a fixed amount for a product or service. This can be a one-time fee or a recurring fee.

* One-time fee pricing is a model where you charge customers a fixed amount for a product or service. This is typically used for installment fees or setup fees.
* Recurring fee pricing is a model where you charge customers a fixed amount at regular intervals, such as monthly or annually. This is a common model for product subscriptions.

The following table breaks down the options for configuring a flat fee pricing model:

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: Billing cadence
    description: Select the interval at which customers are billed for their usage, either recurring, or select "One time" to only bill once.
  - parameter: Payment term
    description: |
      Select whether the fee must be paid in advance (at the beginning of the billing period), or in arrears (at the end of the billing period).
      <br><br>
      Not applicable to one-time fees.
  - parameter: Price
    description: Price in the plan's configured currency.
  - parameter: Percentage discount
    description: Reduces price by a fixed percent across all usage.
  - parameter: Tax behavior
    description: |
      Select from one of the following behaviors:
      <br><br>
      * Inclusive: The listed price already includes tax.
      * Exclusive: The tax is added on top of the listed price.
      <br><br>

      See [Tax calculations](/metering-and-billing/product-catalog/#tax-calculations) for details.
  - parameter: Stripe Tax Code
    description: Select a [Stripe product tax code](https://docs.stripe.com/tax/tax-codes).
{% endtable %}

## Usage based

Usage-based pricing is a model where you charge customers based on the number of units they use, as reported by the [meter](/metering-and-billing/metering/).

For example, you could charge customers $0.01 per AI token used. 
If a customer uses 10,000 tokens, they would be charged:

```
$0.01 × 10,000 = $100
```

The following table breaks down the options for configuring a usage based pricing model:

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: Billing cadence
    description: Select the interval at which customers are billed for their usage.
  - parameter: Price per unit
    description: Price in the plan's configured currency charged per unit of usage as reported by the meter.
  - parameter: Usage discount
    description: Number of free units included before billing starts.
  - parameter: Percentage discount
    description: Reduces price by a fixed percent across all usage.
  - parameter: Minimum commitment
    description: The minimum amount the customer is charged per billing period, regardless of usage.
  - parameter: Maximum commitment
    description: The maximum amount the customer is charged per billing period, regardless of usage.
  - parameter: Tax behavior
    description: |
      Select from one of the following behaviors:
      <br><br>
      * Inclusive: The listed price already includes tax.
      * Exclusive: The tax is added on top of the listed price.
      <br><br>

      See [Tax calculations](/metering-and-billing/product-catalog/#tax-calculations) for details.
  - parameter: Stripe Tax Code
    description: Select a [Stripe product tax code](https://docs.stripe.com/tax/tax-codes).
{% endtable %}

## Tiered

Tiered pricing is a model where fees vary between usage levels. 
{{site.metering_and_billing}} supports two types of tiered pricing:

* [Graduated pricing](#graduated-pricing): Charge each unit according to the tier it falls into.
* [Volume pricing](#volume-pricing): Charge customers based on the highest achieved tier.

### Graduated pricing

Graduated pricing is a model where you charge each unit according to the tier it falls into.

For example:

<!--vale off-->
{% table %}
columns:
  - title: First Unit
    key: first_unit
  - title: Last Unit
    key: last_unit
  - title: Unit Price
    key: unit_price
  - title: Flat Price
    key: flat_price
rows:
  - first_unit: 0
    last_unit: 1000
    unit_price: $0.3
    flat_price: $0
  - first_unit: 1001
    last_unit: 5000
    unit_price: $0.2
    flat_price: $0
  - first_unit: 5001
    last_unit: "∞"
    unit_price: $0.1
    flat_price: $0
{% endtable %}
<!--vale on-->

In this example, a customer with 6,000 units would be charged as:

```
(1000 × $0.3) + (4000 × $0.2) + (1000 × $0.1) = $300 + $800 + $100 = $1,200
```

The following table breaks down the options for configuring a graduated pricing model:

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: Billing cadence
    description: Select the interval at which customers are billed for their usage, such as monthly or yearly.
  - parameter: Price mode
    description: |
      Set to **Graduated**. 
      The price of each unit is determined by the tier it falls into.
  - parameter: Tiers
    description: |
      Define pricing tiers by setting the first unit, last unit, unit price in the plan's configured currency, and an optional flat fee per tier.
  - parameter: Usage discount
    description: Number of free units included before billing starts.
  - parameter: Percentage discount
    description: Reduces price by a fixed percent across all usage.
  - parameter: Minimum commitment
    description: The minimum amount the customer is charged per billing period, regardless of usage.
  - parameter: Maximum commitment
    description: The maximum amount the customer is charged per billing period, regardless of usage.
  - parameter: Tax behavior
    description: |
      Select from one of the following behaviors:
      <br><br>
      * Inclusive: The listed price already includes tax.
      * Exclusive: The tax is added on top of the listed price.
      <br><br>

      See [Tax calculations](/metering-and-billing/product-catalog/#tax-calculations) for details.
  - parameter: Stripe Tax Code
    description: Select a [Stripe product tax code](https://docs.stripe.com/tax/tax-codes).
{% endtable %}

### Volume pricing

Volume pricing is a model where you charge customers based on the highest achieved tier.

For example:

<!--vale off-->
{% table %}
columns:
  - title: First Unit
    key: first_unit
  - title: Last Unit
    key: last_unit
  - title: Unit Price
    key: unit_price
  - title: Flat Price
    key: flat_price
rows:
  - first_unit: 0
    last_unit: 1000
    unit_price: $0.3
    flat_price: $0
  - first_unit: 1001
    last_unit: 5000
    unit_price: $0.2
    flat_price: $0
  - first_unit: 5001
    last_unit: "∞"
    unit_price: $0.1
    flat_price: $0
{% endtable %}
<!--vale on-->

Based on this table, a customer with 6,000 units would reach the unit price tier of $0.1, so they would be charged:

```
6,000 × $0.1 = $600
```

The following table breaks down the options for configuring a volume pricing model:

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: Billing cadence
    description: Select the interval at which customers are billed for their usage, such as monthly or yearly.
  - parameter: Price mode
    description: |
      Set to **Volume**. The price of all units is determined by the highest tier reached.
  - parameter: Tiers
    description: |
      Define pricing tiers by setting the first unit, last unit, unit price in the plan's configured currency, and an optional flat fee per tier.
  - parameter: Usage discount
    description: Number of free units included before billing starts.
  - parameter: Percentage discount
    description: Reduces price by a fixed percent across all usage.
  - parameter: Minimum commitment
    description: The minimum amount the customer is charged per billing period, regardless of usage.
  - parameter: Maximum commitment
    description: The maximum amount the customer is charged per billing period, regardless of usage.
  - parameter: Tax behavior
    description: |
      Select from one of the following behaviors:
      <br><br>
      * Inclusive: The listed price already includes tax.
      * Exclusive: The tax is added on top of the listed price.
      <br><br>

      See [Tax calculations](/metering-and-billing/product-catalog/#tax-calculations) for details.
  - parameter: Stripe Tax Code
    description: Select a [Stripe product tax code](https://docs.stripe.com/tax/tax-codes).
{% endtable %}

### Flat prices in tiers

With tiered pricing, you can define flat fees for each tier in addition to unit pricing.

For example, you could charge $500 for the first tier and $0.1 per unit for the rest. 

This is useful to define overage charges or to bill a flat fee regardless of usage.
For example:

<!--vale off-->
{% table %}
columns:
  - title: First Unit
    key: first_unit
  - title: Last Unit
    key: last_unit
  - title: Unit Price
    key: unit_price
  - title: Flat Price
    key: flat_price
rows:
  - first_unit: 0
    last_unit: 1000
    unit_price: $0
    flat_price: $500
  - first_unit: 1001
    last_unit: "∞"
    unit_price: $0.1
    flat_price: $0
{% endtable %}
<!--vale on-->

Based on this table, a customer that uses 2,000 units would be charged as:

```
(1000 * $0 + $500) + (1000 * $0.1 + $0) = $500 + $100 = $600
```

Tiers start from 0, so defining a flat fee in the first tier will always cause the customer to be billed, regardless of usage.
For example, if you have a flat fee of $500 in the first tier, the total amount will be $500 when the quantity is 0.

To bill $0 when there's no usage, set the unit price for the first tier and omit the flat price. Let's use the previous example, but this time set a $500 flat fee for the first tier and $0.1 per unit for the rest:

<!--vale off-->
{% table %}
columns:
  - title: First Unit
    key: first_unit
  - title: Last Unit
    key: last_unit
  - title: Unit Price
    key: unit_price
  - title: Flat Price
    key: flat_price
rows:
  - first_unit: 0
    last_unit: 1
    unit_price: $500
    flat_price: $0
  - first_unit: 2
    last_unit: 1000
    unit_price: $0
    flat_price: $0
  - first_unit: 1001
    last_unit: "∞"
    unit_price: $0.1
    flat_price: $0
{% endtable %}
<!--vale on-->

In this example, if a customer uses 2,000 units, they will be charged as:

```
(1 * $500 + $0) + (999 * $0 + $0) + (1000 * $0.1 + $0) = $500 + $0 + $100 = $600
```

But if this customer uses 0 units, they will be charged as:

```
(0 * $500 + $0) + (0 * $0 + $0) + (0 * $0.1 + $0) = $0 + $0 + $0 = $0
```

## Package

Package pricing is a model where you charge customers based on fixed-sized usage packages.
Customers are billed per package rather than per individual unit.

This model is particularly useful for services that want to simplify billing by offering usage in fixed-size bundles rather than per-unit charges.

In package pricing:

* Each package contains a fixed number of units.
* The price is set per package.
* The total price is calculated based on the number of packages needed to accommodate the total usage.

Package pricing is particularly effective for:

* API services where you want to simplify billing by offering fixed-size bundles.
* Storage services where you want to sell storage in predefined chunks.
* Compute services where you want to offer processing time in fixed blocks.
* Any service where you want to simplify billing by avoiding per-unit calculations.

Let's look at examples with a package size of 20 units and a price of $10 per package:

<!--vale off-->
{% table %}
columns:
  - title: Usage
    key: usage
  - title: Calculation
    key: calculation
  - title: Total Price
    key: total_price
  - title: Explanation
    key: explanation
rows:
  - usage: 0 units
    calculation: 0 packages × $10
    total_price: $0
    explanation: No packages needed as there's no usage.
  - usage: 20 units
    calculation: 1 package × $10
    total_price: $10
    explanation: Usage fits exactly in one package.
  - usage: 20.1 units
    calculation: 2 packages × $10
    total_price: $20
    explanation: Adding 0.1 units requires a new package.
  - usage: 98 units
    calculation: 5 packages × $10
    total_price: $50
    explanation: Usage requires 5 full packages.
{% endtable %}
<!--vale on-->

Any usage of a positive value will be rounded up to the next closest package, while zero usage won't generate any charge. 
If you want zero usage to charge customers, combine package pricing with minimum commitments.

The following table breaks down the options for configuring a package pricing model:

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: Billing cadence
    description: Select the interval at which customers are billed for their usage, such as monthly or yearly.
  - parameter: Price per package
    description: Price in the plan's configured currency charged per package.
  - parameter: Quantity per package
    description: Number of units included in each package.
  - parameter: Usage discount
    description: Number of free units included before billing starts.
  - parameter: Percentage discount
    description: Reduces price by a fixed percent across all usage.
  - parameter: Minimum commitment
    description: The minimum amount the customer is charged per billing period, regardless of usage.
  - parameter: Maximum commitment
    description: The maximum amount the customer is charged per billing period, regardless of usage.
  - parameter: Tax behavior
    description: |
      Select from one of the following behaviors:
      <br><br>
      * Inclusive: The listed price already includes tax.
      * Exclusive: The tax is added on top of the listed price.
      <br><br>

      See [Tax calculations](/metering-and-billing/product-catalog/#tax-calculations) for details.
  - parameter: Stripe Tax Code
    description: Select a [Stripe product tax code](https://docs.stripe.com/tax/tax-codes).
{% endtable %}

## Dynamic

Dynamic pricing is a model where USD prices are created dynamically from meter values.

With the dynamic pricing model, meters track cost rather than usage. 
The price is calculated based on the underlying meter's value, optionally with a markup rate applied. 

This model is useful when the price per unit varies request by request.
Since modeling this complexity at the product catalog level is not feasible, the price calculation is deferred to the event reporting stack: the meter value is expected to represent the cost of each request.

Dynamic pricing is particularly effective for:

* Cost-plus pricing models where you want to add a markup to your costs.
* Services where prices fluctuate based on market conditions (for example, SMS or MMS).
* Customer-specific pricing scenarios where the meter value already reflects the cost in the customer's configured currency.
* Services that need to pass through variable costs with a markup.

The following table breaks down the options for configuring a dynamic pricing model:

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: Billing cadence
    description: Select the interval at which customers are billed for their usage, such as monthly or yearly.
  - parameter: Multiplier
    description: An optional multiplier applied to each incoming meter value. Defaults to 1 if not set.
  - parameter: Usage discount
    description: Number of free units included before billing starts.
  - parameter: Percentage discount
    description: Reduces price by a fixed percent across all usage.
  - parameter: Minimum commitment
    description: The minimum amount the customer is charged per billing period, regardless of usage.
  - parameter: Maximum commitment
    description: The maximum amount the customer is charged per billing period, regardless of usage.
  - parameter: Tax behavior
    description: |
      Select from one of the following behaviors:
      <br><br>
      * Inclusive: The listed price already includes tax.
      * Exclusive: The tax is added on top of the listed price.
      <br><br>

      See [Tax calculations](/metering-and-billing/product-catalog/#tax-calculations) for details.
  - parameter: Stripe Tax Code
    description: Select a [Stripe product tax code](https://docs.stripe.com/tax/tax-codes).
{% endtable %}

### Tracking cost with meters

With dynamic pricing, meters track cost instead of usage. 
Meters are designed to track usage by default, so keep the following in mind:

* There is no exchange rate. All customers and meter costs must be in the same currency.
* Cost-tracking meters look the same as usage-tracking meters. Use naming conventions to distinguish them.

### Markup rate

The final price is calculated by multiplying the base price from the meter by the markup rate. 
The default markup rate is 1.

Let's look at examples with a base price of $100, and what happens at each rate:

<!--vale off-->
{% table %}
columns:
  - title: Markup Rate
    key: markup_rate
  - title: Calculation
    key: calculation
  - title: Final Price
    key: final_price
  - title: Explanation
    key: explanation
rows:
  - markup_rate: 0.0
    calculation: $100 × 0.0
    final_price: $0
    explanation: A rate of 0 results in no charge
  - markup_rate: 0.5
    calculation: $100 × 0.5
    final_price: $50
    explanation: A rate of 0.5 reduces the price by 50%
  - markup_rate: 1.0
    calculation: $100 × 1.0
    final_price: $100
    explanation: A rate of 1 passes through the base price unchanged
  - markup_rate: 1.5
    calculation: $100 × 1.5
    final_price: $150
    explanation: A rate of 1.5 increases the price by 50%
  - markup_rate: 2.0
    calculation: $100 × 2.0
    final_price: $200
    explanation: A rate of 2 doubles the price
{% endtable %}
<!--vale on-->

## Overage fees

Overages are additional charges that customers incur when they exceed their usage limits. 
You can model overages with usage discounts.
This option is available for usage-based, tiered, package, and dynamic pricing models under **Advanced Settings**.

When a pricing model has a usage discount configured, {{site.metering_and_billing}} applies the discount to the metered usage first, then applies a fee to the remaining usage.

For example, if a customer's metered usage is 1,000 units, the usage discount is 900 units, and the per-unit price is $0.1, they will be charged:

```
(1000 - 900) × $0.1 = 100 × $0.1 = $10
```

{:.info}
> Usage discounts are applied before percentage discounts.

If the customer in the example above also has a percentage discount of 10%, the calculation is:

```
(1000 - 900) × $0.1 × (100% - 10%) = 100 × $0.1 × 0.9 = $9
```

To define a flat fee for usage before the overage fee, add a rate card with a flat fee alongside the overage fee rate card.
For simple usage-based pricing, you can achieve the same result by creating a tiered pricing model with a flat fee in the first tier.

## Set up a pricing model

Set up a pricing model for a rate card through the {{site.konnect_short_name}} UI.

### Prerequisites 
To set up a pricing model, you must have:
* [A feature](/metering-and-billing/product-catalog/#features)
* [A plan](/metering-and-billing/product-catalog/#plans)

### Steps
To set up a pricing model on a rate card:
1. Navigate to **Metering and Billing** > **Product Catalog**.
1. Click the **Plans** tab. 
1. Select a plan and click **Add Rate Card**.
1. Select a feature.
1. Select and configure the pricing model. Refer to the parameter reference for your model to fill out the form:
   * [Flat fee](#flat-fee)
   * [Usage based](#usage-based)
   * [Tiered](#tiered)
   * [Package](#package)
   * [Dynamic](#dynamic)

   Free pricing models have no settings to configure.
1. Set the [entitlement](/metering-and-billing/entitlements/).
1. Click **Save Rate Card**.
1. Click **Publish Plan**.