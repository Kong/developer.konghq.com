---
title: "Customers and usage attributes"
content_type: reference
description: "Learn how Customers and usage attributes work in {{site.konnect_short_name}} Metering and Billing and how they access features."
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

## What is a customer?

Customers represent individuals or organizations that subscribe to plans and gain access to features. 

Billable events ingested into OpenMeter always include a usage attribute.  
Usage attributes represent usage-producing entities within your system, such as {{site.base_gateway}} [Consumers](/gateway/entities/consumer/), [Dev Portal applications](/dev-portal/self-service/), or [subjects](#what-is-a-subject) (for usage outside of {{site.konnect_short_name}}).

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
      Attribute AI token usage to customers.
    recommendation: "[Consumers](/gateway/entities/consumer/)"
  - use-case: |
      Attribute API request usage to customers. 
    recommendation: "[Consumers](/gateway/entities/consumer/)"
  - use-case: |
      Attribute Dev Portal application usage to customers.
    recommendation: "[Applications](/dev-portal/self-service/)"
  - use-case: |
      Attribute usage from sources outside of {{site.base_gateway}} and {{site.konnect_short_name}} to customers.
    recommendation: "[Subjects](#what-is-a-subject)"
{% endtable %}

### What is a subject?

Subjects represent the entity that consumes metered resources in {{site.konnect_short_name}} Metering and Billing. Billable events ingested to Metering and Billing have a subject associated with them.

A subject can represent any unique event in your system, such as: 
* Customer ID or User ID  
* Hostname or IP address  
* Service or application name  
* Device ID  

The subject model is intentionally generic, enabling flexible application across different metering scenarios.

Each subject contains the following fields:

* **Key** – The subject’s unique identifier  
* **Display name** – A human-readable label shown in the UI  
* **Metadata** – Optional key-value attributes for additional context  

{:.info}
> We recommend creating a subject when a new customer or user is created in your system and deleting a subject when a customer or user is deleted. Keeping the subjects in sync in Metering and Billing is necessary if you synchronize usage to external systems, such as Stripe billing or CRMs, as {{site.konnect_short_name}} knows the mapping between the subject and the external system.
> {{site.konnect_short_name}} Metering and Billing will also automatically create a subject for you when you ingest an usage event for a new subject.


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

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter your customer's name.
1. Select **Consumers**.
1. In the **Include usage from** dropdown, search for your Consumer. 
1. Click **Save**.

{% endnavtab %}
{% navtab "Application" %}

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter your customer's name.
1. Select **Applications**.
1. In the **Include usage from** dropdown, search for the Dev Portal application. 
1. Click **Save**.

{% endnavtab %}
{% navtab "Subject" %}

{:.warning}
> **Important:** During the billing beta, customers are limited to **one subject**. Support for multiple subjects will be available in the future.

Subjects are created when you create the customer. To create a customer associated with a subject, send a `POST` request to the `/api/v1/customers` endpoint:

```
curl https://openmeter.cloud/api/v1/customers \
  --request POST \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer $KONNECT_TOKEN' \
  --data '{
  "name": "",
  "description": "",
  "metadata": {
    "externalId": "019142cc-a016-796a-8113-1a942fecd26d"
  },
  "key": "",
  "usageAttribution": {
    "subjectKeys": [
      "$YOUR-SUBJECT"
    ]
  },
  "primaryEmail": "",
  "currency": "USD",
  "billingAddress": {
    "country": "US",
    "postalCode": "",
    "state": "",
    "city": "",
    "line1": "",
    "line2": "",
    "phoneNumber": ""
  }
}'
```

Replace `$KONNECT_TOKEN` with your [{{site.konnect_short_name}} personal or system access token](/konnect-api/#system-accounts-and-access-tokens).

{:.info}
> {{site.konnect_short_name}} Metering and Billing will also automatically create a subject for you when you ingest an usage event for a new subject.

{% endnavtab %}
{% endnavtabs %}


## Schema

[Insert Schema here](https://openmeter.io/docs/api/cloud#tag/customers)