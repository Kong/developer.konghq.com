## Discounts and commitments

Rate Cards discounts and commitments allow you to adjust the price of a feature in a plan. 

The following table describes the discounts and commitment types:

{% table %}
columns:
  - title: Discount
    key: discount
  - title: Description
    key: description
rows:
  - discount: Percentage discount
    description: "Reduces price by a fixed percent across all usage."
  - discount: "[Usage discount](#usage-discounts)"
    description: "Provides discounts on the metered value."
  - discount: Minimum spend
    description: "Guarantees a customer pays a specified amount, even if their usage is less. For example, if the minimum spend is set to $10, customers will pay $10 even if they only use $2 worth of the API or LLM token. The minimum spend line only appears on the invoice that includes the end of the line’s billing period."
  - discount: Maximum spend
    description: "Sets the maximum amount a customer will pay for a feature. For example, if maximum spend is set to $10, customers will only pay $10, even if they have a $100 worth of usage."
{% endtable %}

### Usage discounts
Usage discounts apply **only to usage-based line items** (not flat-fee prices).

The discount can be consumed across multiple invoices.  
The discount is applied until the total available discount amount is fully depleted.

For example: 

A line has a 500-unit usage discount, and usage is billed in three parts:

* 300 units  
* 250 units  
* 100 units  

The discount is applied progressively:

1. Invoice 1 
   * Usage: 300  
   * Discount applied: 300  
   * Billed quantity: **0**  
   * Remaining discount: **200**

1. Invoice 2 
   * Usage: 250  
   * Discount applied: 200  
   * Billed quantity: **50**  
   * Remaining discount: **0**

1. Invoice 3  
   * Usage: 100  
   * Discount applied: 0  
   * Billed quantity: **100**


