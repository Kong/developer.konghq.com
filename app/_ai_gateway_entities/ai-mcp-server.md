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
  - kongctl
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
      `conversion-listener` converts a RESTful API into MCP tools and accepts MCP requests on one route path. `conversion-only` converts a RESTful API into MCP tools that a `listener` AI MCP Server
      aggregates by matching labels, but doesn't accept incoming MCP traffic itself. `listener` aggregates tools from one or more
      `conversion-only` AI MCP Servers into a single MCP endpoint. `upstream-server` registers a real
      MCP server into an aggregation pool, dynamically fetching its tools for a `listener` to aggregate.

  - q: Can the same AI Consumer's identity gate access to specific tools?
    a: |
      Yes. Set [`access.default_tool_acls`](#schema-aigateway-mcpserver-access-default-tool-acls) on the AI MCP Server with `allow` and `deny` lists, and override per
      tool through [`tools[].access.acls`](#schema-aigateway-mcpserver-tools-access). A per-tool ACL replaces the default for that tool, it doesn't
      merge.

  - q: How do OAuth-based ACLs differ from AI Consumer-based ACLs?
    a: |
      Set [`access.acl_attribute_type`](#schema-aigateway-mcpserver-access-acl-attribute-type) to `oauth_access_token` and provide [`access.access_token_claim_field`](#schema-aigateway-mcpserver-access-access-token-claim-field) (a jq
      filter, for example `.user.email`). ACLs then evaluate against the claim value extracted from
      the OAuth access token instead of the resolved AI Consumer identity. If [`access.metadata`](#schema-aigateway-mcpserver-access-metadata)
      is also set, {{site.ai_gateway}} generates an [AI MCP OAuth2 Policy](/ai-gateway/policies/ai-mcp-oauth2/)
      configuration for this server's route instead of a plain auth-strategy check. See
      [Protected resource metadata](#protected-resource-metadata).

  - q: What error code do denied requests return?
    a: |
      `HTTP 403 Forbidden`. Earlier {{site.ai_gateway}} versions returned the JSON-RPC error code
      `INVALID_PARAMS -32602`; from {{site.ai_gateway}} 3.14 onward, denials follow the
      [MCP 2025-11-25 authorization specification](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization#error-handling).

  - q: How do I authenticate requests to an AI MCP Server?
    a: |
      Reference an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) by name or ID in the AI MCP
      Server's [`access.auth_strategies`](#schema-aigateway-mcpserver-access) array, the same
      way you would for an [AI Model](/ai-gateway/entities/ai-model/#access-control) or
      [AI Agent](/ai-gateway/entities/ai-agent/#access-control). This is supported for `conversion-listener`,
      `listener`, and `passthrough-listener` modes. An AI MCP Server currently accepts up to one AI Identity
      Provider reference. The AI MCP Server has its own top-level authentication mechanism, so attaching an
      authentication AI Policy directly to its `policies` field isn't supported.

  - q: Can I attach a rate-limiting policy to an AI MCP Server?
    a: |
      Yes. Policy configuration such as rate limiting, logging, or request/response transformation goes through
      the [AI Policy entity](/ai-gateway/entities/ai-policy/). Attach Policies to the AI MCP Server through its
      [`policies`](#schema-aigateway-mcpserver-policies) field.
---

## What is an AI MCP Server?

Create an AI MCP Server to connect AI applications such as [Claude](https://claude.ai/), [Cursor](https://cursor.com/), or [Insomnia](/insomnia/) to your APIs and tools through the standardized [Model Context Protocol](https://modelcontextprotocol.io/). An AI MCP Server acts as a bridge between MCP-compatible clients and your backend systems, allowing you to expose existing APIs as discoverable tools without building custom integrations for each AI client.

Because MCP endpoints run directly on {{site.ai_gateway}}, you don't need to host and scale MCP infrastructure separately. The same authentication, rate limiting, and observability policies you apply to traditional API traffic automatically cover MCP traffic, giving you consistent governance across both HTTP and MCP clients.

{:.warning}
> **Note:** MCP traffic is API-level traffic, not LLM request/response flows. Authenticate MCP traffic through an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) referenced in [`access.auth_strategies`](#schema-aigateway-mcpserver-access), the same as AI Models and AI Agents. Standard API-level policies (rate limiting, logging) still apply to MCP traffic through the [`policies`](#schema-aigateway-mcpserver-policies) field. AI Policies that operate on LLM prompt/response flows (such as prompt guards or model routing) won't apply here.

## Manage AI MCP Servers

AI MCP Servers can be created and managed through the:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/mcp-servers`
* [kongctl](/kongctl/)

For configuration examples and step-by-step setup instructions, see [Set up an AI MCP Server](#set-up-an-ai-mcp-server).

## AI MCP Server governance

Attach [AI Policies](/ai-gateway/entities/ai-policy/) to AI MCP Servers to enforce rate limits, request/response transformation, logging, and OAuth-based ACL gating. Add them to the [`policies`](#schema-aigateway-mcpserver-policies) field by name or ID. AI Policies run on all MCP traffic through the server, before tool invocation and after ACL checks. Multiple AI Policies can attach to one AI MCP Server, and each runs independently in the request lifecycle. Authenticating AI Consumers isn't handled through the `policies` field; reference an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) in [`access.auth_strategies`](#schema-aigateway-mcpserver-access) instead. See [Access control](#access-control).

You can also attach AI Policies at the [AI Consumer](/ai-gateway/entities/ai-consumer/) level for per-client enforcement.

Attach [AI Policies](/ai-gateway/entities/ai-policy/) to your AI MCP Server for common governance scenarios:

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Policy
    key: example
rows:
  - use_case: "Secure MCP endpoints with AI Consumer identity or OAuth tokens"
    example: "Reference an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) (`key-auth` or `openid-connect`) in [`access.auth_strategies`](#schema-aigateway-mcpserver-access). Advertise [protected resource metadata](#protected-resource-metadata) through `access.metadata` so MCP clients can discover the authorization server."
  - use_case: "Rate limiting"
    example: "Use [Rate Limiting](/ai-gateway/policies/rate-limiting/) or [Rate Limiting Advanced](/ai-gateway/policies/rate-limiting-advanced/) Policy to control MCP request volume per AI Consumer or AI Consumer Group."
  - use_case: "Track all MCP traffic and ACL decisions."
    example: "Enable request and response logging through [AI logging Policies](/ai-gateway/policies/?category=logging) and audit trails."
  - use_case: "Traffic control"
    example: "Apply [Request Transformer](/ai-gateway/policies/request-transformer/) or [Response Transformer](/ai-gateway/policies/response-transformer/) Policy to modify MCP payloads, or use [ACLs](#acl-tool-control) for fine-grained tool access."
{% endtable %}
<!-- vale on -->

## Server modes

{{site.ai_gateway}} supports five server modes for different integration patterns: exposing REST APIs as discoverable MCP tools, proxying requests to existing MCP servers with added authentication and observability, or aggregating tools from multiple sources into a single endpoint. Select the mode that fits your use case using the [`type`](#schema-aigateway-mcpserver-type) field. Regardless of mode, {{site.ai_gateway}} generates [MCP observability metrics](/ai-gateway/monitor-ai-llm-metrics/#mcp-traffic-metrics) for all traffic through the server.

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Integration pattern
    key: pattern
  - title: Description
    key: description
  - title: Mode
    key: mode
rows:
  - usecase: |
      You already operate an MCP server and want {{site.ai_gateway}} to act as an authenticated,
      observable entrypoint. Common for third-party or internally hosted MCP services exposed
      through {{site.ai_gateway}}.
    pattern: Existing MCP server
    description: |
      Listens for incoming MCP requests and proxies them to an upstream MCP server without
      converting tools.
    mode: "`passthrough-listener`"
  - usecase: |
      Make an existing REST API available to MCP clients directly through {{site.ai_gateway}}.
      Common for services that both define and handle their own tools.
    pattern: Generate from REST API
    description: |
      Converts RESTful API paths into MCP tools and accepts incoming MCP requests on the route
      path. Tools are defined directly on the MCP Server and an optional server block applies.
      Supports session identifiers set by authentication services for cookie-based
      authentication.
    mode: "`conversion-listener`"
  - usecase: |
      Define reusable tool specifications without serving them yourself. Suitable for teams that
      maintain a shared library of tool definitions for one or more `listener` MCP Servers.
      Good for APIs you don't own or can't modify.
    pattern: Generate from REST API and feeds aggregate
    description: |
      Converts RESTful API paths into MCP tools but does not accept incoming MCP requests.
      Since a `conversion-only` AI MCP Server has no `config.server` block, it marks itself for aggregation using the
      top-level [`labels`](#schema-aigateway-mcpserver-labels) field instead (for example,
      `labels: {ai-gateway-mcp-aggregation: payments}`). A `listener` AI MCP Server then references it by
      matching label. This mode must be used together with one or more AI MCP Servers configured with
      `listener` mode.
    mode: "`conversion-only`"
  - usecase: |
      A single MCP endpoint that aggregates tools from multiple `conversion-only` or
      `upstream-server` MCP Servers. Typical in multi-service or multi-team environments that
      expose a unified MCP interface. One `listener` per aggregated endpoint.
    pattern: Aggregate
    description: |
      Similar to `conversion-listener`, but binds tools from one or more `conversion-only` MCP Servers
      instead of defining its own. Set [`config.server.label`](#schema-aigateway-mcpserver-config-server-label)
      to `<label-key>:<label-value>`, matching a key/value pair set in the `labels` field of each
      `conversion-only` MCP Server to include. Merges all matching tools into one list and routes each
      tool call to the correct backend.
    mode: "`listener`"
  - usecase: |
      Expose an existing upstream MCP server's tools alongside others through a single `listener`
      endpoint. The listener aggregates all matching upstreams, so adding a new upstream is just
      deploying a new `upstream-server` AI MCP Server with a matching label.
    pattern: Existing MCP server and feeds aggregate
    description: |
      Registers a real MCP server into an aggregation pool and tells the `listener` MCP Server
      "this backend has tools, go fetch them." Dynamically fetches and caches its tool list,
      then pairs with a `listener` MCP Server through a shared label. Supports optional OAuth2
      authentication to fetch tool lists from the upstream. This mode must be used together
      with one or more AI MCP Servers configured with `listener` mode.
    mode: "`upstream-server`"
{% endtable %}
<!-- vale on -->

## How MCP traffic flows

For `conversion-listener`, `conversion-only`, and `listener` modes, the runtime converts MCP requests into HTTP calls and wraps the responses back in MCP format:

1. Accepts an MCP protocol request from a client.
1. Parses the MCP tool call and matches it to a tool definition.
1. Converts the call into a standard HTTP request.
1. Sends the request to the upstream service.
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

### Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}

## Tool aggregation with upstream-server

You can use a `listener` AI MCP Server to pull tools from multiple `upstream-server` AI MCP Servers and expose them through a single endpoint. The listener discovers and aggregates tools based on a matching label, so clients see one unified tool catalog while your services remain independent.

### How aggregation works

1. **Labels connect upstreams to listeners**: Each `upstream-server` AI MCP Server tags itself using the top-level [`labels`](#schema-aigateway-mcpserver-labels) field (for example, `labels: {my-tools: catalog}`). Set [`config.server.label`](#schema-aigateway-mcpserver-config-server-label) on the listener to the matching `<label-key>:<label-value>` string (for example, `my-tools:catalog`). Any upstream with that label gets pulled into the aggregation.

2. **Tool discovery**: When an MCP client calls `tools/list`, the listener fetches tool lists from every matching upstream. If an upstream requires authentication, configure [`config.server.tools_list_auth`](#schema-aigateway-mcpserver-config-server-tools-list-auth) with OAuth2 credentials so the listener can fetch its tools.

3. **Tool caching**: Each `upstream-server` caches its tool list for the duration specified by [`config.tools_cache_ttl_seconds`](#schema-aigateway-mcpserver-config-tools-cache-ttl-seconds). Set to `0` to fetch fresh on every client request.

4. **Tool name disambiguation**: If two upstreams expose tools with the same name, the listener prepends the service name to avoid collisions (e.g., `weather-service/get-forecast`). Disable this with [`config.server.preserve_upstream_tool_names`](#schema-aigateway-mcpserver-config-server-preserve-upstream-tool-names): true if you're sure names won't collide.

5. **Tool invocation**: When a client calls a tool, the listener routes the request to whichever upstream registered it. From the client's perspective, it's one call to one URL.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant Agent as AI Agent
    participant Kong as {{site.ai_gateway}}
    participant Listener as AI MCP Server
    participant Upstreams as Upstreams<br/>(label: my-tools:catalog)

    note over Agent,Upstreams: Phase 1: Token Validation
    Agent->>Kong: Bearer token
    Kong->>Kong: Validate & exchange token
    Kong->>Listener: Pass request

    note over Agent,Upstreams: Phase 2: Tools List Aggregation
    Agent->>Kong: tools/list
    Kong->>Listener: tools/list
    Listener->>Upstreams: Query all matching upstreams
    Upstreams-->>Listener: Tool lists
    Listener-->>Kong: Merged list
    Kong-->>Agent: Aggregated tools

    note over Agent,Upstreams: Phase 3: Tool Call Routing
    Agent->>Kong: tools/call (tool name)
    Kong->>Listener: Route to upstream
    Listener->>Upstreams: Forward call
    Upstreams-->>Listener: Result
    Listener-->>Kong: Result
    Kong-->>Agent: Tool response
{% endmermaid %}
<!-- vale on -->

> _Figure 1_: This diagram shows how {{site.ai_gateway}} handles requests from an AI agent. It validates the agent's credentials, collects tool definitions from multiple services, and forwards tool calls to the correct upstream.

### Upstream authentication

By default, the AI MCP Server in `listener` mode connects to upstreams without credentials. If an upstream MCP server requires authentication, configure [`config.server.tools_list_auth`](#schema-aigateway-mcpserver-config-server-tools-list-auth) on the `upstream-server`. The credential is used only when fetching the upstream's tool list, not for agent requests. Different upstreams can use different credentials, managed centrally by {{site.ai_gateway}}.

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Type
    key: type
  - title: Configuration
    key: config
rows:
  - usecase: Your upstream requires a service-to-service OAuth2 token from an identity provider.
    type: "`credentials`"
    config: |
      `token_endpoint`, `client_id`, and `client_secret`. {{site.ai_gateway}} exchanges them for
      a bearer token, caches it, and refreshes it on expiry.
  - usecase: Your upstream validates JWTs directly, without a token exchange step.
    type: "`jwt`"
    config: A pre-signed JWT. {{site.ai_gateway}} presents it as-is when fetching the tool list.
{% endtable %}
<!-- vale on -->

### Header forwarding

When your upstream services need to enforce their own access controls or apply client-specific logic based on identity, enable [`config.server.forward_client_headers`](#schema-aigateway-mcpserver-config-server-forward-client-headers) on the `listener` or `upstream-server`. This setting passes the original client's headers (authentication tokens, context) so upstreams see the actual client, not just the listener.

## Tools

A [tool](#schema-aigateway-mcpserver-tools) maps an MCP tool name to an upstream HTTP endpoint. Each tool needs at minimum a description and an HTTP method. The runtime extracts the host, path, headers, and query from the route configuration, so most tool entries don't need to specify them. Override these on the tool entry only when the route doesn't match the upstream endpoint exactly.

For richer mapping, supply [`request_body`](#schema-aigateway-mcpserver-tools-request-body), [`responses`](#schema-aigateway-mcpserver-tools-responses), and [`parameters`](#schema-aigateway-mcpserver-tools-parameters) specifications in OpenAPI JSON format. The runtime uses them to validate calls and shape upstream HTTP requests.

Tools can also carry MCP-spec [`annotations`](#schema-aigateway-mcpserver-tools-annotations) that hint at tool behavior to clients (for example, whether a tool is read-only, idempotent, or destructive). Annotations don't change runtime behavior; they help clients decide whether to surface a tool, confirm before invocation, or treat it as safe to retry.

[Per-tool ACLs](#schema-aigateway-mcpserver-tools-access) override the MCP Server's [default tool ACLs](#schema-aigateway-mcpserver-access-default-tool-acls). For more information, see [ACL tool control](#acl-tool-control).

## Sessions

Some MCP clients need to maintain state across multiple tool calls such as authentication tokens, conversation context, or request IDs. {{site.ai_gateway}} can manage session state for you in `listener` and `conversion-listener` modes, storing it either encrypted on the client or in Redis. Configure session storage through [`config.server.session`](#schema-aigateway-mcpserver-config-server-session). The `passthrough-listener` mode doesn't manage sessions because state lives entirely on the upstream MCP server.

There are two session strategies:

1. **Client.** Session state is encrypted into the MCP session ID assigned to the client. Requires `secrets` which are encryption keys; the first entry is used for encryption, all entries are used for decryption to support key rotation.
1. **Redis.** Session state is stored in Redis. Configure connection details and authentication in [`config.server.session.redis`](#schema-aigateway-mcpserver-config-server-session-redis).

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md tier='enterprise' %}

Configure how long sessions persist using [`session_ttl`](#schema-aigateway-mcpserver-config-server-session-session-ttl) (default 24 hours) to match your application's needs. If your upstream server already manages state internally, disable {{site.ai_gateway}}'s session management by setting `managed: false`.

{:.info}
> Secrets used in session encryption can be referenced from an [AI Vault](/ai-gateway/entities/ai-vault/).

## Connecting to the MCP endpoint

An MCP client such as [Claude Desktop](https://claude.ai/download), Cursor, or [ChatWise](https://chatwise.app/) handles the following details automatically. They matter when testing an AI MCP Server directly, for example with `curl`, or when building a custom MCP client.

**Streamable HTTP handshake**. {{site.ai_gateway}} implements the MCP [Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#streamable-http). A spec-compliant client performs this sequence before calling tools:

1. Send an `initialize` request to the route configured on [`config.route.paths`](#schema-aigateway-mcpserver-config-route-paths). The response includes an `Mcp-Session-Id` header.
1. Send a `notifications/initialized` notification to the same route.
1. Carry the `Mcp-Session-Id` header on subsequent `tools/list` and `tools/call` requests.

{:.success}
> **Tool argument naming**.
>
>Tools generated from [`parameters`](#schema-aigateway-mcpserver-tools-parameters) (`conversion-listener`, `conversion-only`) rename `query`, `path`, `header`, and `cookie` args to `{in}_{name}`: `query: q` becomes `query_q`.
> Bodies collapse into a single `body` property. Check `tools/list` before calling `tools/call`.

## Access control

Once you expose tools through an AI MCP Server, anyone who can reach the endpoint can attempt to call them unless you gate access to known AI Consumers. To authenticate AI Consumers calling a `conversion-listener`, `listener`, or `passthrough-listener` AI MCP Server, reference an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) by name or ID in the [`access.auth_strategies`](#schema-aigateway-mcpserver-access) array. This is the same mechanism used by [AI Models](/ai-gateway/entities/ai-model/#access-control) and [AI Agents](/ai-gateway/entities/ai-agent/#access-control). An AI MCP Server currently accepts up to one AI Auth Strategy reference. The AI MCP Server has its own top-level authentication mechanism, so attaching an authentication AI Policy directly to its [`policies`](#schema-aigateway-mcpserver-policies) field isn't supported; authentication is configured exclusively through AI Auth Strategies. See [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes) for details.

`upstream-server` AI MCP Servers don't accept an `access.auth_strategies` reference. Configure [`config.server.tools_list_auth`](#schema-aigateway-mcpserver-config-server-tools-list-auth) instead to authenticate to the upstream when fetching its tool list; see [Upstream authentication](#upstream-authentication). `conversion-only` AI MCP Servers have no `access` field at all, since they never accept incoming MCP traffic directly.

ACLs are evaluated only after the AI Consumer's identity is resolved through this authentication step. For ACL configuration, see [ACL tool control](#acl-tool-control).

### Protected resource metadata

If your MCP clients follow the MCP authorization specification's discovery flow, they need to know which authorization server protects your AI MCP Server before they can request a token, or they fail outright instead of prompting the user through an OAuth flow. To support these clients, advertise [OAuth 2.0 Protected Resource Metadata](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) (RFC 9728) through [`access.metadata`](#schema-aigateway-mcpserver-access-metadata) on `conversion-listener`, `listener`, and `passthrough-listener` AI MCP Servers.

Configure `access.metadata` alongside an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) in `access.auth_strategies`:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`resource`"
    description: The protected resource's canonical identifier (a URI).
  - field: "`authorization_servers`"
    description: Issuer URLs of the authorization servers that can issue tokens for this resource. Falls back to the AI Auth Strategy's issuer when omitted.
  - field: "`scopes_supported`"
    description: The OAuth scopes the resource accepts. Falls back to the AI Auth Strategy's configured scopes when omitted.
  - field: "`endpoint`"
    description: The path where {{site.ai_gateway}} serves the metadata document. Added to the AI MCP Server's route automatically.
{% endtable %}

Setting `access.metadata` causes {{site.ai_gateway}} to generate an [AI MCP OAuth2 Policy](/ai-gateway/policies/ai-mcp-oauth2/) configuration from it and the referenced AI Auth Strategy, and apply it to this AI MCP Server's route in place of a plain auth-strategy check. You don't create or attach an AI MCP OAuth2 Policy instance yourself for this. The generated configuration adds OAuth 2.1 resource-server behavior (protected resource metadata serving, token audience validation) that a plain `openid-connect` check alone doesn't provide.

{:.info}
> Generating an AI MCP OAuth2 Policy configuration is the current mechanism for this OAuth 2.1 resource-server behavior. This is also why `access.metadata` requires an `openid-connect` AI Auth Strategy: a future release moves this behavior to native OIDC resource-server support without changing how you configure `access.auth_strategies`.

<!-- FOT ENG REVIEW: confirm the full field-mapping from AI Auth Strategy config to the generated AI MCP OAuth2 configuration against the real materialization logic before expanding this note beyond audience_required/hide_credentials. -->
Two AI Auth Strategy settings carry forward into the generated configuration: `audience_required` controls whether the generated configuration enforces the token's audience against `access.metadata.resource`, and `hide_credentials: false` enables credential passthrough on the generated configuration instead of stripping credentials from the request.

{:.warning}
> `access.metadata` isn't supported with a `key-auth` AI Auth Strategy. `key-auth` credentials can't serve OAuth 2.0 Protected Resource Metadata; combining the two is rejected.

If you omit `access.metadata`, `access.auth_strategies` still authenticates requests on its own, as a plain `key-auth` or `openid-connect` check, without the added OAuth 2.1 resource-server behavior.

## ACL tool control

When exposing MCP servers through {{site.ai_gateway}}, you may need granular control over which authenticated [AI Consumers](/ai-gateway/entities/ai-consumer/) can discover and invoke specific tools. The MCP Server's ACL feature lets you define access rules at both the default level (which applies to all tools) and per-tool level (for fine-grained exceptions).

This way, AI Consumers only interact with tools appropriate to their role, while maintaining a complete audit trail of all access attempts. Authentication is handled by an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) (`key-auth` or `openid-connect`) referenced in the AI MCP Server's [`access.auth_strategies`](#schema-aigateway-mcpserver-access) array, and the resolved AI Consumer identity is used for ACL checks. See [Access control](#access-control).

{:.info}
> **ACL in `listener` mode**
>
> `listener` mode supports direct ACL configuration on the MCP Server itself.
>
> To use ACLs with `listener` mode:
> 1. Reference an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) in [`access.auth_strategies`](#schema-aigateway-mcpserver-access) so requests resolve to an authenticated AI Consumer.
> 1. Set ACL fields directly on the listener: [`access.acl_attribute_type`](#schema-aigateway-mcpserver-access-acl-attribute-type), [`access.access_token_claim_field`](#schema-aigateway-mcpserver-access-access-token-claim-field) (when using `oauth_access_token`), [`access.acls`](#schema-aigateway-mcpserver-access-acls) for server-level fallback rules, [`access.default_tool_acls`](#schema-aigateway-mcpserver-access-default-tool-acls) for the default tool ACL, and per-tool [`tools[].access.acls`](#schema-aigateway-mcpserver-tools-access) for tool-specific overrides.
> 1. Configure [AI Consumers](/ai-gateway/entities/ai-consumer/) and [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) to match the `allow` and `deny` entries.
>
> ACL behavior:
>
> - `access.default_tool_acls` applies to all tools by default.
> - If `access.default_tool_acls` isn't set, the listener falls back to the top-level `access.acls`.
> - A tool's own `acls` fully overrides the default ACL for that tool.
> - [`config.server.label`](#schema-aigateway-mcpserver-config-server-label) is used for tool filtering and aggregation, not for inheriting ACLs from other AI MCP Servers.

### Attribute types

For modes that support server-level ACL configuration (`conversion-listener`, `listener`, `passthrough-listener`, `upstream-server`), two attribute types determine what the AI MCP Server evaluates ACL rules against:

1. **`consumer`** (default). Evaluates against the resolved AI Consumer identity.
1. **`oauth_access_token`**. Evaluates against a claim extracted from the OAuth access token. Set [`access.access_token_claim_field`](#schema-aigateway-mcpserver-access-access-token-claim-field) to a jq filter (for example, `.user.email` for a nested claim). The token is validated by the `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) referenced in [`access.auth_strategies`](#schema-aigateway-mcpserver-access) — on this server if it accepts MCP traffic directly (`conversion-listener`, `listener`, `passthrough-listener`), or on the `listener` that aggregates it if this is a `conversion-only` or `upstream-server` AI MCP Server. If [`access.metadata`](#schema-aigateway-mcpserver-access-metadata) is also set, validation happens through the generated AI MCP OAuth2 Policy configuration instead; see [Protected resource metadata](#protected-resource-metadata).

`conversion-only` AI MCP Servers have no `access` field of their own, since they never accept incoming MCP traffic directly. They only support per-tool ACLs (via [`tools[].access.acls`](#schema-aigateway-mcpserver-tools-access)), which travel with the tool definition when a `listener` aggregates it.

### Using AI Consumers and Groups in ACLs

When `access.acl_attribute_type` is `consumer`, you can gate access by individual [AI Consumers](/ai-gateway/entities/ai-consumer/) (using username, UUID, or custom ID) or by [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) membership. This flexibility lets you define rules at the right level: deny a specific user, allow a tier-based group, or mix both in the same ACL. The runtime checks the authenticated AI Consumer's identity and group memberships against your `allow` and `deny` lists.

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
  - field: "`access.default_tool_acls`"
    description: |
      Baseline rules that apply to all tools unless overridden.
  - field: "`tools[].access.acls`"
    description: |
      When configured, these rules replace the default ACL for that specific tool. The per-tool ACL doesn't inherit or merge with `access.default_tool_acls`. It is an all-or-nothing override.
{% endtable %}
<!-- vale on -->

{:.info}
> If a tool defines its own ACL, the runtime ignores `access.default_tool_acls` for that tool:
>
> - Tools with no ACL configuration inherit the default rules (both `allow` and `deny` lists).
> - Tools with an ACL must explicitly list all allowed subjects (even if they were already in `access.default_tool_acls`).

### ACL evaluation logic

Both default and per-tool ACLs use `allow` and `deny` lists. Evaluation follows this order:

1. **Deny list configuration**. If a `deny` list exists and the subject matches any `deny` entry, the request is rejected (`HTTP 403 Forbidden`).
1. **Allow list configuration**. If an `allow` list exists, the subject must match at least one entry; otherwise, the request is denied (`HTTP 403 Forbidden`).
1. **No allow list configuration**. If no `allow` list exists and the subject is not in `deny`, the request is allowed.
1. **No ACL configuration**. If neither list exists, the request is allowed.

All access attempts (allowed or denied) are written to the audit log.

The following table summarizes the possible ACL configurations and their outcomes.

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
1. The AI Auth Strategy validates the request and identifies the AI Consumer.
1. The runtime loads the AI Consumer's group memberships.
1. The runtime evaluates each tool against `default_tool_acls`.
1. The runtime returns an HTTP 200 response with only the tools the AI Consumer is allowed to access.
1. The runtime logs the discovery attempt.

**Tool invocation**:

1. MCP client invokes a specific tool.
1. The AI Auth Strategy validates the request and identifies the AI Consumer.
1. The runtime loads the AI Consumer's group memberships.
1. The runtime evaluates the tool-specific ACL if it exists, or the default ACL otherwise.
1. The runtime logs the access attempt (allowed or denied).
1. The runtime returns `HTTP 403 Forbidden` if denied, or forwards the request to the upstream MCP server if allowed.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
  participant Client as MCP Client
  participant Gateway as {{site.ai_gateway}}
  participant Auth as AI Auth Strategy
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

To monitor and troubleshoot MCP traffic, enable logging and audit trails through [`config.logging`](#schema-aigateway-mcpserver-config-logging). You can capture per-request statistics for metrics, full request and response payloads for debugging, and [audit entries](/ai-gateway/ai-audit-log-reference/#ai-mcp-logs) for every ACL decision. Note that payload logging may expose sensitive data. Enable it only when debugging and be careful with retention. [AI MCP Server analytics](/ai-gateway/monitor-ai-llm-metrics/#mcp-traffic-metrics) display in {{site.konnect_short_name}} [Explorer](https://cloud.konghq.com/analytics/explorer) and [Dashboards](https://cloud.konghq.com/analytics/dashboards) alongside other {{site.ai_gateway}} traffic, and export through [OpenTelemetry](/ai-gateway/policies/opentelemetry/reference/).

## Scope of support

The AI MCP Server runtime supports MCP operations and upstream interactions, while certain advanced features and non-HTTP protocols are not currently supported. The following table summarizes what is supported and what is outside the current scope.

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
> You need your WeatherAPI API key set as an environment variable (`WEATHERAPI_API_KEY`) before using this example.

{% entity_example %}
type: mcp_server
data:
  display_name: Weather API
  name: weather-mcp
  type: conversion-listener
  enabled: true
  policies: []
  access:
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
      audits: true
    server:
      timeout: 60000
  tools:
    - name: get-current-weather
      description: Get current weather for a location
      method: GET
      path: /weather
      query:
        key:
          - $WEATHERAPI_API_KEY
      parameters:
        - name: q
          in: query
          required: true
          schema:
            type: string
          description: Location query. Accepts US Zipcode, UK Postcode, Canada postal code, IP address, latitude/longitude, or city name.
{% endentity_example %}

## Schema

{% entity_schema %}
