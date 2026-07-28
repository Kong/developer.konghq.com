---
title: Sending notifications when a Kong session is created using Event Hooks
content_type: support
description: You can use Kong Event Hooks to send notifications to a webhook endpoint.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Is it possible for Kong to notify when a session is created?
  a: |
    Yes. Use Kong Event Hooks to send a notification to a webhook endpoint on a CRUD event for the `sessions` entity. Check the available event hook sources and the `sessions` schema through the Admin API, then create an event hook with `source: crud`, `event: sessions`, and a `webhook-custom` handler pointing at your endpoint.
related_resources:
  - text: Kong Event Hooks documentation
    url: /gateway/admin-api/event-hooks/reference/
---

## Sending notifications when a Kong session is created

Can Kong be configured to send a notification when an authorized session is created? For example, when logging in to Kong Manager?

You can use Kong Event Hooks to send notifications to a webhook endpoint. There is further detail on Kong Event Hooks at the documentation link below.

For our requirement, we can check to see what event hook sources are available. Specifically, we are interested in CRUD events for the `sessions` entity:

```bash
curl -sk -X GET 'https://api.kong.lan:8444/event-hooks/sources' | jq '.data.crud.sessions'
{
  "fields": [
    "operation",
    "entity",
    "old_entity",
    "schema"
  ]
}
```

From the result above, we can see that the source of the event is `crud` and the event is for `sessions`. We can also see the available fields for the webhook notification are `operation`, `entity`, `old_entity`, and `schema`.

But what parameters does the `sessions` entity have? For this information, we can make a request to the `/schemas` endpoint for the `sessions` entity:

```bash
curl -sk -X GET 'https://api.kong.lan:8444/schemas/sessions' -H 'Kong-Admin-Token: password' | jq
{
  "fields": [
    {
      "id": {
        "type": "string",
        "uuid": true,
        "auto": true,
        "len_min": 1
      }
    },
    {
      "session_id": {
        "type": "string",
        "unique": true,
        "len_min": 1,
        "required": true
      }
    },
    {
      "expires": {
        "type": "integer"
      }
    },
    {
      "data": {
        "type": "string",
        "len_min": 1
      }
    },
    {
      "created_at": {
        "type": "integer",
        "auto": true,
        "timestamp": true
      }
    }
  ]
}
```

Now we have all the information needed for the event hook, which can be created with an Admin API call like this:

```bash
curl -s -X POST 'https://api.kong.lan:8444/event-hooks' \
-H 'content-type: application/json' \
--data-raw '{
	"source": "crud",
	"event": "sessions",
	"handler": "webhook-custom",
	"config": {
		"body_format": true,
		"method": "POST",
		"payload_format": true,
		"headers_format": false,
		"payload": {
			"text": "webhook-custom for sessions : operation {{ operation }}, entity.session_id {{ entity.session_id }}, entity.expires {{ entity.expires }}, entity.data {{ entity.data }}, entity.created_at {{ entity.created_at }} schema {{ schema }}"
		},
		"url": "<webhook_endpoint>",
		"headers": {
			"content-type": "application/json"
		},
		"ssl_verify": false
	}
}'
```
