---
title: "Collect payments with a custom invoicing integration"
content_type: reference
description: "Learn how to integrate external invoicing and payment providers with {{site.metering_and_billing}} using the Custom Invoicing app."
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
  - text: "Billing, invoicing, and subscriptions"
    url: /metering-and-billing/billing-invoicing-subscriptions/
  - text: Integrate Stripe with {{site.metering_and_billing}}
    url: /metering-and-billing/stripe-integration/
---

You can integrate any external invoicing or payment provider with {{site.konnect_short_name}} {{site.metering_and_billing}} using the Custom Invoicing app to:

* Deliver invoices to customers via your existing invoicing provider
* Perform custom validation before invoices are issued or sent to customers
* Map invoice line items to your external system's data model

{% mermaid %}
flowchart TB
    IN["Invoice notifications"]
    CIA["Custom Invoicing app"]
    IC["Invoice changes"]
    IU["Invoice updates"]
    INT["Integration"]
    INV["3rd party invoicing solution"]
    PGW["3rd party payment gateway"]

    IN -->|Invoice changes| IC
    CIA -->|Invoice updates| IU
    IC --> INT
    IU --> INT
    INT <--> INV
    INT <--> PGW
{% endmermaid %}

## Revenue lifecycle

The following lists show which parts of the revenue lifecycle are managed by {{site.konnect_short_name}} {{site.metering_and_billing}} and which are delegated to your external provider:

Managed by {{site.metering_and_billing}}:
* Usage metering 
* Products and prices
* Subscription management 
* Billing and subscriptions
* Rating and invoice generation

Managed by your external provider:
* Sending invoices to customers
* Storing payment details
* Payment collection

## How to configure custom invoicing with {{site.metering_and_billing}}

Configuring {{site.metering_and_billing}} with a custom invoicing provider involves the following steps:

1. Create a notification channel.
1. Install the Custom Invoicing app in {{site.metering_and_billing}}.
1. Configure a billing profile or customer overrides.
1. Implement the integration using notifications as a data source and the Custom Invoicing API to advance invoice state.

## Implementation

