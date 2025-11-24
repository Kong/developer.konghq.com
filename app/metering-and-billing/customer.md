---
title: "Customer"
content_type: reference
description: "Learn how Customers work in {{site.konnect_short_name}} Metering and Billing and how they access features."
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

## What is a customer?

Customers represent individuals or organizations that subscribe to plans and gain access to features.  
You can create and manage customers using the API or the Konnect dashboard.
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

## Create a customer

When onboarding a customer, you must provide the following information in the request:

{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "Name"
    description: "The name of the customer, for example: `ACME, Inc.`"
  - name: "Assigned Subject"
    description: "The [subject](/metering-and-billing/subjects/) associated with the customer."
{% endtable %}


```ts
const customer = await openmeter.customers.create({
  name: 'ACME, Inc.',
  usageAttribution: { subjects: ['my-identifier'] },
});
```

{% include_cached /konnect/metering-and-billing/assigned-subjects.md %}

## Schema

[Insert Schema here](https://openmeter.io/docs/api/cloud#tag/customers)

## Set up a Customer

CRUD a subject here