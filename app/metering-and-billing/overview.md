---
title: "How can Metering & Billing help?"
content_type: reference
description: "Understand what {{site.konnect_short_name}} {{site.metering_and_billing}} does and where it fits in your revenue infrastructure."
layout: reference
products:
  - metering-and-billing
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: Metering
    url: /metering-and-billing/metering/
  - text: "Billing, invoicing, and subscriptions"
    url: /metering-and-billing/billing-invoicing-subscriptions/
---

{{site.konnect_short_name}} {{site.metering_and_billing}} is a real-time metering and billing engine that helps you track usage, enforce limits, manage subscriptions, and automate invoicing in one platform. Ingest events through a simple API, define meters with flexible aggregations, and connect usage data to billing, entitlements, and customer-facing dashboards. Launch new products and iterate on pricing without code changes.

## Features

<!--vale off-->
{% table %}
columns:
  - title: Feature
    key: feature
  - title: Description
    key: description
rows:
  - feature: "**Usage metering**"
    description: "Real-time usage metering from AI and compute to outcomes."
  - feature: "**Usage-based billing**"
    description: "Invoice after metered usage and automate your revenue collection."
  - feature: "**Usage quotas**"
    description: "Enforce usage quotas in real time per feature."
  - feature: "**Entitlements**"
    description: "Metered, boolean, and static entitlements."
  - feature: "**Product catalog**"
    description: "Define plans, add-ons, features, and rate cards."
  - feature: "**Subscriptions**"
    description: "Manage subscriptions with mid-cycle changes, prorating, and alignment."
  - feature: "**Prepaid credits**"
    description: "Support paid or promotional credit grants with priority-based burn-down and expiration."
  - feature: "**Notifications**"
    description: "Webhook-based alerts with configurable rules and channels for usage thresholds and billing events."
  - feature: "**Cost Analytics**"
    description: "First-class support for metering AI token usage and computing LLM model costs."
{% endtable %}
<!--vale on-->

## Billing pipeline

The following diagram shows how {{site.konnect_short_name}} {{site.metering_and_billing}} turns raw usage events into a finalized invoice. Events flow through metering and unit conversion, get rated against your product catalog's rate cards, and then credits and discounts are applied before an invoice is generated. From there, the invoice is handed off to downstream systems for tax calculation, delivery, and payment collection.

![Usage to invoice pipeline](/assets/images/konnect/usage-to-invoice-pipeline.svg)
{:.no-image-expand}

## Where {{site.metering_and_billing}} fits in the revenue infrastructure

Getting from a usage event to a charged credit card involves many steps. {{site.konnect_short_name}} {{site.metering_and_billing}} covers the core of that pipeline --- metering, rating, subscription management, and invoice generation --- while integrating with specialized vendors for tax, payments, and invoice delivery.

<!--vale off-->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: "{{site.metering_and_billing}}"
    key: openmeter
  - title: Solutions
    key: vendors
rows:
  - capability: "**Usage metering** (ingest, dedupe, real-time usage)"
    openmeter: "✓"
    vendors: ""
  - capability: "**Product catalog** (prices, plans, discounts)"
    openmeter: "✓"
    vendors: ""
  - capability: "**Subscription management** (start, cancel, billing periods)"
    openmeter: "✓"
    vendors: ""
  - capability: "**Entitlement management** (feature access and usage limits)"
    openmeter: "✓"
    vendors: ""
  - capability: "**Rating** (unit × price, discounts, etc.)"
    openmeter: "✓"
    vendors: ""
  - capability: "**Invoice generation** (billing periods, lines)"
    openmeter: "✓"
    vendors: ""
  - capability: "**Sales tax calculations** (based on geo and tax code)"
    openmeter: ""
    vendors: "Stripe Tax, Avalara, Anrok"
  - capability: "**Invoice delivery** (email, dunning, compliance)"
    openmeter: ""
    vendors: "Stripe Invoicing, NetSuite, Invopop"
  - capability: "**Credit card payment** (storing credit cards, payment rails)"
    openmeter: ""
    vendors: "Stripe Payments, Adyen, PayPal"
{% endtable %}
<!--vale on-->

### Tax, payments, and invoice delivery

{{site.konnect_short_name}} {{site.metering_and_billing}} does not handle sales tax, payment processing, or invoice delivery directly. Instead, it integrates with vendors that specialize in these areas so you can choose the best fit for your business.

Combining multiple vendors is common. A startup might pair {{site.metering_and_billing}} with Stripe Payments for credit card processing, while a telecommunications company might use Avalara for tax because their industry's tax law is more complex than what general-purpose tools support. You connect these vendors through [apps and integrations](/metering-and-billing/#integrations). Billing profiles in {{site.metering_and_billing}} let you use different vendors for different segments of your customers.
