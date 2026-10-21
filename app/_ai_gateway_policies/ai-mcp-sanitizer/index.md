---
title: 'AI MCP Sanitizer'
name: 'AI MCP Sanitizer'
publisher: kong-inc
description: 'Detect and redact personally identifiable information (PII) in MCP tool call arguments and results.'
min_version:
  ai-gateway: '2.3'
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
---

The AI MCP Sanitizer Policy detects and redacts personally identifiable information (PII) in [Model Context Protocol (MCP)](/ai-gateway/mcp/) `tools/call` traffic on {{site.ai_gateway}}.
It can sanitize the arguments an agent sends to a tool, the result a tool returns, or both.

MCP tools often front systems of record such as CRMs, ticketing tools, and medical or financial databases, where arguments and results routinely contain PII.
The [AI PII Sanitizer Policy](/ai-gateway/policies/ai-sanitizer/) can't protect this traffic, because it only processes chat-completion bodies and not MCP's JSON-RPC `params` and `result` structures.
The AI MCP Sanitizer Policy adds PII sanitization to MCP traffic proxied by an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).

The Policy uses the same [PII service](#ai-pii-anonymizer-service), PII categories, custom patterns, blocking, and recovery options as the AI PII Sanitizer Policy.
If you already use that Policy, the connection and detection settings work the same way.

## Use cases

Use the AI MCP Sanitizer Policy in the following situations:

{% table %}
columns:
  - title: Problem to solve
    key: situation
  - title: Typical scenario
    key: example
  - title: What to configure
    key: config
rows:
  - situation: Customer data goes into a third-party tool.
    example: "An agent puts a customer's Social Security number into the arguments of a CRM or ticketing tool call."
    config: "Target `tool_arguments` so the tool server receives redacted values."
  - situation: A system of record returns sensitive records.
    example: "A tool returns a medical or financial record, and you don't want that record in the LLM context."
    config: "Target `tool_results` so the agent receives a sanitized result."
  - situation: A call must not proceed if it contains PII.
    example: "A tool must never receive or return PII, and a redacted call isn't acceptable."
    config: "Set [`block_if_detected`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-block-if-detected) to `true` to [reject the call](#block-instead-of-redact) instead of redacting it."
  - situation: Your data includes identifiers that the built-in categories don't cover.
    example: "Your systems use employee IDs in the format `EMP-123456`."
    config: "Add [`custom_patterns`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-custom-patterns) with a regular expression for the identifier, and include `custom` in [`anonymize`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-anonymize)."
  - situation: A tool must work with placeholders, but the agent needs the real values back.
    example: "The tool returns a placeholder it received in the arguments."
    config: "Set [`recover_redacted`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-recover-redacted) to `true` to [restore the original values](#recover-redacted-values) in the tool result."
{% endtable %}

## What gets sanitized

The Policy sanitizes the `tools/call` method only.
It doesn't sanitize other MCP methods, such as `resources/read` or `prompts/get`.

You choose what to sanitize with [`sanitize_targets`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-sanitize-targets).
Each target names a location in the MCP protocol instead of an abstract direction:

{% table %}
columns:
  - title: Target
    key: target
  - title: Direction
    key: direction
rows:
  - target: "`tool_arguments`"
    direction: "The `tools/call` request, from {{site.ai_gateway}} to the tool server"
  - target: "`tool_results`"
    direction: "The `tools/call` response, from the tool server through {{site.ai_gateway}} to the calling agent"
{% endtable %}

You can enable either target, or both.
The default is `tool_arguments`.

{{site.ai_gateway}} sanitizes only the fields that contain user data:

* **Sanitized:** string values in the tool call arguments, `text` entries in `result.content[]`, and string values in `result.structuredContent`.
* **Not sanitized:** the tool name, JSON-RPC envelope fields such as `jsonrpc` and `id`, `result.isError`, `result._meta`, and `result.content[]` entries of type `image`, `audio`, or `resource`.

Rewriting tool names and protocol fields would break tool dispatch, access control, and protocol negotiation.
Skipping binary content avoids sending large payloads to the PII service for no benefit.

## Choose what to sanitize

Choose targets based on which direction of the tool call includes PII and whether you need streaming:

* **Sanitize only `tool_arguments`** if your agents send user data to a third-party tool and you need to keep streaming.
  This target doesn't hold responses or change how [`conversion-listener`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-type) servers run, so the [streaming and single-pass changes](#streaming-and-performance-trade-offs) don't apply.
  Set `recover_redacted` to `false` as well, because enabling it also holds the result.
* **Sanitize only `tool_results`** if your tools return records from a system of record, such as a CRM or a medical database, and you want to keep that data out of the LLM context.
  {{site.ai_gateway}} forwards the arguments to the tool server unchanged.
  Set `recover_redacted` to `false`, because you can't use recovery when `tool_results` is a target.
* **Sanitize both** if user data goes to the tool and the tool returns PII too.
  The streaming and single-pass changes apply because `tool_results` is targeted.
  Set `recover_redacted` to `false`, because you can't use recovery when `tool_results` is a target.

## How it works

The AI MCP Sanitizer Policy sanitizes a `tools/call` request and its result in the following order:

1. A client sends a `tools/call` request to the AI MCP Server.
1. {{site.ai_gateway}} authorizes the request and applies rate limiting.
   {{site.ai_gateway}} rejects a request that fails either check before it calls the PII service.
1. If `tool_arguments` is targeted, the Policy sends the argument text to the PII service and replaces each value with its sanitized version.
1. {{site.ai_gateway}} forwards the sanitized request to the tool server.
1. If `tool_results` is targeted, {{site.ai_gateway}} holds the complete result from the tool server.
   The Policy sends the result text to the PII service.
   {{site.ai_gateway}} then returns the sanitized result to the agent.

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

### Supported server types

The Policy works with the [`passthrough-listener`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-type), [`listener`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-type), and [`conversion-listener`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-type) AI MCP Server types.
It handles both JSON and SSE-framed responses, and re-frames sanitized SSE responses automatically.

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
  - type: "[`passthrough-listener`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-type)"
    change: "{{site.ai_gateway}} buffers a streamed `tools/call` response and sends it as one body."
    effect: "For an upstream that streams a response incrementally, time to first byte becomes time to last byte. An SSE response that contains one complete message isn't affected."
  - type: "[`conversion-listener`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-type)"
    change: "{{site.ai_gateway}} disables single-pass conversion for converter tools that the AI MCP Server owns, and sends the call to the upstream as a separate request."
    effect: "Each call opens one additional outbound connection and doesn't use the load balancer, retries, upstream TLS or mTLS settings, the keepalive pool, or the configured timeouts."
{% endtable %}

Enabling `recover_redacted` also requires {{site.ai_gateway}} to hold the result, so the same changes apply.

These changes reverse when you remove `tool_results` from `sanitize_targets` and disable `recover_redacted`.
A configuration that targets only `tool_arguments` without recovery doesn't change streaming or single-pass behavior.
{{site.ai_gateway}} never buffers long-lived streams, such as `subscriptions/listen` and GET-initiated SSE.

{:.warning}
> Each sanitized call adds at least one round trip to the PII service.
> Load test the PII service with your largest and most deeply nested tool payloads before you enable the Policy in production.

## Block instead of redact

When `block_if_detected` is `true` and the PII service finds sensitive data, {{site.ai_gateway}} rejects the call instead of redacting it:

* For `tool_arguments`, the agent receives a JSON-RPC error and {{site.ai_gateway}} doesn't send the request to the tool server.
* For `tool_results`, {{site.ai_gateway}} replaces the result with a JSON-RPC error.

The error uses the format and HTTP status that match the client's [MCP protocol revision](/ai-gateway/mcp-version-support/).

## Recover redacted values

When [`recover_redacted`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-recover-redacted) is `true`, the tool server receives placeholders instead of the original values.
If the tool returns a placeholder in its result, {{site.ai_gateway}} restores the original value before it sends the result to the agent.
The `recover_redacted` setting is `true` by default.

## Error handling

The AI MCP Sanitizer Policy uses [`stop_on_error`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-stop-on-error) to decide what happens when the PII service is unreachable, returns a non-200 response, or returns a malformed response.
The `stop_on_error` setting is `true` by default.

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
    mcp: "[`sanitize_targets`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-sanitize-targets): `tool_arguments`, `tool_results`, or both"
  - setting: "`allow_all_conversation_history`"
    sanitizer: Supported
    mcp: Not available. Conversation history is an LLM concept.
{% endtable %}

{:.info}
> `INPUT`, `OUTPUT`, and `BOTH` are ambiguous on MCP traffic, because an AI MCP Server is both a server to the agent and a client of the tool server.
>
> `sanitize_targets` names the protocol location instead.

## AI PII Anonymizer service

{% include /md/ai-gateway/v2/policies/pii-service.md policy_name="AI MCP Sanitizer" %}

## Logging and analytics

The AI MCP Sanitizer Policy adds sanitization details to the MCP logs.

{% include md/ai-gateway/v2/mcp-sanitizer-logs.md %}
<!-- TODO: confirm the log field names against the spec. PR #23501 uses `sanitizer`, and the design doc uses `sanitization`. -->

## Configuration notes

* [`anonymize`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-anonymize) must contain at least one value.
  The default is `all_and_credentials`.
* If `anonymize` includes `custom`, you must set [`custom_patterns`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-custom-patterns).
  Each pattern needs a `name` and a `regex`.
  The optional `score` is a number between 0 and 1 and defaults to 0.5.
* [`sanitize_targets`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-sanitize-targets) must contain at least one target.
  The default is `tool_arguments`.
