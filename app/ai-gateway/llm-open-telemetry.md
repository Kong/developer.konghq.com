---
title: "Gen AI OpenTelemetry attributes reference"
content_type: reference
layout: reference

products:
  - ai-gateway
  - gateway

breadcrumbs:
  - /ai-gateway/

tags:
  - ai
  - monitoring
  - tracing

plugins:
  - opentelemetry
  - ai-proxy
  - ai-proxy-advanced

min_version:
  gateway: '3.13'

tech_preview: true

description: "Reference for OpenTelemetry Gen AI span attributes emitted by {{site.ai_gateway}} for generative AI requests."

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: Zipkin plugin
    url: /plugins/zipkin/
  - text: "{{site.base_gateway}} tracing guide"
    url: /gateway/tracing/
  - text: Set up Jaeger with Gen AI OpenTelemetry
    url: /how-to/set-up-jaeger-with-gen-ai-otel/
  - text: Validate Gen AI tool calls with Jaeger and OpenTelemetry
    url: /how-to/set-up-jaeger-with-gen-ai-otel-for-tool-calls/

works_on:
  - on-prem
  - konnect
---

{% new_in 3.13 %} {{site.ai_gateway}} supports [OpenTelemetry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/#genai-attributes) instrumentation for generative AI traffic. When the OpenTelemetry (OTEL) plugin is enabled in {{site.ai_gateway}}, a set of **Gen AI-specific attributes** are emitted on tracing spans. These attributes complement the core tracing instrumentations described in the [{{site.base_gateway}} tracing guide](/gateway/tracing), giving insight into the Gen AI request lifecycle (inputs, model, and outputs), usage, and tool/agent interactions.

You can export these attributes via a supported backend such as [Jaeger](/how-to/set-up-jaeger-with-otel/) configured through Kong's [OpenTelemetry plugin](/plugins/opentelemetry) or the [Zipkin plugin](/plugins/zipkin) to:

* Inspect which model or provider handled a request
* Track conversation/session identifiers across requests
* Analyze prompt structure (system vs. user vs. tool messages)
* Evaluate model parameters (such as temperature, top-k)
* Measure tool-call behavior (which tools were invoked, and their metadata)
* Monitor token usage (input vs. output) for cost or performance analysis

The span data is sent to the configured OTEL endpoint through the existing tracing plugins. Use the OpenTelemetry plugin or Zipkin plugin to export these spans to backends such as Jaeger.

{% include plugins/otel/collecting-otel-data.md  %}

### Provider & Operation

These attributes identify the Gen AI provider and the type of operation requested (such as chat completion or embeddings generation).

<!-- vale off -->
{% table %}
columns:
  - title: Key
    key: key
  - title: Value Type
    key: type
  - title: Description
    key: desc
rows:
  - key: |
        `gen_ai.operation.name`
    type: "string"
    desc: "Operation requested from the provider, such as chat or embeddings."
  - key: |
        `gen_ai.provider.name`
    type: "string"
    desc: "Name of the Generative AI provider handling the request."
{% endtable %}
<!-- vale on -->

### Request details

These attributes capture model configuration parameters sent with the request. They control generation behavior such as randomness, token limits, and sampling strategies.

<!-- vale off -->
{% table %}
columns:
  - title: Key
    key: key
  - title: Value Type
    key: type
  - title: Description
    key: desc
rows:
  - key: |
        `gen_ai.request.choice.count`
    type: "int"
    desc: "Number of result candidates requested in a response."
  - key: |
        `gen_ai.request.encoding_formats`
    type: "string[]"
    desc: "Requested encoding formats for embeddings results."
  - key: |
        `gen_ai.request.frequency_penalty`
    type: "double"
    desc: "Penalty that reduces repetition of frequent tokens."
  - key: |
        `gen_ai.request.max_tokens`
    type: "int"
    desc: "Maximum number of tokens the model may generate."
  - key: |
        `gen_ai.request.model`
    type: "string"
    desc: "Model name targeted by the request."
  - key: |
        `gen_ai.request.presence_penalty`
    type: "double"
    desc: "Penalty that reduces repetition of new tokens."
  - key: |
        `gen_ai.request.seed`
    type: "int"
    desc: "Seed value that increases response reproducibility."
  - key: |
        `gen_ai.request.stop_sequences`
    type: "string[]"
    desc: "Token sequences that stop further generation."
  - key: |
        `gen_ai.request.temperature`
    type: "double"
    desc: "Randomness factor for generated results."
  - key: |
        `gen_ai.request.top_k`
    type: "double"
    desc: "Top-k sampling configuration limiting candidate tokens."
  - key: |
        `gen_ai.request.top_p`
    type: "double"
    desc: "Probability threshold applied during nucleus sampling."
{% endtable %}
<!-- vale on -->

### Payloads and types

These attributes contain the actual input and output messages exchanged with the model, along with output format specifications and system-level instructions. Payload attributes are only emitted when payload logging is enabled.

{:.warning}
> The `gen_ai.input.messages` and `gen_ai.output.messages` attributes log full request and response payloads. These may contain personally identifiable information (PII), credentials, or other sensitive data.
>
> Make sure your tracing backend has appropriate access controls and retention policies before enabling payload logging.

Attributes with the `any` type contain JSON-serialized objects. The structure follows the message format of the underlying provider API (for example, OpenAI's chat completion message schema).

<!-- vale off -->
{% table %}
columns:
  - title: Key
    key: key
  - title: Value Type
    key: type
  - title: Description
    key: desc
rows:
  - key: |
        `gen_ai.input.messages`
    type: "any"
    desc: "Structured messages sent as input when payload logging is enabled."
  - key: |
        `gen_ai.output.messages`
    type: "any"
    desc: "Structured messages returned by the model when payload logging is enabled."
  - key: |
        `gen_ai.output.type`
    type: "string"
    desc: "Requested output format, such as text or JSON."
  - key: |
        `gen_ai.system_instructions`
    type: "string"
    desc: "System-level instructions provided to steer model behavior."
{% endtable %}
<!-- vale on -->

### Response and usage

These attributes capture metadata from the model's response, including token consumption metrics used for cost analysis and performance monitoring.

<!-- vale off -->
{% table %}
columns:
  - title: Key
    key: key
  - title: Value Type
    key: type
  - title: Description
    key: desc
rows:
  - key: |
        `gen_ai.response.finish_reasons`
    type: "string[]"
    desc: "Reasons returned for why token generation stopped."
  - key: |
        `gen_ai.response.id`
    type: "string"
    desc: "Unique identifier assigned to the completion by the provider."
  - key: |
        `gen_ai.response.model`
    type: "string"
    desc: "Model name reported by the provider in the response."
  - key: |
        `gen_ai.usage.input_tokens`
    type: "int"
    desc: "Number of tokens processed as input to the model."
  - key: |
        `gen_ai.usage.output_tokens`
    type: "int"
    desc: "Number of tokens generated by the model in the response."
{% endtable %}
<!-- vale on -->

### Specific Features (Tools, Agents, Data Sources)

These attributes provide context for advanced Gen AI features such as tool calling, agent-based architectures, and data source grounding.

<!-- vale off -->
{% table %}
columns:
  - title: Key
    key: key
  - title: Value Type
    key: type
  - title: Description
    key: desc
rows:
  - key: |
        `gen_ai.agent.description`
    type: "string"
    desc: "Description of the agent's purpose or role."
  - key: |
        `gen_ai.agent.id`
    type: "string"
    desc: "Identifier representing the application-defined agent."
  - key: |
        `gen_ai.token.type`
    type: "string"
    desc: "Token counting strategy used for the request."
  - key: |
        `gen_ai.tool.call.id`
    type: "string"
    desc: "Unique identifier assigned to a tool call from the model."
  - key: |
        `gen_ai.tool.description`
    type: "string"
    desc: "Description of the tool being invoked."
  - key: |
        `gen_ai.tool.name`
    type: "string"
    desc: "Name of the tool invoked by the model."
  - key: |
        `gen_ai.tool.type`
    type: "string"
    desc: "Type of tool invoked, such as function."
{% endtable %}
<!-- vale on -->
