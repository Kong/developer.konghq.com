---
description: 'Detect and redact personally identifiable information (PII) in MCP tool call arguments and results.'
min_version:
  ai-gateway: '2.0' # TODO: confirm. Aha AI-46 targets the 2.3 GA release (2026-10-29) as Tech Preview.
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
tech_preview: true
categories:
  - ai
tags:
  - ai
  - mcp
  - dlp
  - security
related_resources:
  - text: AI PII Sanitizer Policy
    url: /ai-gateway/policies/ai-sanitizer/
  - text: AI MCP Server
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Policy
    url: /ai-gateway/entities/ai-policy/
  - text: MCP version support
    url: /ai-gateway/mcp-version-support/
  - text: Model Context Protocol specification
    url: https://modelcontextprotocol.io/
published: false
---

<!-- TODO: Drafted from kong-ee PR #23501 (draft), Aha AI-46, and the MCP PII sanitizer PRD and design doc. No Konnect API spec was available. Confirm every field name, default, scope, and error behavior against the spec, then remove `published: false`. The Aha description and PRD still describe the earlier `mcp-pii-sanitizer` design (`sanitization_mode`, per-leaf calls). PR #23501 is the source for this page. -->

The AI MCP Sanitizer Policy detects and redacts personally identifiable information (PII) in [Model Context Protocol (MCP)](/mcp/) `tools/call` traffic on {{site.ai_gateway}}.
It can sanitize the arguments an agent sends to a tool, the result a tool returns, or both.

MCP tools often front systems of record such as CRMs, ticketing tools, and medical or financial databases, where arguments and results routinely carry PII.
The [AI PII Sanitizer Policy](/ai-gateway/policies/ai-sanitizer/) can't protect this traffic, because it expects chat-completion bodies and not MCP's JSON-RPC `params` and `result` structures.
The AI MCP Sanitizer Policy adds PII sanitization to MCP traffic proxied by an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).

The Policy uses the same PII service, PII categories, custom patterns, blocking, and recovery options as the AI PII Sanitizer Policy.
If you already use that Policy, the connection and detection settings work the same way.

## What gets sanitized

The Policy sanitizes the `tools/call` method only.
It doesn't sanitize other MCP methods, such as `resources/read` or `prompts/get`.

You choose what to sanitize with `sanitize_targets`.
Each target names a location in the MCP protocol instead of an abstract direction:

{% table %}
columns:
  - title: Target
    key: target
  - title: Direction
    key: direction
  - title: Use it to
    key: use
rows:
  - target: "`tool_arguments`"
    direction: "The `tools/call` request, from {{site.ai_gateway}} to the tool server"
    use: Prevent a third-party tool from receiving user data.
  - target: "`tool_results`"
    direction: "The `tools/call` response, from the tool server through {{site.ai_gateway}} to the calling agent"
    use: Prevent data from a system of record from appearing in the LLM context.
{% endtable %}

You can enable either target, or both.
The default is `tool_arguments`.

{{site.ai_gateway}} sanitizes only the fields that carry user data:

* **Sanitized:** string values in the tool call arguments, `text` entries in `result.content[]`, and string values in `result.structuredContent`.
* **Not sanitized:** the tool name, JSON-RPC envelope fields such as `jsonrpc` and `id`, `result.isError`, `result._meta`, and `result.content[]` entries of type `image`, `audio`, or `resource`.

Rewriting tool names and protocol fields would break tool dispatch, access control, and protocol negotiation.
Skipping binary content avoids sending large payloads to the PII service for no benefit.

<!-- TODO: confirm the exact set of sanitized fields against the final PR and spec. -->

## How it works

The AI MCP Sanitizer Policy sanitizes a `tools/call` request and its result in the following order:

1. A client sends a `tools/call` request to the AI MCP Server.
1. {{site.ai_gateway}} authorizes the request and applies rate limiting.
   {{site.ai_gateway}} rejects a request that fails either check before it calls the PII service.
1. If `tool_arguments` is targeted, the Policy sends the argument text to the PII service and replaces each value with its sanitized version.
1. {{site.ai_gateway}} forwards the sanitized request to the tool server.
1. If `tool_results` is targeted, {{site.ai_gateway}} holds the complete result from the tool server, the Policy sends its text to the PII service, and {{site.ai_gateway}} returns the sanitized result to the agent.

{% mermaid %}
sequenceDiagram
    autonumber
    participant Agent as MCP client
    participant Kong as AI MCP Server
    participant PII as PII service
    participant Tool as MCP tool server

    Agent->>Kong: tools/call request
    Kong->>Kong: Authorize and rate limit
    Kong->>PII: Send argument text (tool_arguments)
    PII->>Kong: Return sanitized text
    Kong->>Tool: Forward sanitized request
    Tool->>Kong: Return result
    Kong->>PII: Send result text (tool_results)
    PII->>Kong: Return sanitized text
    Kong->>Agent: Return sanitized result
{% endmermaid %}

{:.info}
> {{site.ai_gateway}} never sanitizes the authentication tools that it handles itself, because their arguments are credentials and not user PII.
<!-- TODO: confirm the user-facing name of these tools -->

### Supported server types

The Policy works with the `passthrough-listener`, `listener`, and `conversion-listener` AI MCP Server types.
It handles both JSON and SSE-framed responses, and re-frames sanitized SSE responses automatically.
<!-- TODO: confirm behavior for `conversion-only` and `upstream-server` types -->

