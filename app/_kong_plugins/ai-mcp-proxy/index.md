---
title: 'AI MCP Proxy'
name: 'AI MCP Proxy'

content_type: plugin
tier: ai_gateway_enterprise
publisher: kong-inc
description: |
    Convert APIs into MCP tools, proxy MCP servers, expose multiple MCP tools for AI clients, and observe MCP traffic in real time.
breadcrumbs:
 - /ai-gateway/
 - /mcp/
products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-mcp-proxy.png

categories:
  - ai

tags:
  - ai
  - mcp

related_resources:
  - text: About AI Gateway
    url: /ai-gateway/
  - text: Autogenerate serverless MCP
    url: /mcp/autogenerate-mcp-tools/
  - text: All AI Gateway plugins
    url: /plugins/?category=ai
  - text: Kong MCP traffic gateway
    url: /mcp/
    icon: /assets/icons/mcp.svg
  - text: Autogenerate MCP tools from a RESTful API
    url: /mcp/autogenerate-mcp-tools/
  - text: Autogenerate MCP tools for Weather API
    url: /mcp/weather-mcp-api/

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

next_steps:
  - text: Learn about Kong MCP traffic gateway
    url: /mcp/
  - text: Learn about {{site.konnect_product_name}} MCP Server
    url: /mcp/kong-mcp/get-started/
  - text: Autogenerate MCP tools from a RESTful API
    url: /mcp/autogenerate-mcp-tools/
  - text: Autogenerate MCP tools for Weather API
    url: /mcp/autogenerate-mcp-tools-for-weather-api/
---
The AI MCP Proxy plugin lets you connect any Kong-managed Service to the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). It acts as a **protocol bridge**, translating between MCP and HTTP so that MCP-compatible clients can either call existing APIs or interact with upstream MCP servers through Kong.

The plugin’s `mode` parameter controls whether it proxies MCP requests, converts RESTful APIs into MCP tools, or exposes grouped tools as an MCP server. This flexibility allows you to integrate existing HTTP APIs into MCP workflows, front third-party MCP servers with Kong’s policies, or expose multiple tool sets as a managed MCP server.

Because the plugin runs directly on Kong AI Gateway, MCP endpoints are provisioned dynamically on demand. You don’t need to host or scale them separately, and the Kong AI Gateway applies its authentication, traffic control, and observability features to MCP traffic at the same scale it delivers for traditional APIs.

{:.warning}
> **Note:** Unlike other available AI plugins, the AI MCP Proxy plugin is not invoked as part of an LLM request flow.
> Instead, it's part of an MCP request flow. It's registered and executed as a regular plugin, between the MCP client and the MCP server, allowing it to capture MCP traffic independently of LLM request flow.
>
> **Do not configure the AI MCP Proxy plugin together with other AI plugins on the same Service or Route**.

## Why use the AI MCP Proxy plugin

The AI MCP Proxy bridges the Kong plugin ecosystem with the MCP world, enabling you to bring all of Kong's traffic management, security, and observability capabilities to MCP endpoints:

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Example
    key: example
rows:
  - use_case: Authentication
    example: |
      Apply [OpenID Connect](/plugins/openid-connect/) or the [Key Auth](/plugins/key-auth/) plugin to an MCP Server
  - use_case: Rate limiting
    example: |
      Use [Rate Limiting](/plugins/rate-limiting/) or [Rate Limiting Advanced](/plugins/rate-limiting-advanced) plugins to control MCP request volume
  - use_case: Observability
    example: |
      Add [logging and tracing plugins](/plugins/?category=logging) for full request and response visibility
  - use_case: Traffic control
    example: |
      Apply [request/response transformation plugins](/plugins/?category=transformations) or [ACL policies](/plugins/acl/)
{% endtable %}
<!-- vale on -->

## How it works

The AI MCP Proxy plugin handles MCP requests by converting them into standard HTTP calls and returning the responses in MCP format. The flow works as follows:

1. Accepts MCP protocol requests from a client.
2. Parses the MCP tool call and matches it to an OpenAPI operation.
3. Converts the operation into a standard HTTP request.
4. Sends the request to the upstream Service.
5. Wraps the HTTP response in MCP-compatible format and returns it.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as Kong (AI MCP Proxy plugin)
    participant U as Upstream Service

    C->>K: MCP request (tool invocation)
    activate K
    K->>K: Parse MCP payload
    K->>K: Map to HTTP endpoint (OpenAPI schema)
    K->>U: HTTP request
    deactivate K
    activate U
    U-->>K: HTTP response
    deactivate U
    activate K
    K->>K: Convert to MCP format
    K-->>C: MCP response
    deactivate K
{% endmermaid %}
<!-- vale on -->

