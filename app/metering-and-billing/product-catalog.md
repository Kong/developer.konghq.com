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

### Discounts and commitments

Rate Cards support two different types of discounts that can be applied to charges: 

* Percentage discount: Reduce price by a fixed percent across all usage
* Usage discount: Enable you to provide discounts on the metered value. 

For more information see [Discounts](/)

## Subscriptions

{{site.konnect_short_name}} Metering and Billing subscriptions are the link between your [Customers](/metering-and-billing/customers), Plans, and [Meters](/).