## Streaming and performance trade-offs

Sanitizing a tool result requires the complete result before {{site.ai_gateway}} sends any of it to the agent.
The PII service scores text as a whole, and a placeholder can't replace bytes that {{site.ai_gateway}} has already sent.
For that reason, targeting `tool_results` changes how some server types proxy traffic:

{% table %}
columns:
  - title: Server type
    key: type
  - title: What changes
    key: change
  - title: Effect
    key: effect
rows:
  - type: "`passthrough-listener`"
    change: "{{site.ai_gateway}} holds a streamed `tools/call` response and releases it as one body."
    effect: "For an upstream that streams a response incrementally, time to first byte becomes time to last byte. An SSE response that contains one complete message isn't affected."
  - type: "`conversion-listener`"
    change: "{{site.ai_gateway}} disables single-pass conversion for converter tools that the AI MCP Server owns, and sends the call to the upstream as a separate request."
    effect: "Each call opens one additional outbound connection and doesn't use the load balancer, retries, upstream TLS or mTLS settings, the keepalive pool, or the configured timeouts."
{% endtable %}

Enabling `recover_redacted` has the same effect, because {{site.ai_gateway}} must hold the result to restore placeholders in it.

These changes reverse when you remove `tool_results` from `sanitize_targets` and disable `recover_redacted`.
A configuration that targets only `tool_arguments` without recovery doesn't change streaming or single-pass behavior.
{{site.ai_gateway}} never buffers long-lived streams, such as `subscriptions/listen` and GET-initiated SSE.

{:.warning}
> Each sanitized call adds at least one round trip to the PII service. Load test the PII service with your largest and most deeply nested tool payloads before you enable the Policy in production.
<!-- TODO: confirm the call pattern. The PRD describes one call per string value. The design doc and PR describe batched calls. -->

## Block instead of redact

When `block_if_detected` is `true` and the PII service finds sensitive data, {{site.ai_gateway}} rejects the call instead of redacting it:

* For `tool_arguments`, the agent receives a JSON-RPC error and the request doesn't reach the tool server.
* For `tool_results`, {{site.ai_gateway}} replaces the result with a JSON-RPC error.

The error uses the format and HTTP status that match the client's [MCP protocol revision](/ai-gateway/mcp-version-support/).
<!-- TODO: confirm the error code and message -->

## Recover redacted values

When `recover_redacted` is `true`, the tool server receives placeholders instead of the original values.
If the tool returns a placeholder in its result, {{site.ai_gateway}} restores the original value before it sends the result to the agent.

<!-- TODO: PR #23501 shares its entity checks with ai-sanitizer, which rejects `recover_redacted: true` when the Policy sanitizes output. Confirm whether that rule applies to `tool_results`, and document the valid combinations. -->

## Error handling

The AI MCP Sanitizer Policy uses `stop_on_error` to decide what happens when the PII service is unreachable, returns a non-200 response, or returns a malformed response.
<!-- TODO: confirm the default (`true` in the PRD) and the behavior of each value for both targets -->
When the service returns fewer entries than {{site.ai_gateway}} sent, the behavior is still being decided.
<!-- TODO: design doc open question 2 -->

## Differences from the AI PII Sanitizer Policy

The AI MCP Sanitizer Policy shares most settings with the AI PII Sanitizer Policy.
The following table lists the settings that differ:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: AI PII Sanitizer
    key: sanitizer
  - title: AI MCP Sanitizer
    key: mcp
rows:
  - setting: Targeting
    sanitizer: "`sanitization_mode`: `INPUT`, `OUTPUT`, or `BOTH`"
    mcp: "`sanitize_targets`: `tool_arguments`, `tool_results`, or both"
  - setting: "`allow_all_conversation_history`"
    sanitizer: Supported
    mcp: Not available. Conversation history is an LLM concept.
  - setting: "`continue_on_detection`, `rejection_mode`"
    sanitizer: Supported
    mcp: Not available in the first release. <!-- TODO confirm -->
{% endtable %}

`INPUT`, `OUTPUT`, and `BOTH` are ambiguous on MCP traffic, because an AI MCP Server is both a server to the agent and a client of the tool server.
`sanitize_targets` names the protocol location instead.

## PII service

The AI MCP Sanitizer Policy uses the same external PII service as the AI PII Sanitizer Policy.
For the Docker images, the `anonymize` categories, redact modes, custom patterns, and HTTPS setup, see [AI PII Anonymizer service](/ai-gateway/policies/ai-sanitizer/#ai-pii-anonymizer-service).
You run the PII service in your own environment.

## Logging and analytics

<!-- TODO: PRD and design doc say sanitization counts (identified, sanitized, duration, items) are added to the MCP statistics when logging statistics is enabled, and that `skip_logging_sanitized_items` omits the item details. PR #23501 moves MCP logging into an `emit-mcp-log` filter. Confirm the field names and add a link to the audit log reference. -->

## Configuration notes

* `anonymize` must contain at least one value. The default is `all_and_credentials`.
* If `anonymize` includes `custom`, you must set `custom_patterns`. Each pattern needs a `name`, a `regex`, and a `score` between 0 and 1.
* `sanitize_targets` must contain at least one target.

<!-- TODO: Add entity examples and the scope and attachment model for AI MCP Server once the spec is available. -->
