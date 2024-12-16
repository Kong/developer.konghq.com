---
title: Create a custom webhook to push information to Slack
content_type: how_to

related_resources:
  - text: Event hooks
    url: /gateway/entities/event_hooks

works_on:
    - on-prem


tags:
  - eventhooks
  - webhook
  - notifications

tldr:
  q: How can I create a custom webhook to push information to Slack using event hooks.
  a: Using the Slack application URL along with the `webhook-custom` handler to create an event hook that `POSTS` to your Slack application.
prereqs:
  inline:
    - title: A Slack webhook application
      include_content: prereqs/event-hooks/slack

    - title: Reload {{site.base_gateway}}
      include_content: prereqs/event-hooks/restart-kong-gateway

---


## Configure an event hook using the  `webhook-custom` handler

    curl -X POST http://localhost:8001/event-hooks \
      -H "Content-Type: application/json" \
      -d '{
        "source": "crud",
        "event": "consumers",
        "handler": "webhook-custom",
        "on_change": true,
        "config": {
          "method": "POST",
          "url": "{SLACK_WEBHOOK_URL}",
          "headers": {
            "Content-type": "application/json"
          },
          "payload": {
            "text": "new consumer added"
          }
        }
      }'


Be sure to replace `{SLACK_WEBHOOK_URL}` with the one you copied from Slack. 



## Validate the webhook

{:.warning}
> **Important**:  Before you can use event hooks for the first time, {{site.base_gateway}} needs to be reloaded.


1. Using the Admin API to create a new consumer: 

    ```sh
    curl -i -X POST http://localhost:8001/consumers \
        -d username="my-consumer"
    ```


2. Slack will post a message to the channel informing you that a consumer was added. 
