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

Subscriptions in {{site.metering_and_billing}} create relationships between [customers](/metering-and-billing/customer/) and their pricing model. They are the bridge between your customers, their usage data, and how that usage translates into billable amounts.

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

## Change plans

Changing a plan switches a customer to a completely different plan. This is equivalent to canceling the current subscription and starting a new one on the new plan, but without any interruption in service.

To change a customer's plan:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the customer whose subscription you want to change.
1. Click the **Subscriptions** tab.
1. Click the subscription you want to change.
1. Click **Change Plan**.
1. Select the new plan.
1. Choose the timing: **Immediately** or **Next billing cycle**.
1. Click **Save**.

Choose **Next billing cycle** for downgrades to avoid disrupting the customer's current service period. Choose **Immediately** for upgrades so the customer gets access to the new plan right away.

## Customize a subscription

You can add or remove individual rate card items from an active subscription without changing the underlying plan. This is useful for adding one-off features or removing items that a customer no longer needs.

{:.info}
> You cannot modify rate card items that are already deactivated (past phases).

To add or remove a rate card item:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the customer whose subscription you want to edit.
1. Click the **Subscriptions** tab.
1. Click the subscription you want to edit.
1. Click **Edit Subscription**.
1. Add or remove rate card items as needed.
1. Choose the timing: **Immediately** or **Next billing cycle**.
1. Click **Save**.

## Modification timing

When modifying a subscription, the timing determines when the change takes effect:

<!--vale off-->
{% table %}
columns:
  - title: Timing
    key: timing
  - title: Best for
    key: best_for
  - title: Behavior
    key: behavior
rows:
  - timing: Immediate
    best_for: Upgrades
    behavior: The change takes effect right away. Only the modified rate cards are updated; the billing cycle continues unchanged.
  - timing: Next billing cycle
    best_for: Downgrades
    behavior: The change takes effect at the end of the current billing period, avoiding any need for refunds or proration.
{% endtable %}
<!--vale on-->

## Cancel a subscription

Canceling a subscription ends it and stops future invoices from being generated. You can cancel immediately or at the end of the current billing period.

To cancel a subscription:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the customer whose subscription you want to cancel.
1. Click the **Subscriptions** tab.
1. Click the subscription you want to cancel.
1. Click **Cancel Subscription**.
1. Choose the timing: **Immediately** or **Next billing cycle**.
1. Click **Confirm**.

## Plan migration

Plans in {{site.metering_and_billing}} are versioned. When you publish a new version of a plan, existing subscriptions remain on the previous version until explicitly migrated. This is known as grandfathering — customers keep their existing pricing until you choose to migrate them.

Migrating a subscription to a new plan version allows you to:

* Apply new pricing to existing customers
* Transition customers to improved plan structures
* Deprecate old plan versions
* Standardize customers on current offerings

You can migrate customers selectively — for example, migrating enterprise customers first and rolling out changes to self-serve customers later.

To migrate a subscription to a new plan version:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the customer whose subscription you want to migrate.
1. Click the **Subscriptions** tab.
1. Click the subscription you want to migrate.
1. Click **Migrate**.
1. Select the target plan version, or leave it empty to migrate to the latest published version.
1. Choose the timing: **Immediately** or **Next billing cycle**.
1. Click **Save**.
