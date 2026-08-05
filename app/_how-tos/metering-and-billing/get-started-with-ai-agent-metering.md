---
title: Get started with {{site.metering_and_billing}} generic meters
permalink: /how-to/get-started-with-metering-and-billing-generic-meters/
description: Learn how to meter and bill AI agent runs using generic metering in {{site.konnect_short_name}} {{site.metering_and_billing}}.
content_type: how_to

breadcrumbs:
  - /metering-and-billing/

products:
    - metering-and-billing

works_on:
    - konnect

tags:
    - get-started
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
  q: How can I meter and bill AI agent runs in {{site.konnect_short_name}}?
  a: |
    To meter AI agent runs in {{site.konnect_short_name}}, create a generic meter with the **Count agent runs** template and `COUNT` aggregation to count agent run events per billing period. Then define a feature and plan to invoice customers based on their usage. Create a customer that includes usage from a subject and assign the customer to your plan. Finally, send events with the subject associated with the customer to generate an invoice.

related_resources:
  - text: Product Catalog reference
    url: /metering-and-billing/product-catalog/
  - text: Metering reference
    url: /metering-and-billing/metering/
  - text: Customers and usage attribution
    url: /metering-and-billing/customer/
  - text: Billing and invoicing
    url: /metering-and-billing/billing-invoicing/
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
This guide shows you how to use generic metering in {{site.metering_and_billing}} by demonstrating how to track and invoice customers based on the number of AI agent runs per month.

Pay-per-run billing is a common pricing model for AI products where customers are charged for each time an agent executes.
By using the `COUNT` aggregation grouped by `agent_name`, you can track total runs and break down usage by agent type.

In this guide, you'll:

* Create a generic meter that counts agent runs
* Create a feature to make that usage billable
* Create a usage-based plan
* Start a subscription for a customer
* Send usage events and validate the invoice

## Create a meter

In {{site.metering_and_billing}}, [meters](/metering-and-billing/metering/) track and record the consumption of a resource or service over time.
For billing per agent run, you'll use the built-in **Count agent runs** template, which pre-configures a `COUNT` meter that increments once per `agent_run` event and groups results by `agent_name`.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/meters
method: POST
status_code: 201
body:
  name: Count Agent Runs
  key: agent_runs_total
  event_type: agent_run
  aggregation: COUNT
  dimensions:
    agent_name: $.data.agent_name
{% endkonnect_api_request %}
<!--vale on-->

This creates a meter with the following configuration:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: Key
    value: "`agent_runs_total`"
  - field: Event type filter
    value: "`agent_run`"
  - field: Aggregation
    value: "`COUNT`"
  - field: Labels to group by
    value: "`agent_name`"
{% endtable %}
<!--vale on-->

## Create a feature

Meters collect raw usage data, but [features](/metering-and-billing/product-catalog/#features) make that data billable. 
Without a feature, usage is tracked but not invoiced. 
Now that you're metering agent runs, you need to associate that meter with a feature.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/features
method: POST
status_code: 201
body:
  name: Agent Runs
  key: agent_runs
  meter:
    key: agent_runs_total
capture:
  - variable: FEATURE_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a plan and rate card

Plans are the core building blocks of your [product catalog](/metering-and-billing/product-catalog/). 
They are a collection of rate cards that define the price and access of a feature. 
Plans can be assigned to customers by starting a subscription.

A [rate card](/metering-and-billing/product-catalog/#rate-cards) describes the price and usage limits or access control for a feature. 
Rate cards are made up of the associated feature, price, and optional entitlements.

In this section, you'll create a Premium Plan that charges customers $1 per agent run per month.

First, create the plan with a rate card:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans
method: POST
status_code: 201
body:
  name: Premium Plan
  key: premium_plan
  currency: USD
  billing_cadence: P1M
  phases:
    - name: default
      key: default
      rate_cards:
        - name: Agent Runs
          key: agent_runs
          feature:
            id: $FEATURE_ID
          price:
            type: unit
            amount: "1"
          entitlement:
            type: boolean
capture:
  - variable: PLAN_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> **Note:** We're using $1 here to make it easy to see invoice amount changes in the customer invoice.
> Change this price in a production instance to match your own pricing model.

Then publish the plan to make it available for subscriptions:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/plans/$PLAN_ID/publish
method: POST
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

## Start a subscription

[Customers](/metering-and-billing/customer/) are the entities that pay for consumption. Here you'll create a customer and [subscribe](/metering-and-billing/subscriptions/) them to the Premium Plan plan.

First, create the customer.
The `key` field links incoming usage events to this customer: events with `"subject": "acme-inc"` will be attributed to Acme Inc.

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers
method: POST
status_code: 201
body:
  name: Acme Inc
  key: acme-inc
  usage_attribution:
    subject_keys:
      - acme-inc
capture:
  - variable: CUSTOMER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Then start a subscription to the Premium Plan:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/subscriptions
method: POST
status_code: 201
body:
  customer:
    id: $CUSTOMER_ID
  plan:
    key: premium_plan
{% endkonnect_api_request %}
<!--vale on-->

## Validate

Send usage events to {{site.metering_and_billing}} using the [CloudEvents](https://cloudevents.io/) format.
Each event represents one agent run. The meter counts every event, so three events equal three runs.

{:.warning}
> **Important:** When you send events, they must have a unique `id`. {{site.metering_and_billing}} deduplicates events with the same `id`.

1. Export the current time:
   ```sh
   export EVENT_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
   ```
   {{site.metering_and_billing}} only invoices and meters events that are sent _after_ the subscription is created.
1. Send a run event for the `summarizer` agent:
{% capture "run1" %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/events
status_code: 200
method: POST
headers:
  - 'Content-Type: application/cloudevents+json'
body:
  specversion: "1.0"
  type: agent_run
  id: 8655CDD7-0775-4AEA-AF8C-89C47EBC8828
  source: acme-platform
  time: $EVENT_TIME
  datacontenttype: application/json
  subject: acme-inc
  data:
    agent_name: summarizer
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ run1 | indent: 3 }}

1. Send a second run event for the `summarizer` agent:
{% capture "run2" %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/events
status_code: 200
method: POST
headers:
  - 'Content-Type: application/cloudevents+json'
body:
  specversion: "1.0"
  type: agent_run
  id: 3EC7EFD0-5B78-47A4-AE9E-15965675CF95
  source: acme-platform
  time: $EVENT_TIME
  datacontenttype: application/json
  subject: acme-inc
  data:
    agent_name: summarizer
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ run2 | indent: 3 }}

1. Send a run event for the `translator` agent:
{% capture "run3" %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/events
status_code: 200
method: POST
headers:
  - 'Content-Type: application/cloudevents+json'
body:
  specversion: "1.0"
  type: agent_run
  id: 48FC220C-C124-4B73-B378-7DC5CF88DD1A
  source: acme-platform
  time: $EVENT_TIME
  datacontenttype: application/json
  subject: acme-inc
  data:
    agent_name: translator
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ run3 | indent: 3 }}

Now check the usage charges:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID/charges?expand[]=real_time_usage
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

The response includes a usage-based charge for `agent-runs` with a `real_time_usage` quantity of `3`, reflecting three agent runs (two for `summarizer` and one for `translator`).

To preview the full formatted invoice, go to **{{site.metering_and_billing}}** > **Billing** > **Acme Inc** > **Invoicing** > **Preview Invoice** in the {{site.konnect_short_name}} UI.

In this guide, you're using the sandbox for invoices.
To deploy your subscription in production, configure a payments integration in **{{site.metering_and_billing}}** > **Settings**, like [Stripe](/metering-and-billing/stripe-integration/).
