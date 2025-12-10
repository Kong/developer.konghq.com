---
title: "Billing and Subscriptions"
content_type: reference
description: "Learn how billing and subscriptions work in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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
  - text: "{{site.konnect_short_name}} Metering and Billing"
    url: /metering-and-billing/

---


## Overview

Billing and subscriptions in {{site.metering_and_billing}} create relationships between customers and their pricing model. This serves as the bridge between your customers, their usage data, and how that usage translates into billable amounts.

<!--vale off-->
{% mermaid %}
flowchart TD

  customer[Customer]

  customer --> entitlements
  customer --> subscriptions
  customer --> invoices

  entitlements --> feature1
  entitlements --> feature2
  entitlements -.-> feature3

  feature1[Feature 1]
  feature2[Feature 2]
  feature3[Feature 3]
  
  subscriptions[Subscriptions]
  invoices[Invoices]
  entitlements[Entitlements]

{% endmermaid %}
<!--vale on-->


## How subscriptions work

Subscriptions automate the billing lifecycle by:

* **Tracking usage** through meters
* **Applying pricing logic** from plans or custom configurations
* **Generating invoices** based on billing cadences
* **Enforcing entitlements** to control feature access

Subscriptions can be created from predefined plans or fully customized at creation time to accommodate unique customer requirements. This flexibility supports everything from self-serve sign-ups to enterprise contract negotiations.

## Subscription structure

Plans and subscriptions share a similar structure, but where plans use templates, subscriptions contain concrete, instantiated values with actual timestamps and configurations.

## Billing

Billing in {{site.konnect_short_name}} allows you to manage Customers, Entitlements, and Invoices.

### Customers

Customer records form the foundation of your billing relationships. Each customer requires specific information to enable accurate billing and usage tracking.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: Name (required)
    description: The customer's display name for identification purposes
  - field: Key (optional)
    description: A unique identifier for this customer, useful when integrating with external systems
{% endtable %}


Usage attribution defines how events are linked to customers. {{site.metering_and_billing}} supports multiple attribution methods:

{% table %}
columns:
  - title: Attribution method
    key: method
  - title: Description
    key: description
rows:
  - method: Consumers
    description: Used by API and AI gateways to track usage
  - method: Applications
    description: Used by developer portals to attribute usage to specific applications
  - method: Subjects
    description: Used for generic metering scenarios where events are tagged with custom identifiers
{% endtable %}

You can select one or more attribution methods. Events are automatically attributed to the customer when the event's subject property matches one of the selected values. Multiple attribution methods can be enabled simultaneously to support diverse usage tracking scenarios within a single customer account.

Once created, customers can be:

* Assigned to subscription plans
* Monitored for usage patterns
* Invoiced based on their subscription configuration
* Updated with new billing information as needed

## Plan migration

Plans in {{site.metering_and_billing}} are versioned. When you update a plan, existing subscriptions remain on their current version this is known as "grandfathering." Customers keep their existing pricing until they're explicitly migrated.

Migrating a subscription to a new plan version allows you to:

* Apply new pricing to existing customers
* Transition customers to improved plan structures
* Deprecate old plan versions
* Standardize customers on current offerings

## Migration Timing

Migrations follow the same timing rules as other subscription changes:

* **Immediate**: Migration takes effect right away
* **Next billing cycle**: Migration occurs at the end of the current period

Choose timing based on whether the migration is favorable (immediate) or potentially disruptive (next cycle) to the customer.

