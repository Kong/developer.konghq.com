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
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: Autogenerate serverless MCP
    url: /mcp/autogenerate-mcp-tools/
  - text: All {{site.ai_gateway}} plugins
    url: /plugins/?category=ai
  - text: Kong MCP traffic gateway
    url: /mcp/
    icon: /assets/icons/mcp.svg
  - text: Autogenerate MCP tools from a RESTful API
    url: /mcp/autogenerate-mcp-tools/
  - text: Autogenerate MCP tools for Weather API
    url: /mcp/weather-mcp-api/
  - text: Control MCP tool access with Consumer and Consumer Group ACLs
    url: /mcp/use-access-controls-for-mcp-tools/
  - text: Enforce ACLs on aggregated MCP servers
    url: /mcp/enforce-acls-on-aggregated-mcp-servers/
  - text: MCP Registry in {{site.konnect_short_name}} (tech preview)
    url: /catalog/mcp-registry/

examples_groups:
  - slug: basic
    text: Basic use cases
  - slug: mcp-acls
    text: MCP ACLs

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
faqs:
  - q: Which MCP protocol version does the AI MCP Proxy plugin use?
    a: The AI MCP Proxy plugin uses MCP protocol version 2025-06-18.

  - q: What MCP protocol versions are supported for upstream MCP servers?
    a: |
      The AI MCP Proxy plugin supports these upstream MCP server protocol versions:
      * 2025-06-18
      * 2025-11-25

      Versions from 2024 are not supported.

next_steps:
  - text: Learn about Kong MCP traffic gateway
    url: /mcp/
  - text: Learn about {{site.konnect_product_name}} MCP Server
    url: /mcp/kong-mcp/get-started/
  - text: Autogenerate MCP tools from a RESTful API
    url: /mcp/autogenerate-mcp-tools/
  - text: Autogenerate MCP tools for Weather API
    url: /mcp/autogenerate-mcp-tools-for-weather-api/
  - text: Control MCP tool access with Consumer and Consumer Group ACLs
    url: /mcp/use-access-controls-for-mcp-tools/
  - text: Enforce ACLs on aggregated MCP servers
    url: /mcp/enforce-acls-on-aggregated-mcp-servers/
---
The AI MCP Proxy plugin lets you connect any Kong-managed Service to the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). It acts as a **protocol bridge**, translating between MCP and HTTP so that MCP-compatible clients can either call existing APIs or interact with upstream MCP servers through Kong.

The plugin’s `mode` parameter controls whether it proxies MCP requests, converts RESTful APIs into MCP tools, or exposes grouped tools as an MCP server. This flexibility allows you to integrate existing HTTP APIs into MCP workflows, front third-party MCP servers with Kong’s policies, or expose multiple tool sets as a managed MCP server.

Because the plugin runs directly on {{site.ai_gateway}}, MCP endpoints are provisioned dynamically on demand. You don’t need to host or scale them separately, and the {{site.ai_gateway}} applies its authentication, traffic control, and observability features to MCP traffic at the same scale it delivers for traditional APIs.

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
> Pings from your MCP client are included in the total request count for your {{site.ai_gateway}} instance, in addition to the requests made to the MCP server.

## Prerequisites

