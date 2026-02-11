---
title: Create an Event Hook that can run custom code with {{site.base_gateway}}
permalink: /how-to/create-a-lambda-event-hook-with-kong-gateway/
content_type: how_to

description: Execute custom Lua code on an event by configuring an Event Hook entity with the lambda handler, 
entities:
  - event-hook
works_on:
    - on-prem
products:
    - gateway
tags:
  - event-hook
  - webhook
  - notifications
tldr: 
  q: Can you write code to pass into an Event Hook?
  a: The `lambda` Event Hook handler can be used to pass custom Lua code. You can then configure the Event Hook to execute that code on an event.

prereqs:
  inline:
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
  - text: Push Event Hook information to Slack with {{site.base_gateway}}
    url: /how-to/create-a-custom-webhook-slack-with-kong-gateway/

min_version:
    gateway: '3.4'
---

## Create a lambda Event Hook

A `lambda` Event Hook is an Event Hook that utilizes the `lambda` handler to pass custom code to an Event Hook. Depending on the source and individual event, that code can execute during various stages of the lifecycle of an event. In this guide, you will create an `lambda` Event Hook with custom code that logs an error with a specific message every time you create a [Consumer](/gateway/entities/consumer/). 

Create a Lua script to load into the lambda Event Hook. 

```lua
return function (data, event, source, pid)
local user = data.entity.username
error("Event Hook on consumer " .. user .. "")
return true
end
```

Create a `lambda` Event Hook on the `consumers` event, with the `crud` source by creating a `POST` request to the Admin API and passing the code in the request body as an array of strings.

{% entity_example %}
type: event_hook
data:
  source: "crud"
  event: "consumers"
  handler: "lambda"
  config:
    functions:
      - |-
        return function (data, event, source, pid) local user = data.entity.username error("Event Hook on consumer " .. user .. "") return true end
formats:
  - admin-api
{% endentity_example %}

{:.info}
> **Note:** This should return true if the Lua function executed succeeded. The backend engine will check the return value, if it is not true, it would be considered as a failure, and the backend engine will try it later.


## Validate the webhook

{:.warning}
> **Important**:  Before you can use Event Hooks for the first time, {{site.base_gateway}} needs to be [reloaded](/how-to/restart-kong-gateway-container/).

Using the Admin API create a new Consumer: 

{% entity_example %}
type: consumer
data:
  username: my-consumer
formats:
  - admin-api
{% endentity_example %}

Review the logs at `/usr/local/kong/logs/error.log` for an update about the creation of this Consumer. The log will look similar to this: 
    
```sh
2024/12/16 21:52:54 [error] 114#0: *153047 [kong] event_hooks.lua:190 [string "return function (data, event, source, pid)..."]:3: Event Hook on consumer my-consumer, context: ngx.timer, client: 172.19.0.1, server: 0.0.0.0:8001
```

In the error logs, you will see the Event Hook and the error log that resulted from `error("Event Hook on consumer " .. user .. "")`. 