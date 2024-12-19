---
title: Configure an Event Hook to log events
content_type: how_to

entities:
  - event_hook
works_on:
    - on-prem
products:
    - gateway
tier: enterprise

tags:
  - eventhooks
  - webhook
  - notifications
tldr: 
  q: How do I create an Event Hook that logs events on the Consumer entity.
  a: The `log` Event Hook handler can write log events. You can configure an Event Hook using the `log` handler to write to the log file every time a CRUD event happens on the Consumer entity by issuing a `POST` request to the `/event_hooks` endpoint. 
  
prereqs:
  inline:
    - title: Reload {{site.base_gateway}}
      include_content: prereqs/event-hook/restart-kong-gateway
cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---


`log` Event Hook configuration specifies an event and a source. In this guide you will create an Event Hook that listens for CRUD events on the Consumers entity. This Event Hook will create a log entry when a CRUD event occurs. 

## 1. Create the Event Hook

Create a long Event Hook on the `consumers` event using the `crud` source: 

```sh
curl -i -X POST http://localhost:8001/event-hooks \
-H "Content-Type: application/json" \
-d '{
  "source": "crud",
  "event": "consumers",
  "handler": "log"
}'
```


## 2. Validate the webhook

{:.warning}
> **Important**:  Before you can use Event Hooks for the first time, {{site.base_gateway}} needs to be reloaded.

Use the Admin API to create a new Consumer: 

```sh
curl -i -X POST http://localhost:8001/consumers \
    -d username="my-consumer"
```

Review the logs at `/usr/local/kong/logs/error.log` for an update about the creation of this Consumer. The log will look similar to this: 
 
```sh   
        172.19.0.1 - - [16/Dec/2024:15:57:15 +0000] "POST /consumers HTTP/1.1" 409 147 "-" "HTTPie/2.4.0"
        2024/12/16 15:57:26 [notice] 68854#0: *819021 +--------------------------------------------------+, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |[kong] event_hooks.lua:?:452 "log callback: " { "consumers", "crud", {|, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |    entity = {                                    |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |      created_at = 1702735046,                    |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |      id = "4757bd6b-8d54-4b08-bf24-01e346a9323e",|, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |      type = 0,                                   |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |      username = "my-consumer"               |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |    },                                            |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |    operation = "create",                         |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |    schema = "consumers"                          |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 |  }, 68854 }                                      |, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
        2024/12/16 15:57:26 [notice] 68854#0: *819021 +--------------------------------------------------+, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
```