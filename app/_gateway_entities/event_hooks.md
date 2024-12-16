---
title: Event hooks
content_type: reference
entities:
  - event_hooks
tier: enterprise
description: Event hooks allow Kong Gateway monitor to communicate with target services or resources, notifying the target resource that an event was triggered. 
related_resources:
  - text: Services
    url: /gateway/entities/service/
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/

tools:
    - admin-api
    - kic
    - terraform
schema:
    api: gateway/admin-ee
    path: /schemas/Event-hooks


---


## How do Event Hooks work?

{{site.base_gateway}} Event Hooks work by configuring the following three elements: 

* Sources: The actions or operation that trigger the event hook.
* Events: The Kong entity that the event hook monitors for actions.
* Handlers: The mechanism that defines what action is performed when an event is triggered, like sending a webhook, logging, or executing custom code.

{% mermaid %}
flowchart LR
    subgraph events [Kong gateway Events]
        A(<b>Service</b><br>Create<br>Delete<br>Modify)
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

### Handlers

There are four types of handlers that can be used with the Event Hooks entity: 

* **`webhook`**: Issues a `POST` request to a provided URL with the event data as a payload. 
* **`log`**: Logs the event and the content of the payload as a {{site.base_gateway}} log.
* **`webhook-custom`**: Fully configurable request. Supports templating, configurable body, payload, and headers. 
* **`lambda`**: This handler runs Lua code after an event is triggered.

### Sources

{{site.base_gateway}} offers the [`/event-hooks/sources`](/api/gateway/admin-ee/#/Event-hooks/get-event-hooks-sources) endpoint where you can see all available sources, events and fields that are available for creating event hook templates. Sources are the actions that trigger the event hook.

The response body from the endpoint describes a source that can be interpreted in the following pattern: 

1. **Level 1**: The source, the action that triggers the event hook.
2. **Level 2**: The event, this is the {{site.base_gateway}} entity that the event hook listens to for events.
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

- `dao:crud`
- `balancer`
- `ai-rate-limiting-advanced`
- `service-protection`
- `rate-limiting-advanced`
- `crud`
- `oas-validation`

For information about specific events related to a source issue a `GET` request to the `/event-hooks/sources/{source}` endpoint. Doing so will return a list of all of the events associated to a source like: `balancer: health`. 

## Schema

{% entity_schema %}


## Configure an event hook


For step-by-step guides on configuring event hooks see the following docs: 

* [Create a webhook](/how-to/create-a-webhook/)
* [Create a webhook that posts to Slack](/how-to/create-a-custom-webhook-slack)
* [How to create a log event hook](/how-to/create-a-log-event-hook)
* [How to create a lambda event hook](/how-to/create-a-lambda-event-hook)

