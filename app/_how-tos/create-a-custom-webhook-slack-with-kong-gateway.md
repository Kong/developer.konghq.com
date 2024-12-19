---
title: Push Event Hook information to Slack with {{site.base_gateway}}
content_type: how_to
works_on:
    - on-prem
products:
    - gateway
entities:
  - event-hook
tier: enterprise
tags:
  - eventhooks
  - webhook
  - notifications

tldr:
  q: How can I create a custom webhook to push information to Slack using Event Hooks.
  a: With an application URL from Slack, you can configure an Event Hook using the `webhook-custom` handler that can `POST` event information to Slack.
prereqs:
  inline:
    - title: A Slack webhook application
      include_content: prereqs/event-hook/slack
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
  - text: Create a webhook with {{site.base_gateway}}
    url: /how-to/create-a-webhook-with-kong-gateway/
  - text: Configure an Event Hook to log events with {{site.base_gateway}}
    url: /how-to/create-a-log-event-hook-with-kong-gateway/
  - text: Create an Event Hook that can run custom code with {{site.base_gateway}}
    url: /how-to/create-a-lambda-event-hook-with-kong-gateway/

---


## 1. Configure an Event Hook using the `webhook-custom` handler

Using the `webhook-custom` handler, you can configure an Event Hook that listens for events on a source. The `webhook-custom` handler offers a template that you can configure to create a custom webhook. In this tutorial, we will configure an Event Hook that issues a `POST` request when a `crud` event happens on the Consumer entity. That `POST` request will be made to a Slack webhook application containing a custom message describing the event. 

    curl -X POST http://localhost:8001/event-hooks \
      -H "Content-Type: application/json" \
      -d '{
        "source": "crud",
        "event": "consumers",
        "handler": "webhook-custom",
        "on_change": true,
        "config": {
          "method": "POST",
          "url": "$SLACK_WEBHOOK_URL",
          "headers": {
            "Content-type": "application/json"
          },
          "payload": {
            "text": "new consumer added"
          }
        }
      }'

Posting this will result in a `200` response. The `config` body in the Event Hook contains information about the webhook that was created: 

* **`"method": "POST"`**: The method we are using in the webhook.
* **`"url": "$SLACK_WEBHOOK_URL"`**: The URL of the webhook, in this case we are using the Slack URl that we created and set as an environment variable. 
* **`"payload"`**: What this webhook will `POST`. 


## 2. Validate the webhook


{:.warning}
> **Important**:  Before you can use Event Hooks for the first time, {{site.base_gateway}} needs to be [reloaded](/how-to/restart-kong-gateway-container).


Using the Admin API to create a new Consumer: 

```sh
curl -i -X POST http://localhost:8001/consumers \
    -d username="my-consumer"
```


Slack will post a message to the channel informing you that a Consumer was added. 