---
title: 'WebSocket Validator'
name: 'WebSocket Validator'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Validate WebSocket messages before they are proxied'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.0'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: websocket-validator.png

categories:
  - traffic-control

tags:
  - websocket

search_aliases:
  - websocket-validator

related_resources:
  - text: WebSocket Size Limit plugin
    url: /plugins/websocket-size-limit/
  - text: Enable OAuth 2.0 authentication for WebSocket requests
    url: /how-to/enable-oauth2-authentication-for-websocket-requests/
---

Validate individual WebSocket messages against a user-specified schema before proxying them.

The message schema can be configured by type (text or binary) and sender (client or upstream).

This plugin supports validation against [JSON schema draft4](https://json-schema.org/specification-links#draft-4).

## How the WebSocket Validator plugin works 

When an incoming message is invalid according to the schema, a close frame is sent to the sender 
(status: `1007`) and the peer before closing the connection.

For example, here's what it looks like when validating that client text frames:
* Are valid JSON
* Are a JSON object (`{}`)
* Have a `name` attribute (of any type)

<!-- vale off -->
{% mermaid %}
sequenceDiagram
autonumber
    activate Client
    activate Kong
    Client->>Kong: text(`{ "name": "Alex" }`)
    activate Upstream
    Kong->>Upstream: text(`{ "name": "Alex" }`)
    Client->>Kong: text(`{ "name": "Kiran" }`)
    Kong->>Upstream: text(`{ "name": "Kiran" }`)
    Client->>Kong: text(`{ "missing_name": true }`)
    Kong->>Client: close(status=1007)
    Kong->>Upstream: close()
    deactivate Upstream
    deactivate Kong
    deactivate Client
{% endmermaid %}
<!--vale on-->

The clients with the names `Alex` and `Kiran` pass validation, but when `missing_name` appears, 
it's considered invalid and the plugin sends a close frame.

## Configuring the WebSocket Validator plugin

At least one of the following complete message validation configuration pairs must be defined:
  * [`config.client.text.type`](/plugins/websocket-validator/reference/#schema--config-client-text-type) and [`config.client.text.schema`](/plugins/websocket-validator/reference/#schema--config-client-text-schema)
  * [`config.client.binary.type`](/plugins/websocket-validator/reference/#schema--config-client-binary-type) and [`config.client.binary.schema`](/plugins/websocket-validator/reference/#schema--config-client-binary-schema)
  * [`config.upstream.text.type`](/plugins/websocket-validator/reference/#schema--config-upstream-text-type) and [`config.upstream.text.schema`](/plugins/websocket-validator/reference/#schema--config-upstream-text-schema)
  * [`config.upstream.binary.type`](/plugins/websocket-validator/reference/#schema--config-upstream-binary-type) and [`config.upstream.binary.schema`](/plugins/websocket-validator/reference/#schema--config-upstream-binary-schema)

See [Validating client text frames](/plugins/websocket-validator/examples/validate-client-text-frames/) for an example.