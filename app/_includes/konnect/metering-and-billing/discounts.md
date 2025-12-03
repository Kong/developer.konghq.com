## Discounts and commitments

Rate Cards support two different types of discounts that can be applied to charges: 

* Percentage discount: Reduce price by a fixed percent across all usage
* Usage discount: Enable you to provide discounts on the metered value. 

### Usage Discounts
Usage discounts apply **only to usage-based line items** (not flat-fee prices).

The discount configuration is defined in:

* `rateCard.discounts.usage` — the discount definition  
* `line.discounts.usage` — the calculated discount applied to the line  
* `line.meteredQuantity` — the raw metered value for the billing period  

When **usage discounts** are combined with **Progressive Billing**, the discount may be consumed across multiple invoices.  
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


### Percentage discounts

The effect of a **percentage discount** (the actual discounted amount) is available in the line’s `discounts.amount` array.  
The discount’s `reason` field is set to the same value as `rateCard.discounts.percentage`.

### Minimum spend

A **minimum spend** is always shown as an additional detailed line.  
The line’s `category` is set to `charge`.

If **Progressive Billing** is enabled, the minimum spend line only appears on the invoice that includes the **end** of the line’s billing period.

### Maximum spend

Any spend above the configured **maximum spend** threshold results in an amount discount, populated in `discounts.amount`.  
The `reason` field for these discount entries is set to `maximumSpend`.
