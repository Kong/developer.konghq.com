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
- `sampling_rate` is intentionally not documented: the ERD says it stays hidden from users for now (default 0.01). Add it if the spec exposes it publicly.
- `max_payload_size` (ERD default 1,000,000 bytes, configurable) isn't documented until the spec confirms the field and its upper bound.
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
If you enable both capture and the OpenTelemetry policy, each produces its own spans for the same request.

## What is captured

Conversation capture exports two kinds of data from the data plane:

- **Access logs:** the same access log data that the OpenTelemetry policy exports. When payload capture is on, prompts and responses are included in the access log.
- **Traces:** spans that follow the Gen AI OpenTelemetry semantic conventions. See the [spans attributes reference](/ai-gateway/llm-open-telemetry/). Payloads aren't duplicated into trace attributes, because they are already in the access log.

The data plane exports this data over mutual TLS (mTLS), reusing the certificate it already uses to connect to {{site.konnect_short_name}}.

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
  - setting: "`observability.traces`"
    controls: "Whether traces are recorded."
  - setting: "`observability.access_logs`"
    controls: "Whether access logs are recorded."
  - setting: "`observability.payload_capture`"
    controls: |
      Whether request payloads are captured.
      Use `sampling_rule` to limit capture to matching requests.
{% endtable %}

Trace export and access log export are independent.
For example, you can export access logs without traces, or the reverse.

### Payload capture

Payload capture controls whether prompts and responses are included in what's exported.
It's off by default, because payloads can be large and can contain sensitive data.

Payload capture adds to the payload logging you configure on an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).
{{site.ai_gateway}} captures a payload when the entity that serves the request logs payloads, or when payload capture is enabled and the request matches the sampling rule.

Unlike payload capture in Debugger sessions, conversation capture doesn't require a Data Processing Addendum or an organization-level entitlement.
Because payloads can contain sensitive data, review your own data handling requirements before you turn it on.

### Sampling payloads

To limit payload capture to the requests you care about, set a sampling rule.
A sampling rule is a [Common Expression Language (CEL)](/ai-gateway/conditions/) boolean expression of up to 1,024 characters.
It uses the same variables as the `allow_when` and `deny_when` access rules.
Only requests that match the rule have their payloads captured.
If you enable payload capture without a sampling rule, {{site.ai_gateway}} captures every request.

For example, the rule `consumer.username == 'support-bot'` captures conversations only for the `support-bot` consumer.

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
      sampling_rule: "consumer.username == 'support-bot'"
{% endkonnect_api_request %}
<!--vale on-->

A `PATCH` request replaces each top-level property you send in full, and keeps the properties you omit.
In this request, `observability` is the top-level property, so any `traces` settings you stored earlier are replaced by their defaults.
To unset a property, set it to `null`.

By default, a `GET` request to the same endpoint returns only the settings you have set.
To return every setting with its default value, add `view=effective`.

<!-- TODO confirm: UI location (Observability > Sessions?) and toggle design, then add UI steps. -->

## Limitations

- Custom sanitization rules aren't supported.
- Capture doesn't cover requests that are short-circuited before they reach the AI Model.
- Capture works with {{site.konnect_short_name}} data planes only.

<!-- TODO confirm: each limitation. Add memory and performance guidance after load testing. -->
