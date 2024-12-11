---
title: Run custom code in a event hook
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
  q: How do I write custom code in an event hook
  a: Send a `POST` request to the event_hooks endpoint containing the source and event for the webhook.
---

## Create a lambda event hook

1. Create a lua script to load into the lambda event hook. 

    ```lua
    return function (data, event, source, pid)
    local user = data.entity.username
    error("Event hook on consumer " .. user .. "")
    end
    ```
2. Create a lambda event hook on the `consumers` event, with the `crud` source by creating a `POST` request to the Admin API. 

    curl -i -X POST http://localhost:8001/event-hooks \
        -d source=crud \
        -d event=consumers:update \
        -d handler=lambda \
        -d on_change=true \
        -d config.functions='return function (data, event, source, pid) local user = data.entity.username error("Event hook on consumer " .. user .. "") end'

## Validate the webhook


1. Using the Admin API create a new consumer: 

    ```sh
    curl -i -X POST http://localhost:8001/consumers \
        -d username="my-consumer"
    ```
2. Review the logs at `/usr/local/kong/logs/error.log` for an an update about the creation of this consumer. The log will look similar to this: 
    
    ```sh
     11/Dec/2024:23:20:56 +0000 [error] 114#0: *153047 [kong] event_hooks.lua:190 [string "return function (data, event, source, pid)..."]:3: Event hook on consumer my-consumer, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001

    ```
