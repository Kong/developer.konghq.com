---
title: AI MCP Servers
content_type: reference
entities:
  - ai-mcp-server
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-mcp-server/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: AI MCP Server entity used by {{site.ai_gateway}} to expose tools and proxy MCP traffic.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayMCPServer
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: Kong MCP traffic gateway
    url: /mcp/
  - text: Model Context Protocol specification
    url: https://modelcontextprotocol.io/
faqs:
  - q: Which MCP protocol version does the runtime use?
    a: |
      The MCP runtime behind an AI MCP Server entity speaks MCP protocol version `2025-06-18`. Upstream
      MCP servers may run `2025-06-18` or `2025-11-25`. Versions from 2024 are not supported.

  - q: What's the difference between the server types?
    a: |
      `passthrough-listener` proxies MCP traffic to an upstream MCP server without converting tools.
      `conversion-listener` converts a RESTful API into MCP tools and accepts MCP requests on the
      same Route. `conversion-only` defines a tool library that other MCP Servers reference by tag
      but doesn't accept incoming MCP traffic itself. `listener` aggregates tools from one or more
      `conversion-only` MCP Servers into a single MCP endpoint. `upstream-server` registers a real
      MCP server into an aggregation pool, dynamically fetching its tools for a `listener` to aggregate.

  - q: Can the same AI Consumer's identity gate access to specific tools?
    a: |
      Yes. Set [`default_tool_acls`](#schema-aigateway-mcpserver-default-tool-acls) on the AI MCP Server with `allow` and `deny` lists, and override per
      tool through [`tools[].acls`](#schema-aigateway-mcpserver-tools-acls). A per-tool ACL replaces the default for that tool, it doesn't
      merge.

  - q: How do OAuth-based ACLs differ from AI Consumer-based ACLs?
    a: |
      Set [`acl_attribute_type`](#schema-aigateway-mcpserver-acl-attribute-type) to `oauth_access_token` and provide [`access_token_claim_field`](#schema-aigateway-mcpserver-access-token-claim-field) (a jq
      filter, for example `.user.email`). ACLs then evaluate against the claim value extracted from
      the OAuth access token instead of the resolved Consumer identity. The OAuth flow is supplied
      by the [AI MCP OAuth2 Policy](/ai-gateway/policies/ai-mcp-oauth2/).

  - q: What error code do denied requests return?
    a: |
      `HTTP 403 Forbidden`. Earlier {{site.ai_gateway}} versions returned the JSON-RPC error code
      `INVALID_PARAMS -32602`; from {{site.ai_gateway}} 3.14 onward, denials follow the
      [MCP 2025-11-25 authorization specification](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization#error-handling).

  - q: Can I attach the same authentication or rate-limiting policy that I'd attach to a Route?
    a: |
      Policy configuration that applies to the AI MCP Server goes through the
      [AI Policy entity](/ai-gateway/entities/ai-policy/). Attach Policies to the AI MCP Server through its
      [`policies`](#schema-aigateway-mcpserver-policies) field.
---

## What is an AI MCP Server?

Create an AI MCP Server to connect AI applications such as [Claude](https://claude.ai/), [Cursor](https://cursor.com/), or [Insomnia](/insomnia/) to your APIs and tools through the standardized [Model Context Protocol](https://modelcontextprotocol.io/). An AI MCP Server acts as a bridge between MCP-compatible clients and your backend systems, allowing you to expose existing APIs as discoverable tools without building custom integrations for each AI client.

Because MCP endpoints run directly on {{site.ai_gateway}}, you don't need to host and scale MCP infrastructure separately. The same authentication, rate limiting, and observability you apply to traditional API traffic automatically covers MCP traffic, giving you consistent governance across both HTTP and MCP clients.

{:.warning}
> **Note:** AI MCP Servers handle MCP request flows, not LLM request flows. [AI Policies](/ai-gateway/entities/ai-policy/) attached to an AI MCP Server apply only to MCP traffic. Policies designed for LLM model requests won't apply here.

## Manage AI MCP Servers

AI MCP Servers can be created and managed through the:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/mcp-servers`

For configuration examples and step-by-step setup instructions, see [Set up an AI MCP Server](#set-up-an-ai-mcp-server).

## MCP server governance

Attach [AI Policies](/ai-gateway/entities/ai-policy/) to your AI MCP Server to govern them:

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Policy
    key: example
rows:
  - use_case: "Secure MCP endpoints with credentials or OAuth tokens"
    example: "[AI Key Auth](/ai-gateway/policies/ai-key-auth/reference/) or [AI OpenID Connect](/ai-gateway/policies/ai-openid-connect/reference/) Policy"
  - use_case: "Rate limiting"
    example: "Use [AI Rate Limiting](/ai-gateway/policies/ai-rate-limiting/) or [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to control MCP request volume per AI Consumer or Consumer Group."
  - use_case: "Observability"
    example: "Enable request and response logging through [AI Policies](/ai-gateway/policies/?category=logging) and audit trails to track all MCP traffic and ACL decisions."
  - use_case: "Traffic control"
    example: "Apply [AI Request Transformer](/ai-gateway/policies/ai-request-transformer/) or [AI Response Transformer](/ai-gateway/policies/ai-response-transformer/) Policy to modify MCP payloads, or use [ACLs](#acl-tool-control) for fine-grained tool access."
{% endtable %}
<!-- vale on -->

## Server modes

{{site.ai_gateway}} supports five server modes for different integration patterns: exposing REST APIs as discoverable MCP tools, proxying requests to existing MCP servers with added authentication and observability, or aggregating tools from multiple sources into a single endpoint. Select the mode that fits your use case using the [`type`](#schema-aigateway-mcpserver-type) field.

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
  - mode: "`passthrough-listener`"
    description: |
      Listens for incoming MCP requests and proxies them to an upstream MCP server without
      converting tools. Generates MCP observability metrics.
    usecase: |
      You already operate an MCP server and want {{site.ai_gateway}} to act as an authenticated,
      observable entrypoint. Common for third-party or internally hosted MCP services exposed
      through {{site.ai_gateway}}.
  - mode: "`conversion-listener`"
    description: |
      Converts RESTful API paths into MCP tools and accepts incoming MCP requests on the Route
      path. Tools are defined directly on the MCP Server and an optional server block applies.
      Supports session identifiers set by authentication services for cookie-based
      authentication.
    usecase: |
      Make an existing REST API available to MCP clients directly through {{site.ai_gateway}}.
      Common for services that both define and handle their own tools.
  - mode: "`conversion-only`"
    description: |
      Converts RESTful API paths into MCP tools but does not accept incoming MCP requests.
      Tools are tagged at the MCP Server level so a `listener` MCP Server can reference them.
      Used together with one or more `listener` MCP Servers.
    usecase: |
      Define reusable tool specifications without serving them. Suitable for teams that maintain
      a shared library of tool definitions.
  - mode: "`listener`"
    description: |
      Similar to `conversion-listener`, but instead of defining its own tools, it binds tools
      from one or more `conversion-only` or `upstream-server` MCP Servers through `config.server.tag`.
    usecase: |
      A single MCP endpoint that aggregates tools from multiple `conversion-only` or `upstream-server` MCP Servers.
      Typical in multi-service or multi-team environments that expose a unified MCP interface.
  - mode: "`upstream-server`"
    description: |
      Registers a real MCP server into an aggregation pool. Dynamically fetches the upstream's
      tool list and caches it. Works together with a `listener` MCP Server that uses shared tags
      to aggregate tools. Supports optional OAuth2 authentication to fetch tool lists from the upstream.
    usecase: |
      Expose an existing upstream MCP server's tools alongside others through a single `listener`
      endpoint. The listener aggregates all tagged upstreams, so adding a new upstream is just
      deploying a new `upstream-server` with matching tags.
{% endtable %}
<!-- vale on -->

## Tool aggregation with upstream-server

You can use a `listener` to pull tools from multiple `upstream-server` MCP Servers and expose them through a single endpoint. The listener discovers and aggregates tools based on matching tags, so clients see one unified tool catalog while your services remain independent.

### How aggregation works

1. **Tags connect upstreams to listeners**: Set [`config.server.tag`](#schema-aigateway-mcpserver-config-server-tag) on the listener (e.g., `my-tools`). Set the same tag on every `upstream-server` AI MCP Server you want included. Any upstream with matching tags gets pulled into the aggregation.

2. **Tool discovery**: When an MCP client calls `tools/list`, the listener fetches tool lists from every tagged upstream. If an upstream requires authentication, configure [`config.server.tools_list_auth`](#schema-aigateway-mcpserver-config-server-tools-list-auth) with OAuth2 credentials so the listener can fetch its tools.

3. **Tool caching**: Each `upstream-server` caches its tool list for the duration specified by [`config.tools_cache_ttl_seconds`](#schema-aigateway-mcpserver-config-tools-cache-ttl-seconds). Set to `0` to fetch fresh on every client request.

4. **Tool name disambiguation**: If two upstreams expose tools with the same name, the listener prepends the service name to avoid collisions (e.g., `weather-service/get-forecast`). Disable this with [`config.server.preserve_upstream_tool_names`](#schema-aigateway-mcpserver-config-server-preserve-upstream-tool-names): true if you're sure names won't collide.

5. **Tool invocation**: When a client calls a tool, the listener routes the request to whichever upstream registered it. From the client's perspective, it's one call to one URL.

### Upstream authentication

By default, the AI MCP Server in `listener` mode connects to upstreams without credentials. If an upstream MCP server requires authentication:

- Set [`config.server.tools_list_auth`](#schema-aigateway-mcpserver-config-server-tools-list-auth) on the `upstream-server` type with OAuth2 client-credentials configuration
- {{site.ai_gateway}} fetches a token from your identity provider when first needed, caches it, and refreshes it when it expires
- The token is used only when fetching the upstream's tool list; it's separate from agent authentication
- Different upstreams can use different credentials, managed centrally by {{site.ai_gateway}}

### Header forwarding

When your upstream services need to enforce their own access controls or apply client-specific logic based on identity, enable [`config.server.forward_client_headers`](#schema-aigateway-mcpserver-config-server-forward-client-headers) on the `listener` or `upstream-server`. This setting passes the original client's headers (authentication tokens, context) so upstreams see the actual client, not just the listener.

## How MCP traffic flows

For `conversion-listener`, `conversion-only`, and `listener` modes, the runtime converts MCP requests into HTTP calls and wraps the responses back in MCP format:

1. Accepts an MCP protocol request from a client.
1. Parses the MCP tool call and matches it to a tool definition.
1. Converts the call into a standard HTTP request.
1. Sends the request to the upstream Service.
1. Wraps the HTTP response in MCP format and returns it to the client.

For `passthrough-listener` mode, the runtime proxies MCP traffic directly to the upstream MCP server without conversion.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant Client as MCP Client
    participant Gateway as {{site.ai_gateway}}<br>(MCP Server)
    participant Upstream as Upstream Service

    Client->>Gateway: MCP request (tool invocation)
    activate Gateway
    Gateway->>Gateway: Parse MCP payload
    Gateway->>Gateway: Map to HTTP endpoint
    Gateway->>Upstream: HTTP request
    deactivate Gateway
    activate Upstream
    Upstream-->>Gateway: HTTP response
    deactivate Upstream
    activate Gateway
    Gateway->>Gateway: Convert to MCP format
    Gateway-->>Client: MCP response
    deactivate Gateway
{% endmermaid %}
<!-- vale on -->

{:.info}
> Pings from MCP clients are included in the total request count for an {{site.ai_gateway}}
> instance, in addition to requests made to the MCP server itself.

## Tools

A [tool](#schema-aigateway-mcpserver-tools) maps an MCP tool name to an upstream HTTP endpoint. Each tool needs at minimum a description and an HTTP method. The runtime extracts the host, path, headers, and query from the route configuration, so most tool entries don't need to specify them. Override these on the tool entry only when the route doesn't match the upstream endpoint exactly.

For richer mapping, supply [`request_body`](#schema-aigateway-mcpserver-tools-request-body), [`responses`](#schema-aigateway-mcpserver-tools-responses), and [`parameters`](#schema-aigateway-mcpserver-tools-parameters) specifications in OpenAPI JSON format. The runtime uses them to validate calls and shape upstream HTTP requests.

Tools can also carry MCP-spec [`annotations`](#schema-aigateway-mcpserver-tools-annotations) that hint at tool behavior to clients (for example, whether a tool is read-only, idempotent, or destructive). Annotations don't change runtime behavior; they help clients decide whether to surface a tool, confirm before invocation, or treat it as safe to retry.

[Per-tool ACLs](#schema-aigateway-mcpserver-tools-acls) override the MCP Server's [default tool ACLs](#schema-aigateway-mcpserver-default-tool-acls). See [ACL tool control](#acl-tool-control).

## Sessions

Some MCP clients need to maintain state across multiple tool calls such as authentication tokens, conversation context, or request IDs. {{site.ai_gateway}} can manage session state for you in `listener` and `conversion-listener` modes, storing it either encrypted on the client or in Redis. Configure session storage through [`config.server.session`](#schema-aigateway-mcpserver-config-server-session). The `passthrough-listener` mode doesn't manage sessions because state lives entirely on the upstream MCP server.

Two session strategies:

1. **Client.** Session state is encrypted into the MCP session ID assigned to the client. Requires `secrets` which are encryption keys; the first entry is used for encryption, all entries are used for decryption to support key rotation.
1. **Redis.** Session state is stored in Redis. Configure connection details and authentication in [`config.server.session.redis`](#schema-aigateway-mcpserver-config-server-session-redis).

{% include_cached /md/ai-gateway/v2/policies/redis-cloud-auth.md tier='enterprise' %}

Configure how long sessions persist using [`session_ttl`](#schema-aigateway-mcpserver-config-server-session-session-ttl) (default 24 hours) to match your application's needs. If your upstream server already manages state internally, disable {{site.ai_gateway}}'s session management by setting `managed: false`.

{:.info}
> Secrets used in session encryption can be referenced from an [AI Vault](/ai-gateway/entities/ai-vault/).

## ACL tool control

When exposing MCP servers through {{site.ai_gateway}}, you may need granular control over which authenticated AI Consumers can discover and invoke specific tools. The MCP Server's ACL feature lets you define access rules at both the default level (applying to all tools) and per-tool level (for fine-grained exceptions).

This way, AI Consumers only interact with tools appropriate to their role, while maintaining a complete audit trail of all access attempts. Authentication is handled by an authentication Policy attached to the MCP Server (such as [Key Auth Policy](/ai-gateway/policies/key-auth/) or an OIDC flow), and the resulting Consumer identity is used for ACL checks.

{:.info}
> **ACL in `listener` mode**
>
> Listener mode does not support direct ACL configuration. Instead, it inherits ACL rules from tagged `conversion-listener` or `conversion-only` AI MCP Servers.
>
> To use ACLs with `listener` mode:
> 1. Configure `conversion-listener` or `conversion-only` AI MCP Servers with ACL rules and tags.
> 1. Configure `listener` mode to aggregate tools by matching tags.
> 1. Set [`include_consumer_groups`](#schema-aigateway-mcpserver-include-consumer-groups): true on the listener. Without this setting, the listener cannot pass AI Consumer Group membership to the aggregated tools, and ACL rules will not evaluate correctly.

### Attribute types

For modes that support ACL configuration (`conversion-listener`, `conversion-only`, `upstream-server`), two attribute types determine what the AI MCP Server evaluates ACL rules against:

1. **`consumer`** (default). Evaluates against the resolved Consumer identity.
1. **`oauth_access_token`**. Evaluates against a claim extracted from the OAuth access token. Set [`access_token_claim_field`](#schema-aigateway-mcpserver-access-token-claim-field) to a jq filter (for example, `.user.email` for a nested claim). The OAuth flow itself is supplied by the [AI MCP OAuth2 Policy](/ai-gateway/policies/ai-mcp-oauth2/).

### Using AI Consumers and Groups in ACLs

When `acl_attribute_type` is `consumer`, you can gate access by individual [AI Consumers](/ai-gateway/entities/ai-consumer/) (using username, UUID, or custom ID) or by [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) membership. This flexibility lets you define rules at the right level: deny a specific user, allow a tier-based group, or mix both in the same ACL. The runtime checks the authenticated consumer's identity and group memberships against your `allow` and `deny` lists.

### How default and per-tool ACLs work

The runtime evaluates access using a two-tier system:

<!-- vale off -->
{% table %}
columns:
  - title: ACL type
    key: field
  - title: Description
    key: description
rows:
  - field: "`default_tool_acls`"
    description: |
      Baseline rules that apply to all tools unless overridden.
  - field: "`tools[].acls`"
    description: |
      When configured, these rules replace the default ACL for that specific tool. The per-tool ACL doesn't inherit or merge with `default_tool_acls`. It is an all-or-nothing override.
{% endtable %}
<!-- vale on -->

{:.info}
> If a tool defines its own ACL, the runtime ignores `default_tool_acls` for that tool:
>
> - Tools with no ACL configuration inherit the default rules (both `allow` and `deny` lists).
> - Tools with an ACL must explicitly list all allowed subjects (even if they were already in `default_tool_acls`).

### ACL evaluation logic

Both default and per-tool ACLs use `allow` and `deny` lists. Evaluation follows this order:

1. **Deny list configuration**. If a `deny` list exists and the subject matches any `deny` entry, the request is rejected (`HTTP 403 Forbidden`).
1. **Allow list configuration**. If an `allow` list exists, the subject must match at least one entry; otherwise, the request is denied (`HTTP 403 Forbidden`).
1. **No allow list configuration**. If no `allow` list exists and the subject is not in `deny`, the request is allowed.
1. **No ACL configuration**. If neither list exists, the request is allowed.

All access attempts (allowed or denied) are written to the audit log.

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
    response: HTTP 403 Forbidden
  - condition: "`allow` list exists and subject is not in it"
    proxy: No
    response: HTTP 403 Forbidden
  - condition: "Only `deny` list exists and subject is not in it"
    proxy: Yes
    response: 200
  - condition: "No ACL rules configured"
    proxy: Yes
    response: 200
{% endtable %}

### ACL tool control request flow

The runtime evaluates ACLs for both tool discovery and tool invocation. These are two distinct operations with different behaviors:

**Tool discovery (list tools)**:

1. MCP client requests the list of available tools.
1. The authentication Policy validates the request and identifies the Consumer.
1. The runtime loads the Consumer's group memberships.
1. The runtime evaluates each tool against `default_tool_acls`.
1. The runtime returns an HTTP 200 response with only the tools the Consumer is allowed to access.
1. The runtime logs the discovery attempt.

**Tool invocation**:

1. MCP client invokes a specific tool.
1. The authentication Policy validates the request and identifies the Consumer.
1. The runtime loads the Consumer's group memberships.
1. The runtime evaluates the tool-specific ACL if it exists, or the default ACL otherwise.
1. The runtime logs the access attempt (allowed or denied).
1. The runtime returns `HTTP 403 Forbidden` if denied, or forwards the request to the upstream MCP server if allowed.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
  participant Client as MCP Client
  participant Gateway as {{site.ai_gateway}}
  participant Auth as AuthN Policy
  participant ACL as AI MCP Server (ACL/Audit)
  participant Up as Upstream MCP Server
  participant Log as Audit Sink

  %% ----- List Tools -----
  rect
    note over Client,Gateway: List Tools (Default ACL Scope)
    Client->>Gateway: GET /tools
    Gateway->>Auth: Authenticate
    Auth-->>Gateway: Consumer identity
    Gateway->>ACL: Evaluate scoped default ACL
    ACL-->>Log: Audit entry
    alt If allowed
      Gateway-->>Client: Filtered tool list
    else If denied
      Gateway-->>Client: HTTP 403 Forbidden
    end
  end

  %% ----- Tool Invocation -----
  rect
    note over Client,Up: Tool Invocation (Per-tool ACL)
    Client->>Gateway: POST /tools/{tool}
    Gateway->>Auth: Authenticate
    Auth-->>Gateway: Consumer identity
    Gateway->>ACL: Evaluate per-tool ACL
    ACL-->>Log: Audit entry
    alt If allowed
      Gateway->>Up: Forward request
      Up-->>Gateway: Response
      Gateway-->>Client: Response
    else If denied
      Gateway-->>Client: HTTP 403 Forbidden
    end
  end
{% endmermaid %}
<!-- vale on -->

## Logging and audits

To monitor and troubleshoot MCP traffic, enable logging and audit trails through [`config.logging`](#schema-aigateway-mcpserver-config-logging). You can capture per-request statistics for metrics, full request and response payloads for debugging, and [audit entries](/ai-gateway/ai-audit-log-reference/#ai-mcp-logs) for every ACL decision. Note that payload logging may expose sensitive data. Enable it only when debugging and be careful with retention. AI MCP Server analytics appear in [{{site.konnect_short_name}} Explorer and Dashboards](/ai-gateway/monitor-ai-llm-metrics/#mcp-traffic-metrics) alongside other {{site.ai_gateway}} traffic, and export through [OpenTelemetry](/ai-gateway/ai-otel-metrics/#mcp-metrics).


Just like HTTP Routes, AI MCP Servers benefit from security and governance AI Policies. Attach [AI Policies](/ai-gateway/entities/ai-policy/) to enforce authentication, rate limits, request/response transformation, and OAuth gating. Add them to the [`policies`](#schema-aigateway-mcpserver-policies) field by name or ID. AI Policies run on all MCP traffic through the server, before tool invocation and after ACL checks. Multiple AI Policies can attach to one AI MCP Server, and each runs independently in the request lifecycle.

You can also attach AI Policies at the [AI Consumer](/ai-gateway/entities/ai-consumer/) level for per-client enforcement. See [Use cases](#use-cases) for practical AI Policy combinations, and the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference for all supported policy types and how they work.

## Scope of support

The AI MCP Server runtime supports MCP operations and upstream interactions, while certain advanced features and non-HTTP protocols are not currently supported. The table below summarizes what is supported and what is outside the current scope.

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
    description: Applying guardrails to MCP AI requests and responses
    supported: false
{% endfeature_table %}
<!-- vale on -->

## Set up an AI MCP Server

The following example creates a `conversion-listener` AI MCP Server that exposes the [WeatherAPI](https://www.weatherapi.com/) through a single `get-current-weather` MCP tool.

{:.info}
> You need your WeatherAPI API key set as an environment variable (`DECK_WEATHERAPI_API_KEY`) before using this example.

{% entity_example %}
type: mcp_server
data:
  display_name: Weather API
  name: weather-mcp
  type: conversion-listener
  enabled: true
  policies: []
  acl_attribute_type: consumer
  acls:
    allow:
      - __never_match__
  default_tool_acls:
    deny:
      - __never_match__
  config:
    url: https://api.weatherapi.com/v1/current.json
    route:
      paths:
        - /weather
    logging:
      payloads: false
      statistics: true
    server:
      timeout: 60000
  tools:
    - name: get-current-weather
      description: Get current weather for a location
      method: GET
      path: /weather
      query:
        key:
          - $DECK_WEATHERAPI_API_KEY
      parameters:
        - name: q
          in: query
          required: true
          schema:
            type: string
          description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name.
{% endentity_example %}

## Schema

{% entity_schema %}
