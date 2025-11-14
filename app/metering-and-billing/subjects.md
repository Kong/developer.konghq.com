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

Subjects represent the entity that produces usage in {{site.konnect_short_name}} Metering and Billing.

A subject can represent any unique event in your system, such as: 
* Customer ID or User ID  
* Hostname or IP address  
* Service or application name  
* Device ID  

The subject model is intentionally generic, enabling flexible application across different metering scenarios.

In most implementations, a subject maps 1:1 with a customer or user in your system.

## How do subjects work?

{{site.konnect_short_name}} Metering and Billing uses subjects to:

* Associate usage with external systems (for example, Stripe or CRM tools)
* Store descriptive metadata
* Identify the entity producing metered events

Each subject contains the following fields:

* **Key** – The subject’s unique identifier  
* **Display name** – A human-readable label shown in the UI  
* **Metadata** – Optional key-value attributes for additional context  

## Subjects and customers

In most cases, subjects are related to metering and and create usage. A customer, is related to billing and pays for usage. 

You can use the same identifier for both, but they can differ if your usage producer and billing entity are not the same.

For example:

* One customer may have multiple usage-producing subjects  
* A single subject’s usage may need to be billed to a different customer  

For more information, see **subject assignment** in the Metering and Billing documentation.

## Data ingestion

When shipping data to {{site.konnect_short_name}} you must include the subject within the payload: 

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


## Schema

[Insert Schema here](https://openmeter.io/docs/api/cloud#tag/subjects)

## Set up a Route

CRUD a subject here