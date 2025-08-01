---
title: Event Hooks
content_type: reference
entities:
  - event-hook

description: Event Hooks allow {{site.base_gateway}} monitor to communicate with target services or resources, notifying the target resource that an event was triggered. 
related_resources:
  - text: Gateway Services
    url: /gateway/entities/service/
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/
  - text: Create a webhook with {{site.base_gateway}}
    url: /how-to/create-a-webhook-with-kong-gateway/
  - text: Push Event Hook information to Slack with {{site.base_gateway}}
    url: /how-to/create-a-custom-webhook-slack-with-kong-gateway/
  - text: How to create a log Event Hook with {{site.base_gateway}}
    url: /how-to/create-a-log-event-hook-with-kong-gateway/
  - text: Configure an Event Hook to log events with {{site.base_gateway}}
    url: /how-to/create-a-lambda-event-hook-with-kong-gateway/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
    
products:
    - gateway
tools:
    - admin-api
schema:
    api: gateway/admin-ee
    path: /schemas/Event-hooks

api_specs:
    - gateway/admin-ee

works_on:
  - on-prem

tags:
  - webhook
  - logging
---

## What is an Event Hook?

An Event Hook is a {{site.base_gateway}} entity that can be configured to listen for specific events from {{site.base_gateway}} entities. An Event Hook can be configured to send information to logs, webhooks, or third-party applications. 

## How do Event Hooks work?

{{site.base_gateway}} Event Hooks work by configuring the following three elements: 

* Sources: The actions or operation that trigger the Event Hook.
* Events: The {{site.base_gateway}} entity that the Event Hook monitors for actions.
* Handlers: The mechanism that defines what action is performed when an event is triggered, like sending a webhook, logging, or executing custom code.

<!-- vale off -->
{% mermaid %}
flowchart LR
    subgraph events [Kong Gateway Events]
        A(<b>Gateway Service</b><br>Create<br>Delete<br>Modify)
        B(<b>Admins</b><br>Create<br>Delete<br>Modify)
    end 

    subgraph handlers [Handlers]
        C(<b>Webhook</b>)
        D(<b>logs</b><br>)
        E(<b>webhook-custom</b>)
        F(<b>Lambda</b>)
    end

    subgraph output [Output]
        W(<b> POST to third party application</b>)
        X(<b> Log to /usr/local/kong/logs/error.log</b>)
        Y(<b> POST to third party application</b><br>Fully customizable)
        Z(<b> Custom Code Lua code </b>)
    end
    
    A --> handlers
    B --> handlers

    C --> W
    D --> X
    E --> Y
    F --> Z 
{% endmermaid %}
<!-- vale on -->

### Handlers

There are four types of handlers that can be used with Event Hooks:  

* **`webhook`**: Issues a `POST` request to a provided URL with the event data as a payload. 
* **`log`**: Logs the event and the content of the payload as a {{site.base_gateway}} log.
* **`webhook-custom`**: Fully configurable request. Supports templating, configurable body, payload, and headers. 
* **`lambda`**: This handler runs Lua code after an event is triggered.

By default, the `lambda` handler is "Sandboxed". Sandboxing means that {{site.base_gateway}} restricts the types of Lua functions that can be loaded as well as the level of access to {{site.base_gateway}} that is available for these custom functions. For example, in `sandbox` mode, a `lambda` Event Hook will not have access to global values such as `kong.configuration.pg_password`, or OS level functions like `os.execute(rm -rf /*)`, but can still run Lua code like `local foo = 1 + 1`. Removing `sandbox` requires editing the `kong.conf` value `untrusted_lua`, for more information see the [kong.conf documentation](/gateway/configuration/#untrusted-lua).

### Sources

{{site.base_gateway}} offers the [`/event-hooks/sources`](/api/gateway/admin-ee/#/Event-hooks/get-event-hooks-sources) endpoint where you can see all available sources, events and fields that are available for creating Event Hook templates. Sources are the actions that trigger the Event Hook.

The response body from the endpoint describes a source that can be interpreted in the following pattern: 

1. **Level 1**: The source, the action that triggers the Event Hook.
2. **Level 2**: The event, this is the {{site.base_gateway}} entity that the Event Hook listens to for events.
3. **Level 3**: The available template parameters for constructing `webhook-custom` payloads. 

This is an example response body: 


```json
{
	"data": {
		"balancer": {
			"health": {
				"fields": [
					"upstream_id",
					"ip",
					"port",
					"hostname",
					"health"
				]
			}
		}
  }
}
```

You can apply the pattern to the response body and extract the following information: 

* **source**: `balancer`
* **event**: `health`
* **handler**: `webhook-custom`

The values in the `fields` array represent the available template parameters you can use when constructing a payload.

* `upstream_id`
* `ip`
* `port`
* `hostname`
* `health`

These parameters can be used to issue notifications any time an upstream in your application is not reachable. 


### Available sources

- `dao:crud`: Handles `dao:crud` clustering events.
- `balancer`: Information from the load balancer like: `upstream_id`, `ip`, `port`, `hostname`, `health`
- `ai-rate-limiting-advanced`: Run an event when a rate limit has been exceeded.
- `service-protection`: Run an event when a rate limit has been exceeded.
- `rate-limiting-advanced`: Run an event when a rate limit has been exceeded.
- `crud`: Create, read, and update events from {{site.base_gateway}} entities such as Consumers.
- `oas-validation`: Runs an event when [OAS validation Plugin](/plugins/oas-validation/) fails.

For information about specific events related to a source, issue a `GET` request to the `/event-hooks/sources/{source}` endpoint. 
The API returns a list of all of the events associated to a source in the following format: `balancer: health`. 

## Schema

{% entity_schema %}

## Set up an Event Hook

{% entity_example %}
type: event_hook
data:
  source: "crud"
  event: "consumers"
  handler: "webhook"
  on_change: true
  config:
      "url": "$WEBHOOK_URL"
{% endentity_example %}