{:.warning}
> Before using the AI MCP Proxy plugin, ensure your setup meets these requirements:
> - The upstream Service exposes a valid OpenAPI schema.
> - That Service is configured and accessible in Kong.
> - An MCP-compatible client (such as [Insomnia](https://konghq.com/products/kong-insomnia), [Claude](https://claude.ai/), [Cursor](https://cursor.com/), or [LMstudio](https://lmstudio.ai/)) is available to connect to Kong.
> - The {{site.ai_gateway}} instance supports the AI MCP Proxy plugin (is 3.12 or higher).

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
      You can define tools directly in the plugin configuration and optionally set a server block.<br/><br/>
      {% new_in 3.13 %} The conversion-listener mode also supports adding session identifiers set by authentication services in the configuration parameters. See the [cookie conversion example](./examples/conversion-listener/) for details on handling cookie-based authentication.
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

## ACL tool control {% new_in 3.13 %}

When exposing MCP servers through {{site.base_gateway}}, you may need granular control over which authenticated API consumers can discover and invoke specific tools. The AI MCP Proxy plugin's ACL feature lets you define access rules at both the default level (applying to all tools) and per-tool level (for fine-grained exceptions)

This way, consumers only interact with tools appropriate to their role, while maintaining a complete audit trail of all access attempts. Authentication is handled by standard Kong AuthN plugins (for example, [Key Auth](/plugins/key-auth/) or OIDC flows), and the resulting Consumer identity is used for ACL checks.

{:.info}
> **ACL in `listener` mode**
>
> Listener mode does not support direct ACL configuration. Instead, it inherits ACL rules from tagged conversion-listener or conversion-only plugins.
>
> To use ACLs with `listener` mode:
> 1. Configure conversion-listener or conversion-only plugins with ACL rules and tags.
> 2. Configure listener mode to aggregate tools by matching tags.
> 3. Set `include_consumer_groups: true` on the listener. Without this setting, the listener cannot pass Consumer Group membership to the aggregated tools, and ACL rules will not evaluate correctly.
>
> See [Enforce ACLs on aggregated MCP servers](/mcp/enforce-acls-on-aggregated-mcp-servers/) for a complete example.

### Supported identifier types

ACL rules can reference [Consumers](/gateway/entities/consumer/) and [Consumer Groups](/gateway/entities/consumer-group/) using these identifier types in `allow` and `deny` lists:

* [`username`](/gateway/entities/consumer/#schema-consumer-username): Consumer username
* [`id`](/gateway/entities/consumer/#schema-consumer-username): Consumer UUID
* [`custom_id`](/gateway/entities/consumer/#schema-consumer-custom-id): Custom Consumer identifier
* [`consumer_groups.name`](/gateway/entities/consumer/#schema-consumer-custom-id): Consumer Group name

The authenticated Consumer identity is matched against these identifiers. If the [Consumer](/gateway/entities/consumer/) or any of their [Consumer Groups](/gateway/entities/consumer-group/) match an ACL entry, the rule applies.

### How default and per-tool ACLs work

The plugin evaluates access using a two-tier system:

<!-- vale off -->
{% table %}
columns:
  - title: ACL type
    key: field
  - title: Description
    key: description
rows:
  - field: |
      [`default_acl`](./reference/#schema--config-default-acl)
    description: |
      Baseline rules that apply to all tools unless overridden.
  - field: |
      [`tools[].acl`](./reference/#schema--config-tools-acl)
    description: |
      When configured, these rules replace the default ACL for that specific tool. The per-tool ACL doesn't inherit or merge with `default_acl`—it is an all-or-nothing override.
{% endtable %}
<!-- vale on -->

{:.info}
> If a tool defines its own ACL, the plugin ignores `default_acl` for that tool:
>
> - Tools with no ACL configuration inherit the default rules (both `allow` and `deny` lists)
> - Tools with an ACL must explicitly list all allowed subjects (even if they were already in `default_acl`)

### ACL evaluation logic

Both default and per-tool ACLs use `allow` and `deny` lists. Evaluation follows this order:

1. **Deny list configuration**: If a `deny` list exists and the subject matches any `deny` entry, the request is rejected (`INVALID_PARAMS -32602`).
2. **Allow list configuration**: If an `allow` list exists, the subject must match at least one entry; otherwise, the request is denied (`INVALID_PARAMS -32602`).
3. **No allow list configuration**: If no `allow` list exists and the subject is not in `deny`, the request is allowed.
4. **No ACL configuration**: If neither list exists, the request is allowed.

All access attempts (allowed or denied) are written to the plugin's audit log.

The table below summarizes the possible ACL configurations and their outcomes.

{% table %}
columns:
  - title: Condition
    key: condition
  - title: "Proxied to upstream service?"
    key: proxy
  - title: Response code
    key: response
rows:
  - condition: "Subject matches any `deny` rule"
    proxy: No
    response: INVALID_PARAMS -32602
  - condition: "`allow` list exists and subject is not in it"
    proxy: No
    response: INVALID_PARAMS -32602
  - condition: "Only `deny` list exists and subject is not in it"
    proxy: Yes
    response: 200
  - condition: "No ACL rules configured"
    proxy: Yes
    response: 200
{% endtable %}

### ACL tool control request flow

The AI MCP Proxy plugin evaluates ACLs for both tool discovery and tool invocation. These are two distinct operations with different behaviors:

**Tool Discovery (List tools)**:
1. MCP client requests the list of available tools
2. Kong AuthN plugin validates the request and identifies the Consumer
3. AI MCP Proxy loads the Consumer's group memberships
4. Plugin evaluates each tool against the `default_acl`
5. Plugin returns an HTTP 200 response with only the tools the Consumer is allowed to access
6. Plugin logs the discovery attempt

**Tool invocation**:
1. MCP client invokes a specific tool
2. Kong AuthN plugin validates the request and identifies the Consumer
3. AI MCP Proxy loads the Consumer's group memberships
4. Plugin evaluates the tool-specific ACL if it exists, or the default ACL otherwise
5. Plugin logs the access attempt (allowed or denied)
6. Plugin returns `INVALID_PARAMS -32602` if denied, or forwards the request to the upstream MCP server if allowed

<!-- vale off -->
{% mermaid %}
sequenceDiagram
  participant Client as MCP Client
  participant Kong as Kong Gateway
  participant Auth as AuthN Plugin
  participant ACL as ai-mcp-proxy (ACL/Audit)
  participant Up as Upstream MCP Server
  participant Log as Audit Sink

  %% ----- List Tools -----
  rect
    note over Client,Kong: List Tools (Default ACL Scope)
    Client->>Kong: GET /tools
    Kong->>Auth: Authenticate
    Auth-->>Kong: Consumer identity
    Kong->>ACL: Evaluate scoped default ACL
    ACL-->>Log: Audit entry
    alt If allowed
      Kong-->>Client: Filtered tool list
    else If denied
      Kong-->>Client: INVALID_PARAMS -32602
    end
  end

  %% ----- Tool Invocation -----
  rect
    note over Client,Up: Tool Invocation (Per-tool ACL)
    Client->>Kong: POST /tools/{tool}
    Kong->>Auth: Authenticate
    Auth-->>Kong: Consumer identity
    Kong->>ACL: Evaluate per-tool ACL
    ACL-->>Log: Audit entry
    alt If allowed
      Kong->>Up: Forward request
      Up-->>Kong: Response
      Kong-->>Client: Response
    else If denied
      Kong-->>Client: INVALID_PARAMS -32602
    end
  end
{% endmermaid %}
<!-- vale on -->

## Migration path

For users already using the AI MCP Proxy plugin without ACL configuration, follow these steps to add ACL tool control:
1. **Add an AuthN plugin**: Enable an authentication plugin such as [Key Auth](/plugins/key-auth/) to work with Consumers and Consumer Groups.
2. **Add ACL fields to the plugin configuration**: Update the AI MCP Proxy plugin schema to include `default_acl` and per-tool `acl` fields.
3. **Configure ACL rules**: Add `allow` and `deny` lists to control access at the default and per-tool levels.
4. **Enable audit logging**: Set `logging.log_audits: true` to monitor access attempts and verify ACL enforcement.

## Scope of support

The AI MCP Proxy plugin provides support for MCP operations and upstream interactions, while certain advanced features and non-HTTP protocols are not currently supported. The table below summarizes what is supported and what is outside the current scope.

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