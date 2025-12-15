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
    description: "Pricing applies only after the discounted usage value is reached. You can use this to define overage prices."
  - discount: Minimum spend
    description: "Guarantees a customer pays a specified amount, even if their usage is less. For example, if the minimum spend is set to $10, customers will pay $10 even if they only use $2 worth of the API or LLM token. The minimum spend line only appears on the invoice that includes the end of the line’s billing period."
  - discount: Maximum spend
    description: "Sets the maximum amount a customer will pay for a feature. For example, if maximum spend is set to $10, customers will only pay $10, even if they have a $100 worth of usage."
{% endtable %}