The Custom Invoicing app pauses invoice processing at key states and waits for your integration to signal completion before the invoice progresses through its [lifecycle](/metering-and-billing/billing-invoicing-subscriptions/#invoice-lifecycle).

The app provides two optional synchronization hooks:

{% table %}
columns:
  - title: Hook
    key: hook
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - hook: "[Draft Sync Hook](#draft-sync-hook)"
    required: Optional
    description: Invoice processing pauses at the draft state. Your integration validates and confirms the draft before it proceeds.
  - hook: "[Issuing Sync Hook](#issuing-sync-hook)"
    required: Optional
    description: Invoice processing pauses before issuance. Your integration performs final validation before the invoice is sent to the customer.
{% endtable %}

Additionally, payment status synchronization is mandatory once an invoice enters the payment processing state, regardless of hook configurations.

For initial implementation and testing, start with both synchronization hooks disabled. Enable them later as your integration matures. See [Draft Sync Hook](#draft-sync-hook) and [Issuing Sync Hook](#issuing-sync-hook) for details.

After enabling the app, create a billing profile that references it. Use [customer overrides](/metering-and-billing/billing-invoicing-subscriptions/#customer-billing-profile-overrides) to limit the app's effect to specific customers rather than making it the default billing profile.

### Basic setup

When no sync hooks are enabled, the invoice flow works as follows:

1. {{site.metering_and_billing}} creates the invoice according to the [invoice lifecycle](/metering-and-billing/billing-invoicing-subscriptions/#invoice-lifecycle) rules.
1. The invoice reaches payment processing state. Your integration must:
   1. Send the invoice to the customer.
   1. Initiate and accept payment.
   1. Call the Custom Invoicing app's **Update Payment Status** API to set the payment state once payment is complete.

Your integration is responsible for managing the mapping between {{site.metering_and_billing}} invoice IDs and the corresponding entities in your external provider.

### Draft Sync Hook

When the Draft Sync Hook is enabled, invoice processing pauses at `draft.sync`. Your integration must call the **Submit Draft Synchronization Results** endpoint to validate the draft and allow the invoice to proceed.

During draft synchronization, your integration can:

* Update the invoice number to align with your external system's numbering scheme
* Synchronize the external system's invoice identifier back to {{site.metering_and_billing}}
* Associate external IDs with individual line items and discounts

This eliminates manual ID mapping between {{site.metering_and_billing}} and your external system. Your integration can also use this state to perform invoice validation and make adjustments through the Update Invoice endpoint before the invoice advances.

### Issuing Sync Hook

When the Issuing Sync Hook is enabled, invoice processing pauses at `issuing.sync`. Your integration must call the **Submit Issuing Sync Results** endpoint to validate the final invoice details before issuance.

During issuing synchronization, your integration can:

* Set the external payment identifier to link the invoice with your payment system
* Perform final validation of the invoice details before sending to the customer
* Ensure all external system requirements are met

## Install the Custom Invoicing app in {{site.metering_and_billing}}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Settings**.
1. Click **Apps**.
1. Find the **Custom Invoicing** app and click **Install**.
1. Click **Select Custom Invoicing**.
1. (Optional) Expand the **Advanced Hooks & Metadata** section and configure the synchronization hooks:
   * To pause processing at the draft state, enable **Draft Sync Hook**.
   * To pause processing before issuance, enable **Issuing Sync Hook**.
1. Click **Install App**.
1. Enable **Setup Invoice Notifications**.
1. In the **channels** dropdown menu, select your notification channels.
1. Click **Setup Notifications**.
1. Select a billing profile preset:
  * **Auto Collection** to charge the customer automatically.
  * **Send Invoice** to send an invoice and allow the customer to choose their payment method.
1. (Optional) Expand **Advanced Customize Billing Profile** to modify the default billing profile parameters.
1. Click **Create Billing Profile**
1. Do one of the following:
   * To set this as the default billing profile, click **Set as Default Profile**.
   * To limit the app to specific customers, disable **Set this as the new default billing profile**, click **Keep Current Default Profile**, and then configure [customer overrides](/metering-and-billing/billing-invoicing-subscriptions/#customer-billing-profile-overrides).

<!--
## Line mapping strategies

A critical part of the integration is mapping {{site.metering_and_billing}} invoice lines to your external billing system. This section outlines the available strategies.

### Aggregate totals

The simplest approach consolidates all charges into a single line item based on the invoice total.

{% table %}
columns:
  - title: Advantages
    key: advantages
  - title: Disadvantages
    key: disadvantages
rows:
  - advantages: |
      * Minimal implementation complexity
      * Reduced synchronization overhead
      * Works with simple payment processors
    disadvantages: |
      * Loss of itemization detail
      * Reduced transparency for customers
      * Limited ability to track individual usage components
{% endtable %}

Use this strategy only when your external system has limited line item support, when customers can access detailed usage information through other channels, or when implementation speed takes priority over reporting detail.

### Grouping

Usage-based invoice lines are hierarchical: a parent usage-based line groups detailed child lines. For external systems that don't support hierarchical structures, flatten the hierarchy by synchronizing only the child lines.

This approach preserves data integrity because the total of a usage-based parent line always equals the sum of its child lines and their associated discounts.

### Discounts

Amount discounts can be synchronized using three approaches:

{% table %}
columns:
  - title: Approach
    key: approach
  - title: Description
    key: description
  - title: When to use
    key: when
rows:
  - approach: Separate negative line item
    description: Create a dedicated line item with a negative value to represent the discount.
    when: Recommended when the external system supports negative line item values.
  - approach: Native discount integration
    description: Use the external system's built-in discount functionality.
    when: Optimal when the external system has robust native discount support.
  - approach: Line item value adjustment
    description: Merge the discount directly into the affected line item's value.
    when: "Last resort when the external system doesn't support negative values or native discounts. Note: this obscures original pricing detail and quantity information."
{% endtable %}
-->