---
title: "Conversation capture in {{site.konnect_short_name}}"
content_type: reference
layout: reference

products:
  - observability
  - ai-gateway

works_on:
  - konnect

breadcrumbs:
  - /observability/

tags:
  - ai
  - observability
  - logging
  - cost-management

min_version:
  ai-gateway: '2.5'

description: "Conversation capture records the prompts and responses that pass through {{site.ai_gateway}}, so you can find out why costs rise, tool calls fail, or agents misbehave."

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Model cost management
    url: /ai-gateway/model-cost-management/
  - text: Analytics and debugging in {{site.ai_cost_management}}
    url: /ai-cost-management/analytics-and-debugging/
  - text: "{{site.ai_gateway}} logs"
    url: /ai-gateway/ai-logs/
  - text: Gen AI OpenTelemetry spans attributes reference
    url: /ai-gateway/llm-open-telemetry/
  - text: "{{site.konnect_short_name}} Debugger"
    url: /observability/debugger/
---

<!-- TODO confirm before publishing:
- Release: confirm 2.5 versus 2.4. Jira AG-2227 is tagged aigw-2.4.0, but the gateway team said payload export won't make 2.4 (affects `min_version` and `published: false`).
- `sampling_rate` is intentionally not documented: the ERD says it stays hidden from users for now, but the kong-ee schema (PR 23705) defaults it to 1 (range 0 to 1). Confirm with the PM whether it is public, then document it.
- `max_payload_size_bytes` default (2,000,000 in PR 23705) differs from the ERD (1,000,000). Confirm the final default and upper bound against the Konnect spec.
- Trace export isn't in kong-ee PR 23705 (access logs only, "Milestone 1"). Re-add traces content when a PR ships it.
- Whether payload capture gets its own toggle or a per-exporter `export_ai_payloads` switch (PRD AG-2227) is still open.
- Agent debugging, prompt review, and audit use cases (not in the PRD).
- Settings endpoints are public (marked internal and unstable in the spec).
-->

Conversation capture records the prompts and responses that pass through {{site.ai_gateway}} and exports them to {{site.konnect_short_name}}, so you can read the conversation behind a metric.
You turn it on from {{site.konnect_short_name}}.
It runs independently of the [OpenTelemetry policy](/ai-gateway/policies/opentelemetry/) and of [Debugger](/observability/debugger/) sessions, so you don't need to change an existing observability setup to use it.

## Use cases

Conversation capture is most useful after another signal has pointed at a problem.

{% table %}
columns:
  - title: Use case
    key: scenario
  - title: What captured conversations show
    key: shows
rows:
  - scenario: "Cost management: a [cost view](/ai-cost-management/analytics-and-debugging/) shows spend rising for a model or consumer"
    shows: "What drives the cost, such as unusually long prompts, repeated retries, or a cheaper model that misfired a tool call."
  - scenario: "Tool calls fail after you move traffic to a cheaper model"
    shows: "The exact request the model received and the tool call it produced."
  - scenario: "A model picks the wrong tool or passes the wrong arguments"
    shows: "How the model read the tool definitions, so you can find ambiguous descriptions."
  - scenario: "An agent behaves unexpectedly"
    shows: "Each turn the agent took, so you can trace where it went wrong."
  - scenario: "Prompt review"
    shows: "The prompts your applications and agents send, as the gateway received them."
  - scenario: "Audit"
    shows: "Each request sent to an LLM provider and its response."
{% endtable %}

## How conversation capture differs from other tracing

{{site.ai_gateway}} already has two ways to get request detail out of the data plane.
Conversation capture is a third, separate mechanism with its own tracer.

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Where you configure it
    key: config
  - title: Characteristics
    key: characteristics
rows:
  - feature: "Conversation capture"
    config: "{{site.konnect_short_name}}"
    characteristics: |
      Runs continuously on live traffic.
      Exports to {{site.konnect_short_name}}.
      Doesn't depend on the OpenTelemetry policy or on Debugger sessions.
  - feature: "[OpenTelemetry policy](/ai-gateway/policies/opentelemetry/)"
    config: "AI Policy configuration"
    characteristics: |
      Exports to the collector you choose.
      Which spans are produced depends on the gateway's tracing instrumentation settings.
  - feature: "[Debugger](/observability/debugger/) session"
    config: "{{site.konnect_short_name}}"
    characteristics: |
      Time-bounded and high-verbosity.
      A data plane supports one active session at a time.
{% endtable %}

Use Debugger when you need detailed, high-verbosity data about gateway behavior for a short period, such as troubleshooting a policy.
Use conversation capture when you need the prompts and responses behind LLM traffic over time.
Use the OpenTelemetry policy when you need to send telemetry to your own collector.

Enabling conversation capture doesn't change the output of the OpenTelemetry policy, and an active Debugger session doesn't block it.
If you enable both capture and the OpenTelemetry policy, each exports its own access log for the same request.

