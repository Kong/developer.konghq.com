---
title: Create a webhook with {{site.base_gateway}}
permalink: /how-to/create-a-webhook-with-kong-gateway/
content_type: how_to

description: Configure the Event Hook entity as a webhook to listen for events and push information to the configured URL.

products:
    - gateway
entities:
  - event-hook

works_on:
    - on-prem
tags:
  - event-hook
  - webhook
  - notifications
tldr: 
  q: How do I create a webhook using Event Hooks?
  a: The `webhook` handler can be configured with a URL. When configured, the Event Hook will listen for the event and push information to the configured URL.

prereqs:
  inline:
    - title: A webhook URL
      content: |
        * You can generate a URL by navigating to [https://webhook.site](https://webhook.site) and copying the free URL.
        * Set that URL as an environment variable `export WEBHOOK_URL=YOUR_URL`.
    - title: cURL
      include_content: prereqs/tools/curl
    - title: Reload {{site.base_gateway}}
      include_content: prereqs/event-hook/restart-kong-gateway
cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg


related_resources:
  - text: Push Event Hook information to Slack with {{site.base_gateway}}
    url: /how-to/create-a-custom-webhook-slack-with-kong-gateway/
  - text: Configure an Event Hook to log events with {{site.base_gateway}}
    url: /how-to/create-a-log-event-hook-with-kong-gateway/
  - text: Create an Event Hook that can run custom code with {{site.base_gateway}}
    url: /how-to/create-a-lambda-event-hook-with-kong-gateway/

min_version:
    gateway: '3.4'
---

## Create a webhook

The `webhook` handler is used to configure webhooks that make a `POST` request to the URL provided during configuration. The Event Hook will push information to this URL with the event data. In this guide you will configure an Event Hook that will issue a `POST` request every time an event type `consumers` has a CRUD event. 

Using the Admin API, create an Event Hook on the [Consumers](/gateway/entities/consumer/) event by issuing a `POST` request to the `/event-hooks` endpoint.

{% entity_example %}
type: event_hook
data:
  source: "crud"
  event: "consumers"
  handler: "webhook"
  on_change: true
  config:
    url: $WEBHOOK_URL
formats:
  - admin-api
{% endentity_example %}

Issuing this `POST` request will send a request of type `ping` to the webhook URL verifying that the webhook is configured correctly.


## Validate the webhook

{:.warning}
> **Important**:  Before you can use Event Hooks for the first time, {{site.base_gateway}} needs to be reloaded.

Using the Admin API create a new Consumer: 

{% entity_example %}
type: consumer
data:
  username: my-consumer
formats:
  - admin-api
{% endentity_example %}

Verify on [`https://webhook.site`](https://webhook.site) that you received a `POST` request. It will look like this: 

```json
{
  "entity": {
    "username_lower": "my-consumer",
    "id": "ea87c99f-36f1-41c9-8543-7b13ee2b5dfe",
    "updated_at": 1734547295,
    "type": 0,
    "username": "my-consumer",
    "created_at": 1734547295
  },
  "schema": "consumers",
  "source": "crud",
  "event": "consumers",
  "operation": "create"
}
```

This response body contains the `operation`, the `source`, and the `event`, confirming that a new Consumer was created.
