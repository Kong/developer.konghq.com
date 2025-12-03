---
title: "Product Catalog"
content_type: reference
description: "Learn how the Product Catalog work in {{site.konnect_short_name}} Metering and Billing and how they relate to usage tracking and external billing systems."
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
  - text: "Subjects"
    url: /metering-and-billing/subjects/

---


## Overview

{{site.konnect_short_name}} Metering and Billing's Product Catalog lets you centrally define the Products, Plans, and add-ons that make up your offering—so you can manage pricing, entitlements, and packaging in one place.

{% mermaid %}
flowchart TD

    Plan --> RateCards
    RateCards --> Price
    RateCards --> Entitlement

    Price --> Feature
    Entitlement -->Feature

    Feature --> Meter
{% endmermaid %}
## Features

Features are part of your product offering and the building blocks of your plans and entitlements. They are the resource you want to govern and invoice for. For example, LLM Models, tokens, storage units.

## Plans

Plans are a core component of the Product Catalog. Plans define the pricing and entitlements your customers receive in {{site.konnect_short_name}} Metering and Billing through Rate Cards. They act as reusable templates that describe what a customer gets and how they are charged. Each plan can include multiple phases, prices, and entitlements, and can be versioned. 

Plans can take different forms, for example: 

* $99 per month for 1 Million API requests
* 10 GB storage included
* SAML or SSO support


To support this, plans consist of Rate Cards, Add-ons, and Subscriptions. 

## Rate Cards

Rate Cards define the configuration of features that subscribers will be entitled to and charged for.

### Pricing Models
Rate cards offer several different pricing models, which you can see in the table below.

{% table %}
columns:
  - title: Pricing model
    key: model
  - title: Description
    key: description
rows:
  - model: "Free"
    description: "Free pricing"
  - model: "Flat fee"
    description: "A one-time or recurring fee"
  - model: "Usage based"
    description: "Linear pricing based on metered usage"
  - model: "Tiered"
    description: "Tiered pricing based on metered usage"
  - model: "Package"
    description: "Pricing based on fixed-sized usage packages"
  - model: "Dynamic"
    description: "USD prices created dynamically from meter values"
{% endtable %}

Besides the **Free** pricing model, other models require configuration that you can see from the {{site.konnect_short_name}} UI. 

### Entitlements

Entitlements are used to control access to different features, they make it possible to implement complex pricing scenarios such as monthly quotas, prepaid billing, and per-customer pricing. 


{% include_cached /konnect/metering-and-billing/discounts.md %}


## Subscriptions

{{site.konnect_short_name}} Metering and Billing subscriptions are the link between your [Customers](/metering-and-billing/customers), Plans, and [Meters](/).
