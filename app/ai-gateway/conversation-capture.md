---
title: "Conversation capture in {{site.ai_gateway_name}}"
content_type: reference
layout: reference
published: false

products:
  - ai-gateway

works_on:
  - konnect

breadcrumbs:
  - /ai-gateway/

tags:
  - ai
  - observability
  - logging
  - cost-management

min_version:
  ai-gateway: '2.4'

description: "Conversation capture records the prompts and responses that pass through {{site.ai_gateway}} and exports them to {{site.konnect_short_name}}, independent of the OpenTelemetry policy and Debugger sessions. Covers use cases, capture controls, and PII scrubbing."

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

<!-- TODO (AG-2227 / AI-240): feature is in design and targets 2.4.0. Confirm publish timing before removing `published: false`. -->

Conversation capture records the prompts and responses that pass through {{site.ai_gateway}} and exports them to {{site.konnect_short_name}}, so you can read the conversation behind a metric.
You turn it on from {{site.konnect_short_name}}.
It runs independently of the [OpenTelemetry policy](/ai-gateway/policies/opentelemetry/) and of [Debugger](/observability/debugger/) sessions, so you don't need to change an existing observability setup to use it.

## Use cases

Conversation capture is most useful after another signal has pointed at a problem:

- **Cost management:** a [cost view](/ai-cost-management/analytics-and-debugging/) shows spend rising for a model or consumer. Captured conversations show what is driving it, such as unusually long prompts or repeated retries.
- **Tool-call failures on a cheaper model:** after you move traffic to a cheaper model, some tool calls start failing. Captured conversations show the exact request the model received and the tool call it produced.
- **Poorly defined tools:** a model picks the wrong tool or passes the wrong arguments. Captured conversations show how the model read the tool definitions, so you can see which descriptions are ambiguous.
- **Agent debugging:** an agent behaves unexpectedly. Captured conversations show each turn the agent took, so you can trace where it went wrong.
- **Prompt review:** you want to know what prompts your applications and agents send. Captured conversations show the prompts as the gateway received them.
- **Audit:** you need to show what was sent to an LLM provider. Captured conversations record each request and response.

<!-- TODO: the agent debugging, prompt review and audit use cases are the PM's suggestions from a meeting, not from the PRD. Confirm with the PM before publishing. -->

<!-- TODO: add a short end-to-end walkthrough (spot the problem in cost management, find the cause, enable capture, fix it) once the UI is available. The how-to will carry the steps; keep this page conceptual. -->

## How conversation capture differs from other tracing

{{site.ai_gateway}} already has two ways to get request detail out of the data plane.
Conversation capture is a third, separate mechanism.

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

Because conversation capture uses its own tracer, enabling it doesn't change the output of the OpenTelemetry policy, and an active Debugger session doesn't block it.
If both conversation capture and the OpenTelemetry policy are enabled, each produces its own spans for the same request.

Conversation capture propagates trace IDs the same way the OpenTelemetry policy does, using the incoming `traceparent` header.
You can correlate captured traces with traces from downstream applications.

## What is captured

Conversation capture exports two kinds of data from the data plane:

- **Access logs:** the same access log data that the OpenTelemetry policy exports. When payload capture is on, prompts and responses are included in the access log.
- **Traces:** spans that follow the Gen AI OpenTelemetry semantic conventions. See the [spans attributes reference](/ai-gateway/llm-open-telemetry/). Payloads aren't duplicated into trace attributes, because they are already in the access log.

<!--vale off-->
{% mermaid %}
flowchart LR
  Client --> DP[Data plane]
  DP --> LLM[LLM provider]
  DP -- "access logs and traces (mTLS)" --> Konnect[Konnect telemetry endpoint]
{% endmermaid %}
> _Figure 1: Captured access logs and traces leave the data plane for {{site.konnect_short_name}} over mTLS._
<!--vale on-->

The data plane authenticates the export with mutual TLS (mTLS), reusing the certificate it already uses to connect to {{site.konnect_short_name}}.
You don't configure certificates for capture.

## Capture controls

Conversation capture is off by default, so nothing is traced, exported, or captured until you turn it on.
Capture controls determine how much data leaves the data plane.

<!-- TODO: confirm names, defaults and limits against the Konnect API spec and UI. The ERD examples disagree on field names (`enabled` vs `enable`) and on the default max payload size (1,000,000 bytes in the settings table, 5 MB in the payload capture section). -->

You can turn trace export and access log export on independently.
For example, you can export access logs without traces, or the reverse.

### Payload capture

Payload capture controls whether prompts and responses are included in what's exported.
It's off by default, because payloads can be large and can contain sensitive data.

In {{site.ai_gateway}} 2.4, payload capture reuses the `log_payloads` setting on the [AI Model](/ai-gateway/entities/ai-model/).
Turning on `log_payloads` also makes payloads available to any attached logging policy, as it does today.
A separate capture-only toggle is planned for a later release.

<!-- TODO: open PRD question: does payload capture get its own toggle in 2.4, or reuse log_payloads? Update this section when decided. -->

A maximum payload size limits how much of each request or response is captured.

### Sampling payloads

To limit payload capture to the requests you care about, set a sampling rule.
A sampling rule is a [Common Expression Language (CEL)](/ai-gateway/conditions/) expression that must evaluate to a boolean.
Requests that match the rule have their payloads captured.
For other requests, the data plane removes the payload from the access log and the trace.

For example, a rule that matches a single consumer captures conversations only for that consumer.
Sampling rules let you capture the conversations behind a problem without storing every conversation.

<!-- TODO: confirm available CEL variables (model, provider, consumer) and the exact default behavior with the feature team. -->

## PII scrubbing

{{site.ai_gateway}} scrubs PII from captured data in the data plane before export, using a fixed set of rules:

- Values that pass the Luhn check, such as credit card numbers, are redacted.
- A predefined set of authentication headers is removed.

You can't configure these rules, and custom sanitization rules aren't supported.

<!-- TODO: PM (Greg, meeting notes) says PII is scrubbed with "local and dp regex". The ERD only describes static data plane rules (Luhn, auth headers) and no local (client-side?) scrubbing. Confirm with the feature team what "local" means and whether regex rules exist, then rewrite this section. Until then the section documents only the ERD rules. -->

<!-- TODO: open PRD question: are LLM API key headers used by common coding agents (for example Claude Code, OpenCode) in the predefined header list? Do not document until confirmed. -->

{:.warning}
> The fixed scrubbing rules can't detect all sensitive data in prompts and responses.
> For traffic that carries sensitive data, keep payload capture off or limit it with a sampling rule.

## Enable conversation capture

<!-- TODO: PM says captured conversations will appear in the Konnect UI under Observability > Sessions. That menu item was missing on the .tech environment at the time of the meeting, so confirm the name and location before documenting it. -->

<!-- TODO: add UI steps and API/kongctl examples once the Konnect UI and the settings API exist. Use docs/ui-steps-standards.md for UI steps. Do not publish endpoint paths or field names until they appear in api-specs/konnect/ai-gateway/v1/openapi.yaml. -->

## Limitations

- Custom sanitization rules aren't supported.
- Capture doesn't cover requests that are short-circuited before they reach the AI Model.
- Capture works with {{site.konnect_short_name}} data planes only.

<!-- TODO: confirm each limitation. "Short-circuited" comes from the AI Payload Export Control PRD non-goals. "Konnect only" comes from the kong-ee#23705 changelog. Add the memory and performance guidance once load testing (AG-2329) is done. -->
