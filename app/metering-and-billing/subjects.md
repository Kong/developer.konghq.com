---
title: "Subjects"
content_type: reference
description: "Learn how subjects work in {{site.konnect_short_name}} Metering and Billing and how they relate to usage tracking and external billing systems."
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

## What is a subject?

Subjects represent the entity that consume metered resources in {{site.konnect_short_name}} Metering and Billing. Billable events ingested to Metering and Billing have a subject associated with them.

A subject can represent any unique event in your system, such as: 
* Customer ID or User ID  
* Hostname or IP address  
* Service or application name  
* Device ID  

The subject model is intentionally generic, enabling flexible application across different metering scenarios.
In most implementations, a subject maps 1:1 with a customer or user in your system. You can use the same identifier for both, but they can differ if your usage producer and billing entity are not the same. For example:
* One customer may have multiple usage-producing subjects  
* A single subject’s usage may need to be billed to a different customer  

You can also have multiple subjects assigned to a customer. This abstraction allows you to group usage data and billing for a customer. For example, a customer can have multiple subjects like `department1` or `department2`:

{% mermaid %}
flowchart TD

subgraph a ["Customer Kong Air"]
  subject1["Subject"]
end

subgraph Customer-ACME Inc
  subject2["Subject (Department 1)"]
  subject3["Subject (Department 2)"]
end

subject1 --> UsageEvents1["Usage Events"]
subject2 --> UsageEvents2["Usage Events"]
subject3 --> UsageEvents3["Usage Events"]
{% endmermaid %}

{:.info}
> We recommend creating a subject when a new customer or user is created in your system and deleting a subject when a customer or user is deleted. Keeping the subjects in sync in Metering and Billing is necessary if you synchronize usage to external systems, such as Stripe billing or CRMs, as {{site.konnect_short_name}} knows the mapping between the subject and the external system.
> {{site.konnect_short_name}} Metering and Billing will also automatically create a subject for you when you ingest an usage event for a new subject.

## How do subjects work?

{{site.konnect_short_name}} Metering and Billing uses subjects to:

* Associate usage with external systems (for example, Stripe or CRM tools)
* Store descriptive metadata
* Identify the entity producing metered events

Each subject contains the following fields:

* **Key** – The subject’s unique identifier  
* **Display name** – A human-readable label shown in the UI  
* **Metadata** – Optional key-value attributes for additional context  


## Data ingestion

When shipping data to {{site.konnect_short_name}} you must include the subject within the events payload: 

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

### One subject during beta

During the billing beta, customers are limited to **one subject**.  
Support for multiple subjects will be available in the future.


## Schema

[Insert Schema here](https://openmeter.io/docs/api/cloud#tag/subjects)

## Set up a subject

CRUD a subject here