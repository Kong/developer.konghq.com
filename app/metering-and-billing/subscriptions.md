---
title: "Subscriptions"
content_type: reference
description: "Learn how subscriptions work in {{site.konnect_short_name}} {{site.metering_and_billing}} and how to change, edit, cancel, and migrate them."
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
  - text: "Billing and invoicing"
    url: /metering-and-billing/billing-invoicing/
  - text: Product Catalog
    url: /metering-and-billing/product-catalog/
  - text: Entitlements
    url: /metering-and-billing/entitlements/
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
---

Subscriptions in {{site.metering_and_billing}} create relationships between [customers](/metering-and-billing/customer/) and their [pricing model](/metering-and-billing/pricing-models/).. They are the bridge between your customers, their usage data, and how that usage translates into billable amounts.

Subscriptions automate the billing lifecycle by:

* **Tracking usage** through meters
* **Applying pricing logic** from plans or custom configurations
* **Generating invoices** based on billing cadences
* **Enforcing entitlements** to control feature access

Subscriptions can be created from predefined plans or fully customized at creation time to accommodate unique customer requirements. This flexibility supports everything from self-serve sign-ups to enterprise contract negotiations.

Subscriptions follow a billing cycle determined by their related [rate card](/metering-and-billing/product-catalog/#rate-cards), anchored to one of the following:

* The subscription start date, either the creation date or a specified future date.
* The first day of the month, with usage prorated for the partial initial period.

To add a subscription to a customer, navigate to **{{site.metering_and_billing}}** > **Billing**, click your customer, and then click the **Subscriptions** tab in the {{site.konnect_short_name}} UI.

Active customer subscriptions can be enhanced with [add-ons](/metering-and-billing/add-ons/), which allow you to make changes to a customer's entitlements without changing the plan directly.

## Change plans

Changing a plan switches a customer to a completely different plan. This is equivalent to canceling the current subscription and starting a new one on the new plan, but without any interruption in service.

To change a customer's plan:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the customer whose subscription you want to change.
1. Click the **Subscription** tab.
1. Click **Manage**.
1. Select the new plan.
1. Click **Next**.
1. Select when the plan change should be effective **At the end of the billing period** or **Immediately**.
   * **At the end of the billing period**: Select for downgrades to avoid disrupting the customer's current service period. 
   * **Immediately**: Select for upgrades so the customer gets access to the new plan right away.
  
1. Click **Save Changes**.



## Cancel a subscription

Canceling a subscription ends it and stops future invoices from being generated. You can cancel immediately or at the end of the current billing period.

To cancel a subscription:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the customer whose subscription you want to cancel.
1. Click the **Subscriptions** tab.
1. Click **Cancel Subscription**.
1. Select when the plan change should be effective **At the end of the billing period** or **Immediately**.
   * **At the end of the billing period**: Select for downgrades to avoid disrupting the customer's current service period. 
   * **Immediately**: Select for upgrades so the customer gets access to the new plan right away.
1. Click **Save Changes**.

## Plan migration

Plans in {{site.metering_and_billing}} are versioned. When you publish a new version of a plan, existing subscriptions remain on the previous version until explicitly migrated. This is known as grandfathering, customers keep their existing pricing until you choose to migrate them.

Migrating a subscription to a new plan version allows you to:

* Apply new pricing to existing customers
* Transition customers to improved plan structures
* Deprecate old plan versions
* Standardize customers on current offerings

You can migrate customers selectively, migrating enterprise customers first and rolling out changes to self-serve customers later, for example.

To migrate a subscription to a new plan version:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the customer whose subscription you want to migrate.
1. Click the **Subscriptions** tab.
1. Click **Manage**.
1. Click **Migrate**.
1. Click **Next**.
1. Choose when the migration should be effective: **At the end of the billing period** or **Immediately**.
1. Click **Save**.
