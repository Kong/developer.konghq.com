---
title: Event hooks
content_type: reference
entities:
  - event_hooks

description: Event hooks allow Kong Gateway to communicate with target services or resources, notifying the target resource that an event was triggered. 
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
  E["Event Detected"]
  F["Handler Activated"]
  G["Action Executed"]
  E --> F
  F --> G
 
{% endmermaid %}

### Handlers

There are four types of handlers that can be used with the Event Hooks entity: 

* **`webhook`**: Issues a `POST` request to a provided URL with the event data as a payload. 
* **`log`**: Logs the event and the content of the payload as a Kong Gateway log.
* **`webhook-custom`**: Fully configurable request. Supports templating, configurable body, payload, and headers. 
* **`lambda`**: This handler runs Lua code after an event is triggered.


### Sources

{{site.base_gateway}} offers the [`/event-hooks/sources`](/api/admin-ee/latest/#/Event-hooks/get-event-hooks-sources) endpoint where you can see all available sources, events and fields that are available for creating event hook templates. Sources are the actions that trigger the event hook.



The response body from the endpoint describes a source that can be interepreted in the following pattern: 

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


* **event**: `health`
* **source**: `balancer`
* **handler**: `webhook-custom`

The values in the `fields` array represent the availble template parameters you can use when constructing a payload.

* `upstream_id`
* `ip`
* `port`
* `hostname`
* `health`

These parameters can be used to issue notifications any time an upstream in your application is not reachable. 

For step-by-step guides on configuring event hooks see the following docs: 

* [How to configure a custom webhook](/how-to/create-a-custom-webhook)
* [How to create a log event hook](/how-to/create-a-log-event-hook)
* [How to create a lambda event hook](/how-to-create-a-lambda-event-hook)




## Schema

{% entity_schema %}



## Configure an event hook


    curl --request POST \
      --url http://localhost:8001/event-hooks \
      --header 'Content-Type: application/json' \
      --header 'Kong-Admin-Token: kongAdminToken' \
      --data '{
      "source": "crud",
      "event": "admins:create",
      "handler": "webhook",
      "config": {
        "url": "http://<your host>/admin-1created"
      }
    }'