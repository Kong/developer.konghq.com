---
title: AI MCP Servers
content_type: reference
entities:
  - ai-mcp-server
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: MCP Server entity used by {{site.ai_gateway}} to expose tools and proxy MCP traffic.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayMCPServer
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
  - text: Consumer Group entity
    url: /ai-gateway/entities/consumer-group/
  - text: Kong MCP traffic gateway
    url: /mcp/
  - text: Model Context Protocol specification
    url: https://modelcontextprotocol.io/
faqs:
  - q: Which MCP protocol version does the runtime use?
    a: |
      The MCP runtime behind an MCP Server entity speaks MCP protocol version `2025-06-18`. Upstream
      MCP servers may run `2025-06-18` or `2025-11-25`. Versions from 2024 are not supported.

  - q: What's the difference between the four server types?
    a: |
      `passthrough-listener` proxies MCP traffic to an upstream MCP server without converting tools.
      `conversion-listener` converts a RESTful API into MCP tools and accepts MCP requests on the
      same Route. `conversion-only` defines a tool library that other MCP Servers reference by tag
      but doesn't accept incoming MCP traffic itself. `listener` aggregates tools from one or more
      `conversion-only` MCP Servers into a single MCP endpoint.

  - q: Can the same Consumer's identity gate access to specific tools?
    a: |
      Yes. Set `default_tool_acls` on the MCP Server with `allow` and `deny` lists, and override per
      tool through `tools[].acls`. A per-tool ACL replaces the default for that tool, it doesn't
      merge.

  - q: How do OAuth-based ACLs differ from Consumer-based ACLs?
    a: |
      Set `acl_attribute_type` to `oauth_access_token` and provide `access_token_claim_field` (a jq
      filter, for example `.user.email`). ACLs then evaluate against the claim value extracted from
      the OAuth access token instead of the resolved Consumer identity. The OAuth flow is supplied
      by the [AI MCP OAuth2 Policy](/plugins/ai-mcp-oauth2/).

  - q: What error code do denied requests return?
    a: |
      `HTTP 403 Forbidden`. Earlier {{site.ai_gateway}} versions returned the JSON-RPC error code
      `INVALID_PARAMS -32602`; from {{site.ai_gateway}} 3.14 onward, denials follow the
      [MCP 2025-11-25 authorization specification](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization#error-handling).

  - q: Can I attach the same authentication or rate-limiting plugin that I'd attach to a Route?
    a: |
      Plugin configuration that applies to the MCP Server goes through the
      [Policy entity](/ai-gateway/entities/policy/). Attach Policies to the MCP Server through its
      `policies` field.
---

## What is an MCP Server?

An MCP Server is a first-class {{site.ai_gateway}} entity that exposes tools to MCP-compatible clients (such as [Insomnia](https://konghq.com/products/kong-insomnia), [Claude](https://claude.ai/), [Cursor](https://cursor.com/), or [LM Studio](https://lmstudio.ai/)) over the [Model Context Protocol](https://modelcontextprotocol.io/). The runtime acts as a protocol bridge, translating between MCP and HTTP so MCP clients can either call existing APIs through {{site.ai_gateway}} or interact with upstream MCP servers.

Because the runtime executes inside {{site.ai_gateway}}, MCP endpoints are provisioned dynamically on demand. You don't host or scale them separately, and the same authentication, traffic control, and observability features available to traditional API traffic apply to MCP traffic at the same scale.

MCP Servers can be created and managed through {{site.konnect_short_name}}, the on-prem Admin API, decK, or the {{site.konnect_short_name}} UI:

{% table %}
columns:
  - title: Deployment
    key: deployment
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - deployment: "{{site.konnect_short_name}}"
    cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/mcp-servers
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/mcp-servers
{% endtable %}

## Common Policies

Attach plugins as [Policies](/ai-gateway/entities/policy/) on the MCP Server to handle authentication, rate limiting, observability, and traffic control:

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
      Apply [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) for MCP-spec OAuth 2.0 flows, or [OpenID Connect](/plugins/openid-connect/) / [Key Auth](/plugins/key-auth/) for non-OAuth identity.
  - use_case: Rate limiting
    example: |
      Use [Rate Limiting](/plugins/rate-limiting/) or [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) to control MCP request volume.
  - use_case: Observability
    example: |
      Add [logging and tracing plugins](/plugins/?category=logging) for full request and response visibility. MCP metrics surface in [{{site.konnect_short_name}} analytics](/ai-gateway/monitor-ai-llm-metrics/#mcp-traffic-metrics).
  - use_case: Traffic control
    example: |
      Apply [request and response transformation plugins](/plugins/?category=transformations) or [ACL policies](/plugins/acl/).
{% endtable %}
<!-- vale on -->

## Server modes

The `type` field selects one of four modes. Each mode determines how the runtime handles MCP requests and whether it converts RESTful APIs into MCP tools.

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
      {% new_in 3.13 %} Supports session identifiers set by authentication services for cookie-based
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
      from one or more `conversion-only` MCP Servers through `config.server.tag`.
    usecase: |
      A single MCP endpoint that aggregates tools from multiple `conversion-only` MCP Servers.
      Typical in multi-service or multi-team environments that expose a unified MCP interface.
{% endtable %}
<!-- vale on -->

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

Tools can also carry MCP-spec [annotations](#schema-aigateway-mcpserver-tools-annotations) that hint at tool behavior to clients (for example, whether a tool is read-only, idempotent, or destructive). Annotations don't change runtime behavior; they help clients decide whether to surface a tool, confirm before invocation, or treat it as safe to retry.

[Per-tool ACLs](#schema-aigateway-mcpserver-tools-acls) override the MCP Server's [default tool ACLs](#schema-aigateway-mcpserver-default-tool-acls). See [ACL tool control](#acl-tool-control).

## Sessions

`listener` and `conversion-listener` MCP Servers support managed sessions for stateful interactions. Configure session storage through `config.server.session`. The `passthrough-listener` mode doesn't use managed sessions because session state lives on the upstream MCP server.

Two session strategies:

1. **Client.** Session state is encrypted into the MCP session ID assigned to the client. Requires `secrets` which are encryption keys; the first entry is used for encryption, all entries are used for decryption to support key rotation.
1. **Redis.** Session state is stored in Redis. Configure connection details and authentication in `config.server.session.redis`.

{% include_cached /plugins/redis/redis-cloud-auth.md tier='enterprise' %}

`session_ttl` controls how long sessions live (default 24 hours). Set `managed: false` to disable managed sessions when the upstream maintains state externally.

Secrets used in session encryption can be referenced from a [Vault](/ai-gateway/entities/vault/).

## Server configuration

The `config.server` block carries runtime settings that apply across all tools on the MCP Server:

<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: field
  - title: Default
    key: default
  - title: Description
    key: description
rows:
  - field: "[`forward_client_headers`](#schema-aigateway-mcpserver-config-server-forward-client-headers)"
    default: "`true`"
    description: Whether to forward client request headers to the upstream when calling tools.
  - field: "[`tag`](#schema-aigateway-mcpserver-config-server-tag)"
    default: (none)
    description: A single tag used by `listener` MCP Servers to filter which `conversion-only` tools to expose.
  - field: "[`timeout`](#schema-aigateway-mcpserver-config-server-timeout)"
    default: 10 seconds
    description: Maximum time to wait for an upstream tool call.
{% endtable %}
<!-- vale on -->

[`config.max_request_body_size`](#schema-aigateway-mcpserver-config-max-request-body-size) controls the maximum incoming request body size accepted by the MCP Server (default 1 MB).

## ACL tool control

When exposing MCP servers through {{site.ai_gateway}}, you may need granular control over which authenticated API consumers can discover and invoke specific tools. The MCP Server's ACL feature lets you define access rules at both the default level (applying to all tools) and per-tool level (for fine-grained exceptions).

This way, consumers only interact with tools appropriate to their role, while maintaining a complete audit trail of all access attempts. Authentication is handled by an authentication Policy attached to the MCP Server (such as [Key Auth](/plugins/key-auth/) or an OIDC flow), and the resulting Consumer identity is used for ACL checks.

{:.info}
> **ACL in `listener` mode**
>
> Listener mode does not support direct ACL configuration. Instead, it inherits ACL rules from tagged `conversion-listener` or `conversion-only` MCP Servers.
>
> To use ACLs with `listener` mode:
> 1. Configure `conversion-listener` or `conversion-only` MCP Servers with ACL rules and tags.
> 1. Configure `listener` mode to aggregate tools by matching tags.
> 1. Set `include_consumer_groups: true` on the listener. Without this setting, the listener cannot pass Consumer Group membership to the aggregated tools, and ACL rules will not evaluate correctly.
>
> See [Enforce ACLs on aggregated MCP servers](/mcp/enforce-acls-on-aggregated-mcp-servers/) for a complete example.

### Attribute types

Two attribute types determine what the MCP Server evaluates ACL rules against:

1. **`consumer`** (default). Evaluates against the resolved Consumer identity.
1. **`oauth_access_token`**. Evaluates against a claim extracted from the OAuth access token. Set `access_token_claim_field` to a jq filter (for example, `.user.email` for a nested claim). The OAuth flow itself is supplied by the [AI MCP OAuth2 Policy](/plugins/ai-mcp-oauth2/).

### Supported identifier types

When `acl_attribute_type` is `consumer`, ACL rules can reference [Consumers](/gateway/entities/consumer/) and [Consumer Groups](/gateway/entities/consumer-group/) using these identifier types in `allow` and `deny` lists:

* [`username`](/gateway/entities/consumer/#schema-consumer-username): Consumer username
* [`id`](/gateway/entities/consumer/#schema-consumer-username): Consumer UUID
* [`custom_id`](/gateway/entities/consumer/#schema-consumer-custom-id): Custom Consumer identifier
* [`consumer_groups.name`](/gateway/entities/consumer/#schema-consumer-custom-id): Consumer Group name

The authenticated Consumer identity is matched against these identifiers. If the [Consumer](/gateway/entities/consumer/) or any of their [Consumer Groups](/gateway/entities/consumer-group/) match an ACL entry, the rule applies.

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
  participant ACL as MCP Server (ACL/Audit)
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

[Logging](#schema-aigateway-mcpserver-config-logging) captures three layers of MCP traffic: per-request statistics for telemetry, request and response payloads for full visibility, and [audit entries](/ai-gateway/ai-audit-log-reference/#ai-mcp-logs) for every ACL decision. Payload logging may expose sensitive data; enable it with care. MCP Server analytics surface in [{{site.konnect_short_name}} Explorer and Dashboards](/ai-gateway/monitor-ai-llm-metrics/#mcp-traffic-metrics) alongside other {{site.ai_gateway}} traffic, and export through [OpenTelemetry](/ai-gateway/ai-otel-metrics/#mcp-metrics).

## Attach Policies

Policies are how plugin configurations apply to an MCP Server. Authentication, rate limiting, request and response transformation, and OAuth gating (through [AI MCP OAuth2](/plugins/ai-mcp-oauth2/)) attach to the MCP Server through the `policies` field. Each entry is a string that references a Policy by name or ID. Multiple Policies can attach to one MCP Server; each runs as an independent plugin instance.

For details, see the [Policy entity](/ai-gateway/entities/policy/) reference.

## Scope of support

The MCP Server runtime supports MCP operations and upstream interactions, while certain advanced features and non-HTTP protocols are not currently supported. The table below summarizes what is supported and what is outside the current scope.

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

## Set up an MCP Server

The following example creates a `conversion-listener` MCP Server that converts a flight-booking REST API into a single `searchFlights` MCP tool, restricts access to the `internal-teams` Consumer Group, and stores managed sessions in client-side encrypted form.

{% entity_example %}
type: mcp-server
data:
  display_name: KongAir Flights
  name: kongair-flights
  type: conversion-listener
  acl_attribute_type: consumer
  acls:
    allow:
      - internal-teams
    deny: []
  default_tool_acls:
    allow:
      - internal-teams
    deny: []
  policies: []
  config:
    logging:
      statistics: true
      payloads: false
      audits: true
    max_request_body_size: 1048576
    server:
      forward_client_headers: true
      timeout: 10000
      session:
        managed: true
        strategy: client
        session_ttl: 86400
        client:
          secrets:
            - "{vault://my-vault/session-secret}"
  tools:
    - name: searchFlights
      description: Search for available flights between two airports.
      method: GET
      path: /flights
      annotations:
        title: Search flights
        read_only_hint: true
        idempotent_hint: true
{% endentity_example %}

## Schema

{% entity_schema %}
