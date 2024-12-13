---
title: Create a webhook that monitors Consumer creation
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
  q: How do I create a webhook that monitors for the creation of new consumers?
  a: Send a `POST` request to the event_hooks endpoint containing the source, event, template and URL for your webhook. 

prereqs:
  inline:
    - title: A webhook URL
      content: |
        * You can generate a URL by navigating to https://webhook.site and copying the free URL.
---


## Create a webhook

1. Using the Admin API, create an event hook on the consumers event by issuing a `POST` request to the `/event-hooks` endpoint.

        curl -i -X POST http://localhost:8001/event-hooks \
            -d source=crud \
            -d event=consumers:update \
            -d handler=webhook \
            -d on_change=true \
            -d config.url=https://webhook.site/94688621-990a-407f-b0b2-f92322d04c700"

2. Issuing this `POST` request will send a request of type `ping` to the webhook URL verifying that the webhook is configured correctly.



## Validate the webhook


1. Using the Admin API create a new consumer: 

    ```sh
    curl -i -X POST http://localhost:8001/consumers \
        -d username="my-consumer"
    ```
2. Verify on webhook.site that you received a `POST` request. It will look like this: 

    ```json
    {
    "event_hooks": {
        "id": "88a0d071-29c8-4d6a-827e-dbecf09e917c",
        "event": "consumers:update",
        "updated_at": 1733955343,
        "config": {
        "headers": {
            "content-type": "application/json"
        },
        "ssl_verify": false,
        "url": "https://webhook.site/94688621-990a-407f-b0b2-123923ad04c700"
        },
        "source": "crud",
        "created_at": 1733955343,
        "handler": "webhook",
        "on_change": true
    },
    "operation": "create",
    "source": "kong:event_hooks",
    "event": "ping"
    }
    ```

This response body contains the `operation`, the `source`, and the `event`, confirming that a new user was created 