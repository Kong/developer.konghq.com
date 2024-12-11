---
title: Create a log event hook to monitor consumer events
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
  q: How do I create a log webhook to monitor consumer events
  a: Send a `POST` request to the event_hooks endpoint containing the source and event for the webhook.
---

## Create the event hook

Create a long event hook on the `consumers` event using the `crud` source. 

```sh
 curl -i -X POST http://{HOSTNAME}:8001/event-hooks \
   -d source=crud \
   -d event=consumers:update \
   -d handler=log \
   -d on_change=true
```

## Validate the webhook


1. Using the Admin API create a new consumer: 

    ```sh
    curl -i -X POST http://localhost:8001/consumers \
        -d username="my-consumer"
    ```
2. Review the logs at `/usr/local/kong/logs/error.log` for an an update about the creation of this consumer. The log will look similar to this: 
    
    ```sh
    192.168.65.1 - - [11/Dec/2024:23:20:56 +0000] "POST /consumers HTTP/1.1" 201 183 "-" "-"
    ```