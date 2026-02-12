---
title: "Billing, invoicing, and subscriptions"
content_type: reference
description: "Learn how billing, invoicing, and subscriptions work in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
---

## Billing profiles

Billing profiles contain the invoicing, payment, and tax settings for billing and controls invoice generation. An organization can have multiple billing profiles defined. This is useful when you have different billing needs for different customers. For example, you might want some customers to be billed via Stripe and others via bank transfer.

Each {{site.metering_and_billing}} instance has one default billing profile that all new customers will be assigned to unless otherwise specified. An exception to this is when modifying the default billing profile from Sandbox to a production app, customers with outstanding invoices are automatically retained on the Sandbox-based billing profile to prevent unintended charges from test data.

A billing profile is linked to a specific App. This association is established during the billing profile's creation and remains immutable. When transitioning to a new app, organizations must [migrate to a new billing profile](#customer-billing-profile-overrides).

Billing profiles can be managed from the [**Billing Profiles**](https://cloud.konghq.com/metering-billing/billing-profiles) tab in **{{site.metering_and_billing}} > Settings** in the {{site.konnect_short_name}} UI.

### Invoicing settings

The invoicing settings define the invoice creation process and lifecycle management parameters, including:

* Whether invoices are sent automatically for payment collection or if they require approval first
* If intermediate invoices are allowed
* How long to wait for late usage events
* How long to wait before sending the invoice

You may want to disable auto advance for the following use cases:

* Initial billing configuration validation: Enables manual verification of charges prior to customer distribution
* Emergency control mechanism: Provides immediate invoice control during system integration issues or event reporting anomalies
* External system integration requirements: Accommodates scenarios requiring synchronization with external systems prior to invoice finalization

Strategic applications of auto advance with extended draft periods:

* Facilitates internal review processes by support and sales teams before customer distribution.
* Enables quality assurance checks on high-value accounts.
* Default tax behavior establishes the standard tax handling for invoice line items, unless overridden by subscription-specific Rate Card settings.

### Payment settings

Payment method determines the invoice settlement process. {{site.metering_and_billing}} currently supports two payment methods:

* **Charge automatically:** Processes payment immediately using the customer's stored payment card.
* **Send invoice:** Issues an invoice to the customer for payment via their preferred method (credit card, bank transfer, or other supported payment options).

Invoice due after/Payment due after specifies the duration allowed for invoice payment after finalization. This grace period applies to all payment methods, including credit card payments which may be declined. If payment is not received within this timeframe, the invoice status will transition to overdue.

### Customer billing profile overrides

Customer overrides allows you to assign a different billing profile to customers other than the default. By default customers are pinned to the default billing profile. This is useful when you have different billing needs for different customers. For example, you might want some customers to be billed via Stripe and others via bank transfer.

Customer overrides can be useful for the following use cases:
* **Enterprise billing**: Set up one billing profile for SaaS customers and another for Enterprise customers (with send invoice for bank transfer selected).
* **Migrating customers billing**: Create a new billing profile that you want to migrate customers to and then assign them to the new profile with a customer override.

Configure customer overrides by navigating to **{{site.metering_and_billing}}** > [**Billing**](https://cloud.konghq.com/metering-billing/customers), click a customer, then navigate to the **Billing Profile** section of the customer settings.

## Tax calculations

{% include_cached /konnect/metering-and-billing/tax.md %}

## Invoicing 

Invoices are created when a subscription starts and are kept up-to-date with the subscription state. The subscription [Rate Card](/metering-and-billing/product-catalog/#rate-cards) governs the price and the invoicing frequency for the specified feature. For example, a subscription with a single in-advance flat fee billed monthly will generate one invoice per month.

{{site.metering_and_billing}} invoices follow a well-defined lifecycle that aligns directly with their associated subscription periods. Each invoice serves as an immutable record of billing information, which ensures complete data integrity and audit compliance throughout the billing process.

The invoice document maintains comprehensive and structured information that is essential for billing transparency. Invoices contain the following information:
* The total amount of lines before discounts and taxes
* The total amount of charges (minimum spend) before discounts and taxes
* The total amount of discounts applied
* The total amount of inclusive and exclusive taxes
* The total amount of taxes
* The total amount after taxes and discounts charged to the customer

To view invoices in {{site.konnect_short_name}}, navigate to **{{site.metering_and_billing}}** > **Billing** and click the **Invoices** tab. 

### Invoice lifecycle

The following table describes the different states of the invoice lifecycle:
<!--vale off-->
{% table %}
columns:
  - title: State
    key: state
  - title: Possible transitions
    key: transitions
  - title: Description
    key: description
rows:
  - state: Gathering
    transitions: N/A
    description: "Gathering the items to be invoiced. Note: for details please see Gathering Invoices, in this page only the other states will be discussed"
  - state: Draft
    transitions: "Issued, Deleted"
    description: "The invoice is created and in draft state. The invoice can only be updated in this state. In later states the invoice can only be voided."
  - state: Issued
    transitions: Payment Processing
    description: "The invoice is issued to the customer."
  - state: Payment Processing
    transitions: "Overdue, Unable to be collected, Paid, Void"
    description: "Payment is being processed."
  - state: Overdue
    transitions: "Paid, Void, Unable to be collected"
    description: "The invoice is overdue."
  - state: Unable to be collected
    transitions: "Paid, Void"
    description: "The invoice has been marked as unable to be collected."
  - state: Paid
    transitions: N/A
    description: "The invoice has been paid."
  - state: Void
    transitions: N/A
    description: "The invoice has been voided."
  - state: Deleted
    transitions: N/A
    description: "The invoice has been deleted and is no longer available."
{% endtable %}
<!--vale on-->

### Gathering invoices

{{site.metering_and_billing}} gathers invoices with upcoming charges for the active running billing cycle. These invoices show current pending charges for the user's current billing period in real-time when fetched or viewed, providing visibility into accruing usage before the final invoice is issued.

Gathering invoices are automatically deleted when the last item for a subscription has been billed for.

Given an invoice is always single currency, if the customer was migrated between currencies they might have one gathering invoice per currency.

{:.warning}
> **Important:** For systematic changes that need to persist across billing cycles, we recommend modifying the subscription directly rather than editing gathering invoices. This ensures consistent billing behavior aligned with the intended subscription terms.

{% include_cached /konnect/metering-and-billing/discounts.md %}

## Subscriptions

Billing and subscriptions in {{site.metering_and_billing}} create relationships between customers and their pricing model. This serves as the bridge between your customers, their usage data, and how that usage translates into billable amounts.

Subscriptions automate the billing lifecycle by:

* **Tracking usage** through meters
* **Applying pricing logic** from plans or custom configurations
* **Generating invoices** based on billing cadences
* **Enforcing entitlements** to control feature access

Subscriptions can be created from predefined plans or fully customized at creation time to accommodate unique customer requirements. This flexibility supports everything from self-serve sign-ups to enterprise contract negotiations.

To add a subscription to a customer, navigate to **{{site.metering_and_billing}}** > **Billing**, click your customer, and then click the **Subscriptions** tab in the {{site.konnect_short_name}} UI.

## Plan migration

Plans in {{site.metering_and_billing}} are versioned. When you update a plan, existing subscriptions remain on their current version. This is known as "grandfathering". Customers keep their existing pricing until they're explicitly migrated.

Migrating a subscription to a new plan version allows you to:

* Apply new pricing to existing customers
* Transition customers to improved plan structures
* Deprecate old plan versions
* Standardize customers on current offerings

Migrations follow the same timing rules as other subscription changes:

* **Immediate**: Migration takes effect right away
* **Next billing cycle**: Migration occurs at the end of the current period

Choose timing based on whether the migration is favorable (immediate) or potentially disruptive (next cycle) to the customer.

