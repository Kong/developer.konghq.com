---
title: "Customers and usage attribution"
content_type: reference
description: "Learn how Customers and usage attributes work in {{site.konnect_short_name}} {{site.metering_and_billing}} and how they access features."
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
  - text: Subscriptions
    url: /metering-and-billing/subscriptions/
  - text: Integrate Stripe with {{site.metering_and_billing}}
    url: /metering-and-billing/stripe-integration/
  - text: "Prepaid credits"
    url: /metering-and-billing/credits/
faqs:
  - q: Why don't I see any events in my customer's invoice?
    a: |
      {% include faqs/no-events-in-invoice.md %}
---

## What is a customer?

Customers represent individuals or organizations that subscribe to plans, gain access to features, and are invoiced for their consumption.

Billable events ingested into {{site.metering_and_billing}} always include a subject field that represents metered entities within your system, such as {{site.base_gateway}} [Consumers](/gateway/entities/consumer/), [Dev Portal applications](/dev-portal/self-service/), or [subjects](#what-is-a-subject) or entities outside of {{site.konnect_short_name}}.

A customer can have **one or many** usage attributes assigned, allowing you to group usage and billing. For example, if a customer has multiple departments that are producing usage, you could create two usage attributes for each department that are assigned to one customer.

{% mermaid %}
flowchart TB
    %% Left side
    Customer[Customer]
    Subject[Subject]
    UsageEventsLeft[Usage Events]

    Customer -->|1:n| Subject
    Subject -->|1:n| UsageEventsLeft

    %% Right side
    ACME[ACME Inc.]
    Dept1[Department 1]
    Dept2[Department 2]
    UsageEvents1[Usage Events]
    UsageEvents2[Usage Events]

    ACME --> Dept1
    ACME --> Dept2

    Dept1 --> UsageEvents1
    Dept2 --> UsageEvents2
{% endmermaid %}

Use the following table to help you determine the best way to map your customers to usage attributes:

{% table %}
columns:
  - title: You want to...
    key: use-case
  - title: Then use...
    key: recommendation
rows:
  - use-case: |
      Attribute {{site.ai_gateway}} token usage to customers.
    recommendation: "[Consumers](/gateway/entities/consumer/)"
  - use-case: |
      Attribute {{site.base_gateway}} API request usage to customers.
    recommendation: "[Consumers](/gateway/entities/consumer/)"
  - use-case: |
      Attribute {{site.konnect_short_name}} Dev Portal application requests to customers.
    recommendation: "[Applications](/dev-portal/self-service/)"
  - use-case: |
      Attribute usage from sources outside of {{site.base_gateway}} and {{site.konnect_short_name}} to customers.
    recommendation: "[Subjects](#what-is-a-subject)"
{% endtable %}

### What is a subject?

Subjects represent the entity that consumes metered resources in {{site.konnect_short_name}} {{site.metering_and_billing}}. Billable events ingested to {{site.metering_and_billing}} have a subject associated with them.

A subject can represent any unique event in your system, such as:
* Customer ID or User ID
* Hostname or IP address
* Service or application name
* Device ID

The subject model is intentionally generic, enabling flexible application across different metering scenarios.



#### Data ingestion

When shipping data to {{site.konnect_short_name}}, you must include the subject within the events payload:

```ts
{
  "specversion": "1.0",
  "type": "api-calls",
  "id": "00002",
  "time": "2023-01-01T00:00:00.001Z",
  "source": "service-0",
  "subject": "customer-1",
  "data": {...}
}
```

## Create a customer

To create a customer in {{site.konnect_short_name}}, do the following:

{% navtabs "customer" %}
{% navtab "Consumer" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter your customer's name.
1. Select **Consumers**.
1. In the **Include usage from** dropdown, search for your Consumer.
1. Click **Save**.

{% endnavtab %}
{% navtab "Application" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter your customer's name.
1. Select **Applications**.
1. In the **Include usage from** dropdown, search for the Dev Portal application.
1. Click **Save**.

{% endnavtab %}
{% navtab "Subject" %}

Subjects are created when you create the customer.
To create a customer associated with a subject:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers
method: POST
status_code: 201
body:
  name: ACME Inc.
  key: acme-inc
  usage_attribution:
    subject_keys:
      - YOUR-SUBJECT-KEY
{% endkonnect_api_request %}
<!--vale on-->

Replace `YOUR-SUBJECT-KEY` with the subject key from events that you want to attribute to this customer.

{:.info}
> **Note:** {{site.metering_and_billing}} also automatically creates a subject when you ingest a usage event for a new subject.

{% endnavtab %}
{% endnavtabs %}


## Schema

[Insert Schema here](https://openmeter.io/docs/api/cloud#tag/customers)