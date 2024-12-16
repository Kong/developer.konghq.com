---
title: Create an event hook that ships events to logs
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
  
prereqs:
  inline:
    - title: Reload {{site.base_gateway}}
      include_content: prereqs/event-hooks/restart-kong-gateway
  
---

## Create the event hook

Create a long event hook on the `consumers` event using the `crud` source: 

      curl -i -X POST http://localhost:8001/event-hooks \
      -H "Content-Type: application/json" \
      -d '{
        "source": "crud",
        "event": "consumers",
        "handler": "log"
      }'



## Validate the webhook

{:.warning}
> **Important**:  Before you can use event hooks for the first time, {{site.base_gateway}} needs to be reloaded.

1. Using the Admin API create a new consumer: 

    ```sh
    curl -i -X POST http://localhost:8001/consumers \
        -d username="my-consumer"
    ```
2. Review the logs at `/usr/local/kong/logs/error.log` for an an update about the creation of this consumer. The log will look similar to this: 
    
        172.19.0.1 - - [16/Dec/2024:15:57:15 +0000] "POST /consumers HTTP/1.1" 409 147 "-" "HTTPie/2.4.0"
        2024/12/16 15:57:26 [notice] 68854#0: *819021 +--------------------------------------------------+, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |[kong] event_hooks.lua:?:452 "log callback: " { "consumers", "crud", {|, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |    entity = {                                    |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |      created_at = 1702735046,                    |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |      id = "4757bd6b-8d54-4b08-bf24-01e346a9323e",|, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |      type = 0,                                   |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |      username = "Elizabeth Bennet"               |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |    },                                            |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |    operation = "create",                         |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |    schema = "consumers"                          |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |  }, 68854 }                                      |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 +--------------------------------------------------+, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
