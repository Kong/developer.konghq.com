---
title: AI Agents
content_type: reference
entities:
  - ai-agent
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-agent/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: AI Agent entity used by {{site.ai_gateway}} for A2A and HTTP agent configurations.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayAgent
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
  - text: A2A protocol specification
    url: https://a2aproject.github.io/A2A/
faqs:
  - q: What's the difference between an `a2a` AI Agent and an `http` AI Agent?
    a: |
      An `a2a` AI Agent applies Agent-to-Agent protocol awareness (JSON-RPC and REST binding detection,
      agent-card URL rewriting, structured A2A telemetry) to traffic flowing to an upstream agent.
      An `http` AI Agent is a generic HTTP route to an upstream agent without A2A-specific processing.
      Use `a2a` when the upstream speaks the A2A protocol and you want observability tied to A2A
      task and message semantics.

  - q: Does the AI Agent entity modify request routing or aggregate responses?
    a: |
      No. The runtime behind an AI Agent operates as a transparent proxy. It detects A2A requests,
      records telemetry, and rewrites agent-card URLs to the gateway address. It does not change
      routing decisions, merge responses, or hold task state on behalf of clients.

  - q: Why is the agent-card URL rewritten?
    a: |
      A2A clients use agent-card responses (at `/.well-known/agent-card.json`) to discover where to
      send subsequent requests. Rewriting the [`url`](#schema-aigateway-agent-config-url) field, and any [`additionalInterfaces[].url`](#schema-aigateway-agent-config-additional-interfaces-url)
      fields, to the {{site.ai_gateway}} address means clients route follow-up traffic through the
      gateway instead of bypassing it. The rewrite honors `X-Forwarded-*` headers when the gateway
      sits behind a load balancer.

  - q: How does streaming work?
    a: |
      Server-sent events (`Content-Type: text/event-stream`) pass through chunk-by-chunk without
      buffering. The runtime counts SSE events, captures time-to-first-byte, and extracts task state
      from the final event for analytics. Latency is preserved.

  - q: How do I limit which AI Consumers can reach an AI Agent?
    a: |
      Set the [`acls`](#schema-aigateway-agent-acls) field on the AI Agent with allow or deny lists. Each entry is a string that
      references an AI Consumer, AI Consumer Group, or Authenticated Group by name.

  - q: Can the same plugin run on an AI Agent that I'd attach to a route or service?
    a: |
      Plugin configuration that applies to the AI Agent goes through the [AI Policy entity](/ai-gateway/entities/ai-policy/).
      Attach AI Policies to the AI Agent through its [`policies`](#schema-aigateway-agent-policies) field.
---

## What is an AI Agent?

When you want to centrally manage agent routing, control access, and gain observability over agent traffic, use the AI Agent entity to expose upstream agents through {{site.ai_gateway}}. {{site.ai_gateway}}:

- Acts as a central point of contact for A2A clients
- Rewrites agent-card URLs so clients route through the gateway (not directly to agents)
- Enforces access controls via Access Control Lists (ACLs)
- Emits structured telemetry tied to agent operations.

The AI Agent entity supports two types: `a2a` for AI Agents that speak the [Agent-to-Agent protocol](https://a2aproject.github.io/A2A/), and `http` for standard HTTP AI Agents. See the [AI Agent types](#ai-agent-types) section for protocol-specific behavior and configuration guidance.

## Manage AI Agents

AI Agents can be created and managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/agents`

For configuration examples and step-by-step setup instructions, see the following [Set up an AI Agent](#set-up-an-ai-agent) section.

## AI Agent types

Choose an AI Agent type based on your upstream and observability needs. The [`type`](#schema-aigateway-agent-type) controls how requests are processed:

<!-- vale off -->
{% table %}
columns:
  - title: Type
    key: type
  - title: Use case
    key: use_case
rows:
  - type: "`a2a`"
    use_case: "Agents that speak the [Agent-to-Agent protocol](https://a2aproject.github.io/A2A/). {{site.ai_gateway}} applies protocol awareness, detects A2A requests (JSON-RPC and REST bindings), rewrites agent-card URLs to the gateway address, emits structured A2A telemetry, and extracts task metadata for analytics. Use when you want full observability tied to A2A semantics."
  - type: "`http`"
    use_case: "Standard HTTP agent endpoints. Requests pass through transparently as a generic HTTP proxy without A2A-specific processing. Use for upstream agents that don't implement A2A or when you need simple transparent proxying without protocol-aware behavior."
{% endtable %}
<!-- vale on -->

## Use cases for AI Agents

Common use cases for exposing agents through {{site.ai_gateway}}:

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "Observability and telemetry"
    description: "Emit structured A2A telemetry and extract task metadata for analytics. Track agent performance, request patterns, and error rates tied to A2A task semantics. Use for production agent deployments where visibility into agent traffic is critical. See [Logging and observability](#logging-and-observability) for details on telemetry collection and OpenTelemetry integration."
  - use_case: "Authentication and access control"
    description: "Require agents to authenticate clients via [OpenID Connect](/ai-gateway/policies/openid-connect/) or other auth policies before routing requests. Restrict which [AI Consumers](/ai-gateway/entities/ai-consumer/) or [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) can reach specific agents via ACLs."
  - use_case: "Rate limiting"
    description: "Enforce per-agent or per-consumer rate limits to prevent overload and manage agent resource usage. Use [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) to set token or request quotas per consumer."
  - use_case: "Policy enforcement"
    description: "Attach [AI Policies](/ai-gateway/entities/ai-policy/) to agents for request transformation, PII detection, input validation, and request logging. Layer security and governance controls on agent traffic."
  - use_case: "Centralized discovery"
    description: "Provide A2A clients with a single, stable gateway endpoint (via agent-card URL rewriting) instead of having them discover and connect directly to agent instances."
{% endtable %}
<!-- vale on -->

## How A2A traffic flows

When an Agent has type `a2a`, proxied traffic is processed in four phases:

1. **Access**. Detects whether the request is an A2A operation (JSON-RPC or REST binding). When statistics logging is enabled, this starts an OpenTelemetry span and records the request body for payload logging if that's also enabled.
1. **Header filter**. Detects streaming responses (`Content-Type: text/event-stream`) and records time to first byte. Buffers agent-card responses for URL rewriting.
1. **Body filter**. Streams SSE chunks through to the client without buffering. Buffers non-streaming responses to extract task metadata. Rewrites agent-card URLs to the gateway address. Emits analytics at end of response.
1. **Log**. Finalizes the OpenTelemetry span with task state, task ID, and any error information.

Non-A2A traffic, and traffic to `http` Agents, is proxied without these steps.

## Routing configuration

Beyond the [`url`](#schema-aigateway-agent-config-url) field, AI Agents can define HTTP routing rules through [`config.route`](#schema-aigateway-agent-config-route). This allows you to match requests by method, path, host, and other HTTP patterns. Use [`route`](#schema-aigateway-agent-config-route) when you need fine-grained control over which traffic reaches the AI Agent. If only a URL is needed, the [`url`](#schema-aigateway-agent-config-url) field is simpler.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client as A2A Client
    participant Gateway as {{site.ai_gateway}}<br>(Agent)
    participant Agent as Upstream A2A Agent

    Client->>Gateway: A2A request (JSON-RPC or REST)
    Note over Gateway: Detect A2A binding and method<br>Start OTel span (if logging enabled)

    Gateway->>Agent: Proxied request<br>(Accept-Encoding removed if logging enabled)

    alt Streaming response (SSE)
        Agent-->>Gateway: text/event-stream chunks
        Note over Gateway: Pass through each chunk<br>Count SSE events, track TTFB
        Gateway-->>Client: SSE chunks (unchanged)
        Note over Gateway: On final chunk:<br>Extract task state, set analytics
    else Non-streaming response
        Agent->>Gateway: JSON response
        Note over Gateway: Buffer response<br>Extract task metadata
        Gateway->>Client: Response (unchanged)
    end

    Note over Gateway: Finish OTel span<br>Emit ai.a2a metrics to log plugins
{% endmermaid %}
<!-- vale on -->

## Core A2A protocol elements

A2A defines the communication elements between agents. The {{site.ai_gateway}} runtime surfaces data tied to these elements in log output and OpenTelemetry spans for `a2a` Agents.

{% table %}
columns:
  - title: Element
    key: element
  - title: Description
    key: description
  - title: Purpose
    key: purpose
rows:
  - element: Agent Card
    description: A JSON metadata document describing an agent's identity, capabilities, endpoint, skills, and authentication requirements.
    purpose: Enables clients to discover agents and understand how to interact with them.
  - element: Task
    description: A stateful unit of work initiated by an agent, with a unique ID and defined lifecycle.
    purpose: Tracks long-running operations and supports multi-turn interactions.
  - element: Message
    description: A single turn of communication between a client and an agent, containing content and a role (`user` or `agent`).
    purpose: Conveys instructions, context, questions, answers, or status updates that are not formal artifacts.
  - element: Part
    description: The fundamental content container (for example, `TextPart`, `FilePart`, `DataPart`) used within messages and artifacts.
    purpose: Provides flexibility for agents to exchange different content types within messages and artifacts.
  - element: Artifact
    description: A tangible output generated by an agent during a task (for example, a document, image, or structured data).
    purpose: Carries the concrete output of a task in a structured, retrievable form.
{% endtable %}

### Protocol detection

A2A traffic is auto-detected per request and non-A2A traffic passes through without overhead.

#### REST binding

Detection anchors to the end of the request path, so any prefix added by the route is ignored. For example, both `/v1/message:send` and `/api/agents/v1/message:send` match `SendMessage`:

<!-- vale off -->
{% table %}
columns:
  - title: HTTP method
    key: method
  - title: Path suffix
    key: path
  - title: A2A operation
    key: operation
  - title: Canonical method
    key: canonical
rows:
  - method: "`POST`"
    path: "`/v1/message:send`"
    operation: SendMessage
    canonical: "`message/send`"
  - method: "`POST`"
    path: "`/v1/message:stream`"
    operation: SendStreamingMessage
    canonical: "`message/stream`"
  - method: "`GET`"
    path: "`/.well-known/agent-card.json`"
    operation: GetAgentCard
    canonical: "`agent/getCard`"
  - method: "`GET`"
    path: "`/v1/extendedAgentCard`"
    operation: GetExtendedAgentCard
    canonical: "`agent/getExtendedAgentCard`"
  - method: "`GET`"
    path: "`/v1/tasks/{id}`"
    operation: GetTask
    canonical: "`tasks/get`"
  - method: "`GET`"
    path: "`/v1/tasks`"
    operation: ListTasks
    canonical: "`tasks/list`"
  - method: "`POST`"
    path: "`/v1/tasks/{id}:cancel`"
    operation: CancelTask
    canonical: "`tasks/cancel`"
  - method: "`POST`"
    path: "`/v1/tasks/{id}:subscribe`"
    operation: SubscribeToTask
    canonical: "`tasks/resubscribe`"
  - method: "`POST`"
    path: "`/v1/tasks`"
    operation: ListTasks
    canonical: "`tasks/list`"
{% endtable %}
<!-- vale on -->

The canonical method name is what appears in OpenTelemetry span attributes and log output.

#### JSON-RPC binding

Detected by the `"jsonrpc"` field in the request body, combined with a recognized A2A method name or an `A2A-Version` request header. Recognized methods include `message/send`, `message/stream`, `tasks/get`, `tasks/list`, `tasks/cancel`, `tasks/resubscribe`, the `tasks/pushNotificationConfig/*` family, and `agent/getExtendedAgentCard`.

A request carrying an `A2A-Version` header is treated as JSON-RPC even if the method isn't in the recognized list. When an unknown method is accepted this way, the `method` field in log output is recorded as `"unknown"` to bound metric cardinality. The OpenTelemetry span's `kong.a2a.operation` attribute still receives the actual method name.

### Agent-card URL rewriting

When an upstream agent returns an agent card, the runtime rewrites the [`url`](#schema-aigateway-agent-config-url) field, and any `additionalInterfaces[].url` fields, to the {{site.ai_gateway}} address. A2A clients then discover the gateway as the canonical endpoint instead of contacting the upstream directly. The rewrite uses `X-Forwarded-*` headers to construct the correct scheme, host, and port when the gateway is deployed behind a load balancer or reverse proxy.

## Logging and observability

To track agent performance, debug issues, and monitor A2A traffic patterns, enable statistics logging. {{site.ai_gateway}} emits structured A2A telemetry that flows to {{site.konnect_short_name}} analytics, logging plugins, and OpenTelemetry for full visibility into agent operations.

The telemetry data is emitted into the `ai.a2a` namespace (consumed by {{site.konnect_short_name}} analytics and logging plugins) and creates a `kong.a2a` child span when you've configured [{{site.base_gateway}} tracing](/gateway/tracing/). For the canonical metric and attribute list, see [A2A metrics](/ai-gateway/ai-otel-metrics/#a2a-metrics).

{:.info}
> When statistics logging is enabled, the runtime removes the `Accept-Encoding` request header
> before forwarding to the upstream. This prevents compressed responses that the runtime can't
> parse for metadata extraction.

Payload logging additionally captures request and response bodies. Payloads are truncated at the configured payload size limit.

{:.warning}
> Payload logging may expose sensitive data. Only enable it when you're prepared to handle
> request and response bodies in your logging pipeline.

You can view A2A analytics in {{site.konnect_short_name}} Explorer and Dashboards through the [Agentic usage analytics](/observability/explorer/?tab=agentic-usage#metrics) view.

### Log output fields

{% include /plugins/ai-a2a-proxy/log-output-fields.md %}

### OpenTelemetry span attributes

When statistics logging is enabled and {{site.base_gateway}} tracing is configured, the runtime creates a `kong.a2a` child span with the following attributes:

{% include /plugins/ai-a2a-proxy/otel-span-attributes.md %}

## Access control

To restrict which consumers or teams can reach a specific agent, use ACLs. The [`acls`](#schema-aigateway-agent-acls) field defines `allow` and `deny` lists of identities that can access the agent. Each entry references an [AI Consumer](/ai-gateway/entities/ai-consumer/), [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/), or Authenticated Group by name. An **Authenticated Group** is a dynamic group representing all consumers authenticated via a specific OAuth2 scope or claim. Access is enforced before traffic reaches the upstream agent.

For per-request authentication and identity validation, attach an authentication AI Policy to the AI Agent.

## Attach AI Policies

To enforce security, transformation, or governance controls on agent traffic (for example, request validation, PII detection, request logging), attach [AI Policies](/ai-gateway/entities/ai-policy/) to the agent. Add policy names or IDs to the AI Agent's [`policies`](#schema-aigateway-agent-policies) field. Multiple AI Policies can attach to one AI Agent; each runs independently in the request lifecycle.

For available policy types and configuration, see the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference.

## Set up an Agent

The following example creates an `a2a` Agent that proxies traffic to an upstream A2A agent at `https://booking-agent.internal.kongair.com`, with statistics logging enabled and access restricted to the `internal-teams` Consumer Group.

{% entity_example %}
type: agent
data:
  display_name: KongAir Flight Booking Agent
  name: kongair-flight-booking-agent
  type: a2a
  acls:
    allow:
      - internal-teams
    deny: []
  policies: []
  config:
    url: https://booking-agent.internal.kongair.com
    logging:
      statistics: true
      payloads: false
      max_payload_size: 1048576
{% entity_example %}
type: agent
data:
  display_name: KongAir Flight Booking Agent
  name: kongair-flight-booking-agent
  type: a2a
  acls:
    allow:
      - internal-teams
  policies: []
  config:
    url: https://booking-agent.internal.kongair.com
    route:
      paths:
        - /kongair-flight-booking
    logging:
      statistics: true
      payloads: false
      max_payload_size: 1048576
{% endentity_example %}

## Schema

{% entity_schema %}