## What is captured

Conversation capture exports access logs from the data plane: the same access log data that the OpenTelemetry policy exports, in OTLP format.
When payload capture is on, prompts and responses are included in the access log.
See the [spans attributes reference](/ai-gateway/llm-open-telemetry/) for the Gen AI attributes.

The data plane exports this data to the {{site.konnect_short_name}} telemetry endpoint (`cluster_telemetry_endpoint`) over mutual TLS (mTLS), reusing the certificate it already uses to connect to {{site.konnect_short_name}}.
Requests that the gateway handles internally aren't exported.

## Capture controls

Conversation capture settings apply to all traffic through {{site.ai_gateway}}.
All of them are off by default, so nothing is traced, exported, or captured until you turn it on.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: What it controls
    key: controls
rows:
  - setting: "`observability.access_logs.enabled`"
    controls: "Whether access logs are exported."
  - setting: "`observability.access_logs.compression_enabled`"
    controls: "Whether exported access logs are gzip-compressed. Defaults to `true`."
  - setting: "`observability.payload_capture.enabled`"
    controls: "Whether exported access logs keep the request and response bodies."
  - setting: "`observability.payload_capture.sampling_rule`"
    controls: "A CEL expression that limits payload capture to matching requests."
  - setting: "`observability.payload_capture.max_payload_size_bytes`"
    controls: |
      The maximum size of a captured body, in bytes. Defaults to 2,000,000.
      A larger body isn't exported.
{% endtable %}

Payloads are part of the access log, so payload capture has an effect only when access log export is on.

### Payload capture

Payload capture controls whether prompts and responses are included in what's exported.
It's off by default, because payloads can be large and can contain sensitive data.

Payloads only exist in the access log when the [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) that serves the request logs payloads.
Payload capture then decides whether they are exported.
{{site.ai_gateway}} exports a payload only when payload capture is enabled and the request matches the sampling rule, if you set one.
A body larger than `max_payload_size_bytes` is left out of the export, not truncated.

Unlike payload capture in Debugger sessions, conversation capture doesn't require a Data Processing Addendum or an organization-level entitlement.
Because payloads can contain sensitive data, review your own data handling requirements before you turn it on.

### Sampling payloads

To limit payload capture to the requests you care about, set a sampling rule.
A sampling rule is a [Common Expression Language (CEL)](/ai-gateway/conditions/) boolean expression of up to 1,024 characters.
The expression reads access log attributes by their full names, for example `kong.auth.consumer.username`.
An attribute that is missing from the request is null, and a rule that fails to evaluate counts as no match.
Only requests that match the rule have their payloads captured.
If you enable payload capture without a sampling rule, {{site.ai_gateway}} captures every request.
If the rule is invalid, {{site.ai_gateway}} captures no payloads.

For example, the rule `kong.auth.consumer.username == 'support-bot'` captures conversations only for the `support-bot` consumer.

## PII scrubbing

{{site.ai_gateway}} scrubs PII from captured data in the data plane before export, using a fixed set of rules:

- Values that pass the Luhn check, such as credit card numbers, are redacted.
- A predefined set of authentication headers is removed.

You can't configure these rules, and custom sanitization rules aren't supported.

<!-- TODO confirm: the PM brief mentions "local and data plane regex" scrubbing, but the ERD lists only the fixed Luhn and auth header rules and puts custom rules out of scope. Don't mention regex until the PM confirms. -->

<!-- TODO confirm: whether API key headers used by coding agents are in the scrubbed header list. -->

{:.warning}
> The fixed scrubbing rules can't detect all sensitive data in prompts and responses.
> For traffic that carries sensitive data, keep payload capture off or limit it with a sampling rule.

## Enable conversation capture

Turn on conversation capture by updating the {{site.ai_gateway}} settings.
The following request turns on access logs and payload capture for the `support-bot` consumer:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/settings
status_code: 200
method: PATCH
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  observability:
    access_logs:
      enabled: true
    payload_capture:
      enabled: true
      sampling_rule: "kong.auth.consumer.username == 'support-bot'"
{% endkonnect_api_request %}
<!--vale on-->

A `PATCH` request replaces each top-level property you send in full, and keeps the properties you omit.
In this request, `observability` is the top-level property, so any other `observability` settings you stored earlier are replaced by their defaults.
To unset a property, set it to `null`.

By default, a `GET` request to the same endpoint returns only the settings you have set.
To return every setting with its default value, add `view=effective`.

<!-- TODO confirm: UI location (Observability > Sessions?) and toggle design, then add UI steps. -->

## Limitations

- Custom sanitization rules aren't supported.
- Capture doesn't cover requests that are short-circuited before they reach the AI Model.
- Capture works with {{site.konnect_short_name}} data planes only.

<!-- TODO confirm: each limitation. Add memory and performance guidance after load testing. -->
