---
title: "Add-ons"
content_type: reference
description: "Plan add-ons let you sell extra features, overage packs, or services without changing the core plan."
layout: reference
products:
  - metering-and-billing
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
  - /metering-and-billing/product-catalog/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: "Rate cards"
    url: /metering-and-billing/product-catalog/#rate-cards
---

Add-ons let you sell extra features, overage packs, or services without changing the core plan.
Use them to:
* Enable features not included in the base plan.
* Extend usage limits for existing features.
* Cross-sell or bundle products by adding new rate cards and prices.

## How add-ons work

An add-on is made up of one or more rate cards, each defining a specific feature, its pricing, billing cadence, and entitlements.

This modular structure lets you mix and match features and capacities independently of your base plans.

Add-ons can be:
* Single-instance: Only one instance of this add-on allowed per subscription.
* Multi-instance: Multiple instances of this add-on allowed per subscription.

## Managing add-ons for plans

Add-ons can be configured for compatible plans.
Compatibility is managed through the plan versioning cycle:

* **Draft Version**: You can freely add or remove add-ons to a plan before publishing.
* **Published Version**: Once a plan is published, the set of add-ons is locked and available to new subscriptions.

When assigning an add-on to a plan, you choose how many instances are allowed per subscription and at which phase of the plan the add-on is available.

{{site.metering_and_billing}} has a few limitations on add-on and plan compatibility:

* The billing cadences of the add-on must match the plan's billing cadence.
* Any rate cards present in both the add-on and the plan must meet extendability rules.

{:.warning}
> Once a plan version is published, the add-ons attributed to that plan **cannot** be changed.
If you need to add add-ons to a published plan, create a new version of that plan.

### Apply an add-on to a plan

To create a new add-on, go to **Metering & Billing** > **Product Catalog** > **Add-ons** tab.

To apply an existing add-on to a plan, use the go to **Metering & Billing** > **Product Catalog** > **Plans** tab, and choose a plan that's in draft status.

## Purchasing add-ons

You can purchase add-ons for an active subscription as long as they're compatible with the subscription's underlying plan. 
Add-ons can't be purchased for custom subscriptions.

When an add-on is purchased, its contents are merged into the subscription's existing items:
* If the add-on's rate card isn't already in the subscription, it's added as a new item.
* If the rate card already exists in the subscription, the existing item is extended with the add-on's rate card contents.

The resulting items keep the subscription's alignment and billing cadence.

{:.warning}
> Once a subscription has add-ons, you can no longer edit the subscription directly. 
At that point, you can only add or remove add-ons.
If you need to change the subscription, cancel the subscription and create a new one.

### Apply an add-on to a subscription

If a customer is a on a plan with add-ons available, you can apply add-ons to that customer's subscription.

To apply an add-on to an active subscription, go to **Metering and Billing** > **Billing** > **Customers** > select a customer > **Subscriptions** tab > **Apply Add-on**.

## Extendability

When an add-on extends an existing subscription, properties are merged as follows:

* Static prices are summed.
* Boolean entitlements are merged into a single boolean entitlement.
* Metered entitlements are merged by summing their allowance for the billing period if all other properties match.
* Usage discounts are concatenated as a list.

Any combination not listed above is either non-effectual or will cause a validation error during compatibility checks.
In general, we recommend splitting an add-on's contents across multiple rate cards.

