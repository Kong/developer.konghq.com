---
title: How to modify the logging plugins output format
content_type: support
description: Use the `custom_fields_by_lua` config field to nest a logging plugin's output under a single top-level element for centralized logging aggregators.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: File Log plugin log format documentation
    url: /plugins/file-log/#log-format
tldr:
  q: How do I nest a logging plugin's output under a custom top-level element using `custom_fields_by_lua`?
  a: |
    Use the `custom_fields_by_lua` config field to add a new top-level element (for example `message`) that returns `kong.log.serialize()`, then set every other standard top-level field to `return nil` so it doesn't leak out alongside the nested element. Some Kong Gateway versions' `kong.log.serialize()` also returns `workspace_name`, `upstream_status`, and `source`, so include those in the nil list too or they will appear as extra top-level keys.
---

## Overview

When using the logging plugins, the log information is at the top level of the JSON as per the format described in the documentation. How can this format be altered to have the logging content nested under some meta data values that are required by the centralized logging aggregator?

## Steps

Use the `custom_fields_by_lua` functionality to alter the structure of the logging output.

For this example, we will assume that the logging content needs to be added under an element named `message` and the `file-log` plugin is being used.

There are two config changes needed to achieve the goal:

1) Add a new element name `message` that contains the standard log serializer content

2) Remove the top level elements of the standard logging. This can be done by setting those elements to `nil`

The full example to create the plugin would look like this:

```bash
curl -s -X POST 'http://<kong-admin-api>:8001/default/routes/<route_id>/plugins/' \
-H 'kong-admin-token: <token>' \
-H 'Content-Type: application/json' \
--data-raw '{
    "name": "file-log",
    "config": {
        "reopen": false,
        "path": "/dev/stdout",
        "custom_fields_by_lua": {
            "message": "return kong.log.serialize()",
            "tries": "return nil",
            "latencies": "return nil",
            "workspace": "return nil",
            "workspace_name": "return nil",
            "upstream_status": "return nil",
            "source": "return nil",
            "started_at": "return nil",
            "request": "return nil",
            "client_ip": "return nil",
            "response": "return nil",
            "service": "return nil",
            "upstream_uri": "return nil",
            "route": "return nil",
            "authenticated_entity": "return nil",
            "consumer": "return nil"
        }
    }
}'
```

> **Note:** Some versions of `kong.log.serialize()`'s base table include additional fields not covered by shorter nil-lists from older examples of this recipe, such as `workspace_name`, `upstream_status`, and `source`. If these are omitted from `custom_fields_by_lua`, they leak through as extra top-level keys alongside `message` instead of being fully nested underneath it. The list above includes them so the output nests cleanly — confirm against your own Kong Gateway version's `kong.log.serialize()` output which fields it returns.

This will output all the standard log content nested under the parent element named `message`, for example:

```json
{
	"message": {
		"started_at": 1788360462457,
		"tries": [{
			"balancer_start": 1788360462457,
			"balancer_latency": 1,
			"balancer_latency_ns": 134912,
			"ip": "172.18.0.6",
			"port": 80,
			"target_id": "unknown",
			"hostname": "httpbin",
			"keepalive": true
		}],
		"client_ip": "162.159.140.245",
		"workspace": "a1513093-a2ad-4b7a-ba3d-8cb6646274dd",
		"response": {
			"status": 200,
			"size": 1077,
			"headers": {
				"kong-service-name": "kb-nr-ae-flog-svc",
				"via": "1.1 kong/3.14.0.0-enterprise-edition",
				"x-kong-proxy-latency": "1",
				"x-kong-upstream-latency": "1",
				"content-length": "514",
				"server": "gunicorn/19.9.0",
				"connection": "close",
				"kong-route-id": "1feccf91-85bd-4a8f-a160-2edf9606767d",
				"kong-route-name": "kb-nr-ae-flog-route",
				"kong-service-id": "37709fba-90db-4a4e-8425-7a9b42f56543",
				"content-type": "application/json",
				"date": "Wed, 02 Sep 2026 14:47:42 GMT",
				"access-control-allow-origin": "*",
				"access-control-allow-credentials": "true",
				"x-kong-request-id": "43b55b00daeb4866b9649223abadee50"
			}
		},
		"latencies": {
			"third_party": 0.009984,
			"redis": 0,
			"socket": 0,
			"client": 0.59136,
			"kong": 1,
			"request": 2,
			"kong_internal": 0.30469926330566,
			"dns": 0.009984,
			"http_client": 0,
			"receive": 0,
			"proxy": 1
		},
		"service": {
			"id": "37709fba-90db-4a4e-8425-7a9b42f56543",
			"retries": 5,
			"port": 80,
			"enabled": true,
			"updated_at": 1788360381,
			"write_timeout": 60000,
			"name": "kb-nr-ae-flog-svc",
			"protocol": "http",
			"connect_timeout": 60000,
			"host": "httpbin",
			"read_timeout": 60000,
			"created_at": 1788360381,
			"ws_id": "a1513093-a2ad-4b7a-ba3d-8cb6646274dd",
			"path": "/anything"
		}
	}
}
```
