---
title: "Product Catalog"
content_type: reference
description: "Learn how the Product Catalog work in {{site.konnect_short_name}} {{site.metering_and_billing}} and how they relate to usage tracking and external billing systems."
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
  - text: "Features"
    url: /metering-and-billing/features/
  - text: "Plans"
    url: /metering-and-billing/plans/

---


{{site.konnect_short_name}} {{site.metering_and_billing}}'s Product Catalog lets you centrally define the different plans and plan features that make up your offering—so you can manage pricing, entitlements, and packaging in one place. 

Each Product Catalog plan consists of:
* [Features](/metering-and-billing/features/) that you want to price or govern. Can be metered or static.
* [Rate cards](/metering-and-billing/plans/#rate-cards) that determine which features ([entitlements](/metering-and-billing/plans/#entitlements)) and how much of the feature a subscriber can access ([pricing models](/metering-and-billing/plans/#pricing-models))
* Optional [add-ons](/metering-and-billing/plans/#add-ons) that allow customers to purchase additional usage or features on demand

For example, say you're metering API Gateway requests for your API and you want to charge customers based on API usage, you might configure your plans like the following:

{% mermaid %}
flowchart TB
 subgraph free-plan["<b>Free Plan</b>"]
    direction TB
        subgraph feature-free["<b>Feature</b>"]
            direction TB
            meter-free["Meter<br/>(API requests)"]
        end
        rate-card-free["Rate Card<br/>(10 requests/month)"]
        entitlement-free["Entitlement (Metered)"]
  end
  
 subgraph premium-plan["<b>Premium Plan</b>"]
    direction TB
        subgraph feature-premium["<b>Feature</b>"]
            direction TB
            meter-premium["Meter<br/>(API requests)"]
        end
        rate-card-premium["Rate Card<br/>(1000 requests/month)"]
        entitlement-premium["Entitlement (Metered)"]
        addon["<b>Add-on</b><br> (1000 additional requests)"]
  end
  
    meter-free ~~~ rate-card-free
    rate-card-free ~~~ entitlement-free
    
    meter-premium ~~~ rate-card-premium
    rate-card-premium ~~~ entitlement-premium
    entitlement-premium ~~~ addon
{% endmermaid %}

{{site.metering_and_billing}}'s Product Catalog supports various packaging and pricing strategies:

{% table %}
columns:
  - title: Use case
    key: case
  - title: Description
    key: description
rows:
  - case: Self-service plans
    description: Let users pick from tiered plans on your pricing page.
  - case: Enterprise deals
    description: Customize pricing and discounts for specific customers.
  - case: Add-ons
    description: Cross-sell or bundle products, like extra storage, SSO, etc.
  - case: |
      [Usage-based pricing](/how-to/meter-and-bill-active-users/)
    description: Optimize revenue by billing for outcomes.
  - case: Versioned catalogs
    description: Maintain multiple catalog versions and migrate users as needed.
  - case: Trial bundles
    description: Offer limited-time free or discounted bundles to new users.
{% endtable %}

## Features

[Features](/metering-and-billing/features/) are part of your product offering and the building blocks of your plans and entitlements. They represent the resources you want to govern and invoice for, and typically translate to line items on your pricing page and invoice.

## Plans

[Plans](/metering-and-billing/plans/) define the pricing and entitlements your customers receive. They act as reusable templates that describe what a customer gets and how they are charged, built from [rate cards](/metering-and-billing/plans/#rate-cards), [entitlements](/metering-and-billing/plans/#entitlements), and [pricing models](/metering-and-billing/plans/#pricing-models).


## Subscriptions

{{site.konnect_short_name}} {{site.metering_and_billing}} [subscriptions](/metering-and-billing/billing-invoicing-subscriptions/#subscriptions) link your [Customers](/metering-and-billing/customer/) to plans, and [meters](/metering-and-billing/metering/).

