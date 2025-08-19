---
title: 'AI MCP'
name: 'AI MCP'

content_type: plugin
tier: ai_gateway_enterprise
publisher: kong-inc
description: Convert any API into a working MCP server
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

icon: ai-prompt-compressor.png

categories:
  - ai

tags:
  - ai
  - mcp

related_resources:
  - text: About AI Gateway
    url: /ai-gateway/
  - text: Autogenerate serverless MCP
    url: /mcp/autogenerate-serverless-mcp-tools/
  - text: All AI Gateway plugins
    url: /plugins/?category=ai
  - text: Kong MCP traffic gateway
    url: /mcp/
    icon: /assets/icons/mcp.svg
  - text: Autogenerate MCP tools from a RESTful API
    url: /mcp/autogenerate-serverless-mcp-tools/
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
    url: /mcp/autogenerate-serverless-mcp-tools/
  - text: Autogenerate MCP tools for Weather API
    url: /mcp/autogenerate-mcp-tools-for-weather-api/
---
The **AI MCP** plugin lets you expose any Kong-managed Service as a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server. It acts as a **protocol bridge**, translating between MCP and HTTP so that MCP-compatible clients can call existing APIs without custom server code.

Instead of building an MCP server from scratch, you provide the plugin with an **OpenAPI-compatible schema** for your upstream Service. The plugin uses this schema to understand the available operations and automatically generate MCP tool definitions. This allows you to make *any* HTTP API part of an MCP workflow, while still leveraging Kong’s plugin ecosystem for authentication, traffic control, and observability.

Because the plugin runs directly on Kong AI Gateway, MCP servers are provisioned dynamically on demand. You don’t need to host or scale them separately, and the Gateway’s performance allows a single node to handle hundreds of thousands of requests per second—your upstream APIs will reach their limits before Kong AI Gateway does.

## Why use the AI MCP plugin

The AI MCP bridges the Kong plugin ecosystem with the MCP world, enabling you to bring all of Kong's traffic management, security, and observability capabilities to MCP endpoints:

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

The AI MCP plugin handles MCP requests by converting them into standard HTTP calls and returning the responses in MCP format. The flow works as follows:

1. Accepts MCP protocol requests from a client.
2. Parses the MCP tool call and matches it to an OpenAPI operation.
3. Converts the operation into a standard HTTP request.
4. Sends the request to the upstream Service.
5. Wraps the HTTP response in MCP-compatible format and returns it.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as Kong (AI MCP plugin)
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

## Prerequisites

{:.warning}
> Before using the AI MCP plugin, ensure your setup meets these requirements:
> The upstream Service exposes a valid OpenAPI schema.
> That Service is configured and accessible in Kong.
> An MCP-compatible client is available to connect to Kong.
> The Kong AI Gateway instance supports the AI MCP plugin (is 3.12 or higher)

## Configuration modes

The AI MCP plugin can be configured to operate in two distinct modes, depending on whether you want to expose individual tools or run a full MCP Server on a Route. Each mode offers different capabilities and use cases, which allows you to adapt the plugin behavior to your service architecture and workflow requirements.

<!-- vale off -->
{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
  - title: Variants
    key: variants
rows:
  - mode: Tool mode
    description: |
      Attaches an OpenAPI spec and tool metadata to a Service.
      Makes the Service available as a tool definition within an MCP Server.
    variants: N/A
  - mode: Server mode
    description: |
      Enables an MCP Server on the associated Route and Service.
    variants: |
      - **One-to-many** — Expose multiple tools through the same MCP Server.
      - **One-to-one** — Serve MCP protocol and traditional HTTP on the same Route.
{% endtable %}
<!-- vale on -->

## Scope of support

The AI MCP plugin provides support for key MCP operations and upstream interactions, while certain advanced features and non-HTTP protocols are not currently supported. The table below summarizes what is fully supported and what is outside the current scope.

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
  - title: "SNI routing"
    description: Converting SNI-only routes
    supported: false
  - title: "Non-JSON formats"
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



