---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Add a unique ID header to requests sent to your AI Models, AI Agents, and AI MCP Servers, so you can trace a request through your upstream services and logs.'
categories:
  - transformations
tags:
  - ai
search_aliases:
  - correlation-id
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
---

The Correlation ID [AI Policy](/ai-gateway/entities/ai-policy/) adds a unique ID to each request that {{site.ai_gateway}} sends to your [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/).
When a request passes through several systems, the ID lets you find the matching entries in each system's logs and trace a single request from the client to your upstream service.

## How does the Correlation ID Policy work?

The Correlation ID Policy adds an HTTP header to every request it processes.
The header name comes from [`config.header_name`](/ai-gateway/policies/correlation-id/reference/#schema--config-header-name), and the value comes from the [`config.generator`](/ai-gateway/policies/correlation-id/reference/#schema--config-generator) you choose.
{{site.ai_gateway}} adds the header to the request that it sends to the upstream service of the AI Model, AI Agent, or AI MCP Server.

By default, {{site.ai_gateway}} returns the header only to the upstream service.
Set [`config.echo_downstream`](/ai-gateway/policies/correlation-id/reference/#schema--config-echo-downstream) to `true` to also return the header in the response to the client.
The client then receives the same value that your upstream service received.

If the client request already contains a header with the same name, the policy keeps the client's value.

The following example adds a `uuid` ID to every request and returns it to the client:

{% entity_example %}
type: policy
data:
  name: correlation-id-uuid
  display_name: Correlation ID with UUID
  type: correlation-id
  global: true
  config:
    header_name: Kong-Request-ID
    generator: uuid
    echo_downstream: true
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Use cases

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: How the Correlation ID Policy helps
    key: help
rows:
  - use_case: Trace a request across systems
    help: The upstream service receives the same ID as the client, so you can find the matching log entries in each system.
  - use_case: Give clients an ID for support requests
    help: Set [`config.echo_downstream`](/ai-gateway/policies/correlation-id/reference/#schema--config-echo-downstream) to `true` so the client receives the ID in the response and can quote it in a support request.
  - use_case: Continue an ID from your own application
    help: The policy keeps the value of a header that the client already sends, so an ID that your application or front door creates stays the same through {{site.ai_gateway}}.
  - use_case: Match the header name your stack expects
    help: Set [`config.header_name`](/ai-gateway/policies/correlation-id/reference/#schema--config-header-name) to the name that your upstream service or log pipeline uses, for example `X-Correlation-ID`.
  - use_case: Choose the ID format
    help: Set [`config.generator`](/ai-gateway/policies/correlation-id/reference/#schema--config-generator) to `uuid`, `uuid#counter`, or `tracker`. See [Generators](#generators).
{% endtable %}
<!--vale on-->

## Generators

The generator determines the format of the ID.
Choose a generator with [`config.generator`](/ai-gateway/policies/correlation-id/reference/#schema--config-generator).
The default is `uuid#counter`.

### uuid

The `uuid` generator creates a new hexadecimal UUID for each request.

```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### uuid#counter

The `uuid#counter` generator creates one UUID for each worker process.
Each request then appends a counter to the UUID after a `#` character.
The counter increases by one for each request that worker handles, independently of the other workers.
Requests handled by different workers therefore have different UUIDs.

```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx#counter
```

Because many requests share the same UUID, the IDs have low cardinality.

### tracker

The `tracker` generator creates an ID from details of the connection and the request.

```
ip-port-pid-connection-connection_requests-timestamp
```

The following table describes each field:

{% table %}
columns:
  - title: Field
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: "`ip`"
    description: Address of the server that accepts a request.
  - parameter: "`port`"
    description: Port of the server that accepts a request.
  - parameter: "`pid`"
    description: Process ID.
  - parameter: "`connection`"
    description: Connection serial number.
  - parameter: "`connection_requests`"
    description: Current number of requests made through a connection.
  - parameter: "`timestamp`"
    description: A floating-point number for the elapsed time in seconds, including milliseconds as the decimal part, from the epoch for the current time.
{% endtable %}

## Choose a generator

Use `uuid` when you need a different, unrelated ID for every request.
Use `uuid#counter` (the default) when grouping requests by worker is acceptable, because requests handled by the same worker share a UUID.
Use `tracker` when you want the ID to carry connection details, such as the server address, port, and connection number.

## Scopes

The Correlation ID Policy supports the following scopes:

* [AI Model](/ai-gateway/entities/ai-model/)
* [AI Agent](/ai-gateway/entities/ai-agent/)
* [AI MCP Server](/ai-gateway/entities/ai-mcp-server/)
* [AI Consumer](/ai-gateway/entities/ai-consumer/)
* [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)
* Global

Apply the policy globally to add an ID to all traffic that passes through {{site.ai_gateway}}, including requests to AI Models, AI Agents, and AI MCP Servers that you didn't attach the policy to.
Attach it to a single entity to add an ID only to that entity's requests.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

To limit a global policy to specific requests, add a [`condition`](/ai-gateway/entities/ai-policy/#conditional-ai-policy-execution) to the policy.
For example, the condition `http.headers.x_trace == "1"` adds the ID only to requests that carry the header `x-trace: 1`.

## Limitations

- When a client calls a tool on an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) of type `conversion-listener`, {{site.ai_gateway}} doesn't add the header to the REST request that it sends to the upstream service. The server sends that request back through {{site.ai_gateway}} as a new request, which doesn't carry the generated ID. With `config.echo_downstream` set to `true`, the client still receives the header in the response. For AI Models and AI Agents, the header is added to the upstream request.
