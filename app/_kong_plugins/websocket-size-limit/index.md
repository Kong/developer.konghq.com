---
title: 'WebSocket Size Limit'
name: 'WebSocket Size Limit'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Block incoming WebSocket messages greater than a specified size'

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
icon: websocket-size-limit.png

categories:
  - traffic-control

search_aliases:
  - websocket-size-limit

tags:
  - traffic-control
  - websocket

related_resources:
  - text: WebSocket Validator plugin
    url: /plugins/websocket-validator/
  - text: WebSocket RFC
    url: https://datatracker.ietf.org/doc/html/rfc6455
---

Allows operators to specify a maximum size for incoming WebSocket messages.

Separate limits can be applied to clients and upstreams.

When an incoming message exceeds the limit:
1. A close frame with status code `1009` is sent to the sender
2. A close frame with status code `1001` is sent to the peer
3. Both sides of the connection are closed

## How it works

Size limits can be applied to client messages, upstream messages, or both.
Limits are evaluated based on the message payload length, and not the entire length of the WebSocket frame (header and payload).

### Default limits

{{site.base_gateway}} applies the following default limits to incoming messages for all WebSocket services:
* Client: `1048576` (`1MiB`) 
* Upstream: `16777216` (`16MiB`)

This plugin can be used to increase the limit beyond the default using the [`config.client_max_payload`](/plugins/websocket-size-limit/reference/#schema--config-client-max-payload) and 
[`config.upstream_max_payload`](/plugins/websocket-size-limit/reference/#schema--config-upstream-max-payload) parameters.

The default client limit is smaller than the default upstream limit because proxying client-originated messages is much more computationally expensive than upstream messages.
This is due to the client-to-server masking required by the [WebSocket specification](https://datatracker.ietf.org/doc/html/rfc6455#section-5.3), 
so it's generally better to maintain a lower limit for client messages.

### Standalone data frames (text and binary)

For limits of 125 bytes or less, the message length is checked after reading and decoding the entire message into memory.

For limits of 126 bytes or more, the message length is checked from the frame header _before_ the entire message is read from the socket buffer,
allowing {{site.base_gateway}} to close the connection without having to read, and potentially unmask, the entire message into memory.

### Continuation data frames

{{site.base_gateway}} aggregates `continuation` frames, buffering them in-memory before forwarding them to their final destination.
In addition to evaluating limits on an individual frame basis, like singular `text` and `binary` frames, {{site.base_gateway}}
also tracks the running size of all the frames that are buffered for aggregation. 
If an incoming `continuation` frame causes the total buffer size to exceed the limit, the message is rejected, and the connection is closed.

For example, assuming `client_max_payload = 1024`:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
autonumber
    participant Client 
    participant Kong as Kong Gateway

    activate Client
    activate Kong
    Client->>Kong: text(fin=false, len=500, msg=[...])
    note right of Kong: buffer += 500 (500)
    Client->>Kong: continue(fin=false, len=500, msg=[...])
    note right of Kong: buffer += 500 (1000)
    Client->>Kong: continue(fin=false, len=500, msg=[...])
    note right of Kong: buffer += 500 (1500) <br> buffer >= 1024 (limit exceeded!)
    Kong->>Client: close(status=1009, msg="Payload Too Large")
    deactivate Kong
    deactivate Client
{% endmermaid %}
<!--vale on-->

### Control frames

All control frames (`ping`, `pong`, and `close`) have a max payload size of `125` bytes, as per the WebSocket
[specification](https://datatracker.ietf.org/doc/html/rfc6455#section-5.5). 
{{site.base_gateway}} does not enforce any limits on control frames, even when they're set to a value lower than `125`.
