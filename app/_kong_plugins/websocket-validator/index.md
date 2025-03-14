---
title: 'WebSocket Validator'
name: 'WebSocket Validator'

content_type: plugin

publisher: kong-inc
description: 'Validate WebSocket messages before they are proxied'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

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

search_aliases:
  - websocket-validator
---

Validate individual WebSocket messages against to a user-specified schema before proxying them.

The message schema can be configured by type (text or binary) and sender (client or upstream).

This plugin supports validation against [JSON schema draft4](https://json-schema.org/specification-links.html#draft-4).

## How it works 

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

## Configuring the plugin

At least one of the following complete message validation configuration pairs must be defined:
  * `config.client.text.type` and `config.client.text.schema`
  * `config.client.binary.type` and `config.client.binary.schema`
  * `config.upstream.text.type` and `config.upstream.text.schema`
  * `config.upstream.binary.type` and `config.upstream.binary.schema`

See [Validating client text frames](/plugins/websocket-validator/examples/validate-client-text-frames/) for an example.