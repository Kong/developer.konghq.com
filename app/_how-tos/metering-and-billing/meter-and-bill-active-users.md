---
title: Meter and bill active users with {{site.metering_and_billing}} generic meters
permalink: /how-to/meter-and-bill-active-users/
description: Learn how to meter and bill active users using generic metering in {{site.konnect_short_name}} {{site.metering_and_billing}}.
content_type: how_to

breadcrumbs:
  - /metering-and-billing/

products:
    - metering-and-billing

works_on:
    - konnect

tags:
    - metering
    - billing

prereqs:
  skip_product: true
  inline:
    - title: "{{site.konnect_short_name}} roles"
      content: |
        You need the [{{site.metering_and_billing}} Admin role](/konnect-platform/teams-and-roles/#metering-billing) in {{site.konnect_short_name}} to configure {{site.metering_and_billing}}.
      icon_url: /assets/icons/kogo-white.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

tldr:
  q: How can I meter and bill active users in {{site.konnect_short_name}}?
  a: |
    To meter active users in {{site.konnect_short_name}}, create a generic meter with `UNIQUE_COUNT` aggregation to track unique users per billing period. Then define a feature and plan to invoice customers based on their seat count. Create a customer that includes usage from subject and assign the customer to your plan. Finally, send an event that includes the subject that is associated with the customer to generate an invoice.

related_resources:
  - text: Product Catalog reference
    url: /metering-and-billing/product-catalog/
  - text: Metering reference
    url: /metering-and-billing/metering/
  - text: Customers and usage attribution
    url: /metering-and-billing/customer/
  - text: Billing, invoicing, and subscriptions
    url: /metering-and-billing/billing-invoicing-subscriptions/
  - text: Meter and bill {{site.base_gateway}} API requests
    url: /metering-and-billing/get-started/
  - text: Meter and bill {{site.ai_gateway}} LLM tokens
    url: /how-to/meter-llm-traffic/
faqs:
  - q: Why don't I see any events in my customer's invoice?
    a: |
      {% include faqs/no-events-in-invoice.md %}
automated_tests: false
---

Generic metering is a flexible way to meter events from a variety of sources. 
This guide shows you how to use generic metering in {{site.metering_and_billing}} by demonstrating how to track and invoice customers based on the number of unique active users (seats) per month. 

Per-seat billing is a common pricing model for SaaS products where customers are charged based on how many distinct users access the platform in a billing period. 
By using the `UNIQUE_COUNT` aggregation, you can count unique users accurately even if the same user triggers multiple events.

In this guide, you'll:

* Create a generic meter that counts unique active users
* Create a feature to make that usage billable
* Create a per-seat plan with usage-based pricing
* Start a subscription for a customer
* Send usage events and validate the invoice

## Create a meter

In {{site.metering_and_billing}}, [meters](/metering-and-billing/metering/) track and record the consumption of a resource or service over time. 
For per-seat billing, you'll create a generic meter using the `UNIQUE_COUNT` aggregation. 
This counts the number of distinct `user_id` values seen within the billing period, so if the same user is active multiple times, they're only counted once.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. Click **New meter**.
1. In the **Name** field, enter `Active users total`.
1. In the **Description** field, enter `Active Users`.
1. In the **Event Type Filter** field, enter `user_activity`.
1. From the **Aggregation** dropdown menu, select "UNIQUE COUNT".
1. In the **Value property** field, enter `$.user_id`.
1. Click **Save**.

## Create a feature

Meters collect raw usage data, but [features](/metering-and-billing/product-catalog/#features) make that data billable. 
Without a feature, usage is tracked but not invoiced. 
Now that you're metering active users, you need to associate that meter with a named, customer-facing feature.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Product Catalog**.
1. Click **Create Feature**.
1. In the **Name** field, enter `active-users`.
1. From the **Meter** dropdown menu, select "Active users total".
1. Click **Save**.

## Create a plan and rate card

Plans are the core building blocks of your [product catalog](/metering-and-billing/product-catalog/). 
They are a collection of rate cards that define the price and access of a feature. 
Plans can be assigned to customers by starting a subscription.

A [rate card](/metering-and-billing/product-catalog/#rate-cards) describes the price and usage limits or access control for a feature. 
Rate cards are made up of the associated feature, price, and optional entitlements.

In this section, you'll create a Per-Seat plan that charges customers $1 per active user per month:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Product Catalog**.
1. Click the **Plans** tab.
1. Click **Create Plan**.
1. In the **Name** field, enter `Per-Seat`.
1. From the **Billing cadence** dropdown menu, select **1 month**.
1. Click **Save**.
1. Click **Add Rate Card**.
1. From the **Feature** dropdown menu, select "active-users".
1. Click **Next Step**.
1. From the **Pricing model** dropdown menu, select **Usage based**.
1. In the **Price per unit** field, enter `1`.

   {:.info}
   > We're using $1 here to make it easy to see invoice amount changes in the customer invoice. 
   > Change this price in a production instance to match your own pricing model.
1. Click **Next Step**.
1. Select **Boolean**.
1. Click **Save Rate Card**.
1. Click **Publish Plan**.
1. Click **Publish**.

## Start a subscription

[Customers](/metering-and-billing/customer/) are the entities that pay for consumption. Here you'll create a customer and [subscribe](/metering-and-billing/billing-invoicing-subscriptions/#subscriptions) them to the Per-Seat plan.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter `Acme Inc`.
1. In the **Key** field, enter `acme-inc`.

   This value links incoming usage events to this customer. 
   Events with `"subject": "acme-inc"` will be attributed to Acme Inc.
1. Click **Save**.
1. Click the **Subscription** tab.
1. Click **Create a Subscription**.
1. From the **Subscribed Plan** dropdown, select `Per-Seat`.
1. Click **Next Step**.
1. Click **Start Subscription**.

## Validate

Send usage events to {{site.metering_and_billing}} using the [CloudEvents](https://cloudevents.io/) format. 
Each event represents a user interaction in your application. 
The meter counts each unique `user_id` value once per billing period. 
To validate, we'll send events for three distinct users: `alice`, `bob`, and `carol`.

{:.warning}
> **Important:** When you send events, they must have a unique `id`. {{site.metering_and_billing}} deduplicates events with the same `id`.

1. Export the current time:
   ```sh
   export EVENT_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
   ```
   {{site.metering_and_billing}} only invoices and meters events that are sent _after_ the subscription is created.
1. Send an event for `alice`:
{% capture "alice1" %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/events
status_code: 200
method: POST
headers:
  - 'Content-Type: application/cloudevents+json'
body:
  specversion: "1.0"
  type: user_activity
  id: 57B5F342-B8D5-49AE-9D6C-350C1D92155C
  source: acme-platform
  time: $EVENT_TIME
  datacontenttype: application/json
  subject: acme-inc
  data:
    user_id: alice
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ alice1 | indent: 3 }}

1. Send an event for `bob`:
{% capture "bob" %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/events
status_code: 200
method: POST
headers:
  - 'Content-Type: application/cloudevents+json'
body:
  specversion: "1.0"
  type: user_activity
  id: F388B902-7A82-4C40-BC89-448CFA5DDC1B
  source: acme-platform
  time: $EVENT_TIME
  datacontenttype: application/json
  subject: acme-inc
  data:
    user_id: bob
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ bob | indent: 3 }}

1. Send an event for `carol`:
{% capture "carol" %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/events
status_code: 200
method: POST
headers:
  - 'Content-Type: application/cloudevents+json'
body:
  specversion: "1.0"
  type: user_activity
  id: 46C16EE0-6174-4336-A539-AEC3AD1E0485
  source: acme-platform
  time: $EVENT_TIME
  datacontenttype: application/json
  subject: acme-inc
  data:
    user_id: carol
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ carol | indent: 3 }}

1. Now, send a second event for `alice` to confirm that `UNIQUE_COUNT` doesn't duplicate repeated users:
{% capture "alice2" %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/events
status_code: 200
method: POST
headers:
  - 'Content-Type: application/cloudevents+json'
body:
  specversion: "1.0"
  type: user_activity
  id: 2843D4B1-C8F8-408E-9F28-6D4EB44E5A8B
  source: acme-platform
  time: $EVENT_TIME
  datacontenttype: application/json
  subject: acme-inc
  data:
    user_id: alice
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ alice2 | indent: 3 }}

Even though four events were sent, the meter counted only three unique users. Now check the invoice:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Acme Inc**.
1. Click the **Invoicing** tab.
1. Click **Preview Invoice**.

You'll see `active-users` listed in Lines with a quantity of `3`, reflecting three unique active users. 

In this guide, you're using the sandbox for invoices. 
To deploy your subscription in production, configure a payments integration in **{{site.metering_and_billing}}** > **Settings**, like [Stripe](/metering-and-billing/stripe-integration/).
