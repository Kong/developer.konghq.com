---
title: Get started with Metering and Billing in {{site.konnect_short_name}}
description: Learn how to...
content_type: how_to

permalink: /metering-and-billing/get-started/
breadcrumbs:
  - /metering-and-billing/

products:
    - metering-and-billing

works_on:
    - konnect

tags:
    - get-started

tldr: 
  q: What is Metering and Billing in {{site.konnect_short_name}}, and how can I get started with it?
  a: |
    blah

tools:
    - deck
  
prereqs:
  inline:
    - title: cURL
      content: |
        [cURL](https://curl.se/) is used to send requests to {{site.base_gateway}}. 
        `curl` is pre-installed on most systems.
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
next_steps:
  - text: See all {{site.base_gateway}} tutorials
    url: /how-to/?products=gateway
  - text: Learn about {{site.base_gateway}} entities
    url: /gateway/entities/
  - text: Learn about how {{site.base_gateway}} is configured
    url: /gateway/configuration/
  - text: See all {{site.base_gateway}} plugins
    url: /plugins/
automated_tests: false
---

## Create a system access token in Konnect
to ingest usage events?

## Create a meter

## Send your first usage

Ingest usage events in CloudEvents format:

```
curl -X POST https://openmeter.cloud/api/v1/events \
  -H 'Content-Type: application/cloudevents+json' \
  -H 'Authorization: Bearer <API_KEY>' \
  --data-raw '
{
  "specversion": "1.0",
  "type": "prompt",
  "id": "00001",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "chat-app",
  "subject": "customer-1",
  "data": {
    "tokens": "123456",
    "model": "gpt4-turbo",
    "type": "output"
  }
}
'
```

## Query your meter

Query the meter to see the usage.

## Create a feature

## Create a plan

## Set up billing