---
title: AI Agents
content_type: reference
entities:
  - ai-agent
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: Agent entity used by {{site.ai_gateway}} for A2A and HTTP agent configurations.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayAgent
works_on:
  - konnect
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
  - text: A2A protocol specification
    url: https://a2aproject.github.io/A2A/
faqs:
  - q: What's the difference between an `a2a` Agent and an `http` Agent?
    a: |
      An `a2a` Agent applies Agent-to-Agent protocol awareness (JSON-RPC and REST binding detection,
      agent-card URL rewriting, structured A2A telemetry) to traffic flowing to an upstream agent.
      An `http` Agent is a generic HTTP route to an upstream agent without A2A-specific processing.
      Use `a2a` when the upstream speaks the A2A protocol and you want observability tied to A2A
      task and message semantics.

  - q: Does the Agent entity modify request routing or aggregate responses?
    a: |
      No. The runtime behind an Agent operates as a transparent proxy. It detects A2A requests,
      records telemetry, and rewrites agent-card URLs to the gateway address. It does not change
      routing decisions, merge responses, or hold task state on behalf of clients.

  - q: Why is the agent-card URL rewritten?
    a: |
      A2A clients use agent-card responses (at `/.well-known/agent-card.json`) to discover where to
      send subsequent requests. Rewriting the `url` field, and any `additionalInterfaces[].url`
      fields, to the {{site.ai_gateway}} address means clients route follow-up traffic through the
      gateway instead of bypassing it. The rewrite honors `X-Forwarded-*` headers when the gateway
      sits behind a load balancer.

  - q: How does streaming work?
    a: |
      Server-sent events (`Content-Type: text/event-stream`) pass through chunk-by-chunk without
      buffering. The runtime counts SSE events, captures time-to-first-byte, and extracts task state
      from the final event for analytics. Latency is preserved.

  - q: How do I limit which consumers can reach an Agent?
    a: |
      Set the `acls` field on the Agent with allow or deny lists. Each entry is a string that
      references a Consumer, Consumer Group, or Authenticated Group by name.

  - q: Can the same plugin run on an Agent that I'd attach to a route or service?
    a: |
      Plugin configuration that applies to the Agent goes through the [Policy entity](/ai-gateway/entities/policy/).
      Attach Policies to the Agent through its `policies` field.

  - q: How do I configure agents in on-prem deployments?
    a: |
      {{site.ai_gateway}} entities are available only in {{site.konnect_short_name}}.
      For on-prem deployments, configure agent proxying using {{site.base_gateway}} plugins directly (for example, the AI A2A Proxy plugin).
      See the [{{site.base_gateway}} plugin catalog](/gateway/plugins/) for available AI-related plugins.
---

## What is an Agent?

An Agent is a first-class {{site.ai_gateway}} entity that represents an upstream agent endpoint exposed through {{site.ai_gateway}}. An Agent has a type, either `a2a` for [Agent-to-Agent protocol](https://a2aproject.github.io/A2A/) traffic or `http` for generic HTTP agent routing, and a configuration that points {{site.ai_gateway}} at the upstream and shapes how requests flow.

For `http` type Agents, requests are proxied without A2A-specific processing. For `a2a` type Agents, {{site.ai_gateway}} adds protocol-aware behavior on top of plain proxying: it detects A2A requests across both JSON-RPC and REST bindings, rewrites agent-card URLs so clients discover the gateway as the canonical endpoint, and emits structured A2A telemetry to {{site.konnect_short_name}} analytics and OpenTelemetry.

Agents can be created and managed through the {{site.konnect_short_name}} UI, the {{site.ai_gateway}} API, or decK:

{% table %}
columns:
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/agents
{% endtable %}

## How A2A traffic flows

When an Agent has type `a2a`, proxied traffic is processed in four phases:

1. **Access**. Detects whether the request is an A2A operation (JSON-RPC or REST binding). When statistics logging is enabled, this starts an OpenTelemetry span and records the request body for payload logging if that's also enabled.
1. **Header filter**. Detects streaming responses (`Content-Type: text/event-stream`) and records time to first byte. Buffers agent-card responses for URL rewriting.
1. **Body filter**. Streams SSE chunks through to the client without buffering. Buffers non-streaming responses to extract task metadata. Rewrites agent-card URLs to the gateway address. Emits analytics at end of response.
1. **Log**. Finalizes the OpenTelemetry span with task state, task ID, and any error information.

Non-A2A traffic, and traffic to `http` Agents, is proxied without these steps.

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

A2A defines the communication elements between agents. The runtime surfaces data tied to these elements in log output and OpenTelemetry spans for `a2a` Agents.

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

When an upstream agent returns an agent card, the runtime rewrites the `url` field, and any `additionalInterfaces[].url` fields, to the {{site.ai_gateway}} address. A2A clients then discover the gateway as the canonical endpoint instead of contacting the upstream directly. The rewrite uses `X-Forwarded-*` headers to construct the correct scheme, host, and port when the gateway is deployed behind a load balancer or reverse proxy.

## Logging and observability

When Statistics logging is enabled, {{site.ai_gateway}} records structured A2A telemetry per request and exposes it in {{site.konnect_short_name}} analytics, attached log plugins, and OpenTelemetry when [{{site.base_gateway}} tracing](/gateway/tracing/) is configured. For the canonical metric and attribute list, see [A2A metrics](/ai-gateway/ai-otel-metrics/#a2a-metrics).

The runtime emits this data into the `ai.a2a` namespace consumed by {{site.konnect_short_name}} analytics and any attached logging plugins, and creates a `kong.a2a` child span when [{{site.base_gateway}} tracing](/gateway/tracing/) is configured.

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

### Task states

Task state values surfaced in logs and spans are normalized to lowercase A2A spec format, regardless of the upstream SDK version: `submitted`, `working`, `input-required`, `completed`, `canceled`, `failed`, `rejected`, `auth-required`, `unknown`.

## Access control

The `acls` field controls which identities are allowed to reach the Agent. The field accepts `allow` and `deny` lists. Each entry is a string that references a Consumer, Consumer Group, or Authenticated Group by name. Access is enforced before traffic reaches the upstream agent.

For per-request authentication and identity, attach an authentication Policy to the Agent.

## Attach Policies

Policies are how plugin configurations apply to an Agent. Attach them through the Agent's `policies` field. Each entry is a string that references a Policy by name or ID. Multiple Policies can attach to one Agent; each runs as an independent plugin instance.

For details, see the [Policy entity](/ai-gateway/entities/policy/) reference.

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
    max_payload_size: 524288
{% endentity_example %}

## Schema

{% entity_schema %}
