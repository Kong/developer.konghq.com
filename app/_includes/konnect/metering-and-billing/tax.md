{{site.metering_and_billing}} doesn't calculate taxes itself. Instead, it configures external services to do so with Product Catalog. Currently, {{site.metering_and_billing}} supports [Stripe Tax](https://stripe.com/tax).

{{site.metering_and_billing}} supports the following tax settings:

* Inclusive: The listed price already includes tax. A 10% inclusive tax on a $500 item still results in a $500 invoice.
* Exclusive: Tax is added on top of the listed price. A 10% exclusive tax on a $500 item raises the invoice total to $550.
* Tax codes: Apply a tax code to a feature. Some payment providers, like Stripe, apply their own default [tax code](https://docs.stripe.com/tax/tax-codes). In those cases, you can leave {{site.metering_and_billing}}'s tax settings blank.

You can enable tax collection from a [Rate Card](/metering-and-billing/product-catalog/) or the [billing profile settings](https://cloud.konghq.com/metering-billing/billing-profiles).

In {{site.metering_and_billing}}, you can define the tax behavior on multiple levels, from lowest to highest precedence:
<!--vale off-->
{% table %}
columns:
  - title: Use Case
    key: use_case
  - title: Setting
    key: setting
rows:
  - use_case: "Fallback to the tax behavior of the payment provider, like Stripe."
    setting: "[Payment provider](https://cloud.konghq.com/metering-billing/apps)"
  - use_case: "Define the default tax behavior, if any, for all customers."
    setting: "[Billing profile](https://cloud.konghq.com/metering-billing/billing-profiles)"
  - use_case: "Override the default tax behavior on a per Rate Card basis."
    setting: "[Plan Rate Card](/metering-and-billing/product-catalog/#rate-cards)"
  - use_case: "Override the default tax behavior on a per-subscription basis."
    setting: "[Subscription Rate Card](/metering-and-billing/product-catalog/#rate-cards)"
  - use_case: "Override the tax behavior per invoice line item."
    setting: "[Invoice](https://cloud.konghq.com/metering-billing/invoices)"
{% endtable %}
<!--vale on-->

We recommend setting the tax behavior on the payment provider level if you use Stripe for tax calculation. Tax behavior is optional at the billing profile, plan rate card, and subscription rate card levels.

When tax enforcement is enabled, {{site.metering_and_billing}} prevents you from starting a subscription if automatic tax calculation isn't supported. When enforcement is enabled, the following actions are blocked:

* Creating a paid subscription when tax cannot be calculated
* Finalizing an invoice when tax cannot be calculated
* Validation logic also varies by tax service. For example, with Stripe Tax, {{site.metering_and_billing}} uses Stripe's APIs to verify whether tax calculation is supported for the customer. In that case of Stripe, the customer must have a valid tax location.