{:.info}
> Pings from your MCP client are included in the total request count for your Kong AI Gateway instance, in addition to the requests made to the MCP server.

## Prerequisites

{:.warning}
> Before using the AI MCP Proxy plugin, ensure your setup meets these requirements:
> - The upstream Service exposes a valid OpenAPI schema.
> - That Service is configured and accessible in Kong.
> - An MCP-compatible client (such as [Insomnia](https://konghq.com/products/kong-insomnia), [Claude](https://claude.ai/), [Cursor](https://cursor.com/), or [LMstudio](https://lmstudio.ai/)) is available to connect to Kong.
> - The Kong AI Gateway instance supports the AI MCP Proxy plugin (is 3.12 or higher).

## Configuration modes

The AI MCP Proxy plugin operates in four modes, controlled by the [`config.mode`](./reference/#schema--config-mode) parameter. Each mode determines how Kong handles MCP requests and whether it converts RESTful APIs into MCP tools.

<!-- vale off -->
{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
  - title: Use cases
    key: usecase
rows:
  - mode: |
      [`passthrough-listener`](./examples/passthrough-listener/)
    description: |
      Listens for incoming MCP requests and proxies them to the `upstream_url` of the Gateway Service.
      Generates MCP observability metrics for traffic, making it suitable for third-party MCP servers hosted by users.
    usecase: |
      Use when you already operate an MCP server and want {{site.base_gateway}} to act as an authenticated, observable entrypoint for it.
      Useful for exposing a third-party or internally hosted MCP service through {{site.base_gateway}}.
  - mode: |
      [`conversion-listener`](./examples/conversion-listener/)
    description: |
      Converts RESTful API paths into MCP tools **and** accepts incoming MCP requests on the Route path.
      You can define tools directly in the plugin configuration and optionally set a server block.
    usecase: |
      Use when you want to make an existing REST API available to MCP clients directly through {{site.base_gateway}}.
      Common for services that both define and handle their own tools.
  - mode: |
      [`conversion-only`](./examples/conversion-only/)
    description: |
      Converts RESTful API paths into MCP tools but does **not** accept incoming MCP requests.
      `tags` can be defined at the plugin level and are used by `listener` plugins to expose the tools. This mode does not define a server.<br/><br/>

      This mode must be used together with other AI MCP Proxy plugins configured with the `listener` mode.
    usecase: |
      Use when you want to define reusable tool specifications without serving them.
      Suitable for teams that maintain a shared library of tool definitions for other listener plugins.
  - mode: |
      [`listener`](./examples/listener/)
    description: |
      Similar to `conversion-listener`, but instead of defining its own tools, it binds multiple `conversion-only` tools using the [`config.server.tag`](./reference/#schema--config-server-tag) property.
      `conversion-only` plugins define `tags` at the plugin level, and the listener connects to them to expose the tools on a Route for incoming MCP requests.<br/><br/>

      This mode must be used together with other AI MCP Proxy plugins configured with the `conversion-only` mode.
    usecase: |
      Use when you need a single MCP endpoint that aggregates tools from multiple `conversion-only` plugins.
      Typical in multi-service or multi-team environments that expose a unified MCP interface.
{% endtable %}
<!-- vale on -->



## Scope of support

The AI MCP Proxy plugin provides support for key MCP operations and upstream interactions, while certain advanced features and non-HTTP protocols are not currently supported. The table below summarizes what is fully supported and what is outside the current scope.

<!-- vale off -->
{% feature_table %}
item_title: Features
columns:
  - title: Description
    key: description
  - title: Supported
    key: supported

features:
  - title: "Protocol"
    description: Handling latest streamable HTTP with HTTP and HTTPS upstreams
    supported: true
  - title: "OpenAPI operations"
    description: Mapping MCP calls to upstream HTTP operations based on the OpenAPI schema
    supported: true
  - title: "JSON format"
    description: Handling standard JSON request and response bodies
    supported: true
  - title: "Form-encoded data"
    description: Handling `application/x-www-form-urlencoded`
    supported: true
  - title: "SNI routing"
    description: Converting SNI-only routes
    supported: false
  - title: "Form and XML data"
    description: Handling formats such as multipart/form-data or XML
    supported: false
  - title: "Advanced MCP features"
    description: Handling structured output, active notifications on tool changes, and session sharing between instances
    supported: false
  - title: "Non-HTTP protocols"
    description: Handling WebSocket and gRPC upstreams
    supported: false
  - title: "AI Guardrails"
    description: Applying guardrails to MCP AI plugin requests and responses
    supported: false
{% endfeature_table %}
<!-- vale on -->



