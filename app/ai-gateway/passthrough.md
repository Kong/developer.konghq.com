---
title: "Passthrough format in {{site.ai_gateway}}"
content_type: reference
layout: reference

works_on:
 - konnect

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai

tools:
  - konnect-api
  - kongctl

min_version:
  ai-gateway: '2.2'

description: Proxy AI traffic that {{site.ai_gateway}} can't parse, forwarding request and response bodies byte-for-byte while keeping authentication, rate limiting, and logging.

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: "Migrate to {{site.ai_gateway}} 2.x"
    url: /ai-gateway/v2-migration-guide/
  - text: "{{site.ai_gateway}} providers"
    url: /ai-gateway/ai-providers/

faqs:
  - q: Can a single AI Model mix passthrough and non-passthrough formats?
    a: |
      No. Every entry in an AI Model's `formats` array must be `passthrough`, or validation rejects the configuration.
      If you need both, declare two AI Models.

  - q: Why is my passthrough traffic showing no token counts or cost?
    a: |
      Usage extraction is best-effort. {{site.ai_gateway}} can only read token counts when the target's provider has a native adapter, or when the response happens to carry an OpenAI-shaped `usage` object.
      For any other response shape, usage extraction is skipped and token and cost fields are empty. Latency, status codes, and byte counts are always recorded.

  - q: Do `temperature` and `max_tokens` work on a passthrough target?
    a: |
      No. They remain in the schema but have no effect, because passthrough forwards the request body unchanged.
      {{site.ai_gateway}} logs a warning for each request when they're set. Set generation parameters in the client request instead.
---

## What is passthrough?

Passthrough is a request and response format that forwards traffic to an upstream AI service without parsing or transforming it. {{site.ai_gateway}} reads no request body, enforces no schema, and applies no `Content-Type` requirements. Request and response bodies reach their destination byte-for-byte.

Every other format assumes {{site.ai_gateway}} understands the payload. The default `openai` format translates between the OpenAI shape and the provider's own shape, and a [native format](/ai-gateway/entities/ai-model/#request-and-response-formats) such as `anthropic` or `bedrock` skips translation but still parses the payload to dispatch on a known capability. Passthrough drops both assumptions, which lets you put {{site.ai_gateway}} in front of an AI service whose schema it has never seen.

You keep the parts of {{site.ai_gateway}} that don't depend on payload shape: consumer authentication, credential injection, request-count rate limiting, and logging. You give up the parts that do, including format normalization and most guardrails. For the full breakdown, see [Policy compatibility](#policy-compatibility).

## When to use passthrough

Passthrough is for AI endpoints that fall outside the provider and capability matrix {{site.ai_gateway}} supports natively:

* **Self-hosted model servers** with proprietary request and response schemas, such as fine-tuned or experimental inference endpoints.
* **Vendor preview APIs** whose schema is still changing ahead of general availability.
* **Non-LLM AI endpoints**, such as custom computer vision or speech APIs, that don't map to any [capability](/ai-gateway/entities/ai-model/#capabilities).

If your provider and API are supported, use a typed capability with the `openai` format or a native format instead. Those give you normalization, guardrails, semantic features, and reliable usage accounting. Reach for passthrough when the alternative is bypassing {{site.ai_gateway}} altogether.

{:.info}
> If you're moving off the `preserve` route type in the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin, passthrough is its replacement. See [Migrate from the `preserve` route type](#migrate-from-the-preserve-route-type).

## Configure a passthrough AI Model

Set [`formats[].type`](/ai-gateway/entities/ai-model/#schema-aigateway-model-formats-type) to `passthrough` on the [AI Model](/ai-gateway/entities/ai-model/). The following example proxies a self-hosted inference server that exposes a schema {{site.ai_gateway}} doesn't recognize:

{% entity_examples %}
ai_gateway_models:
  - ref: custom-inference
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: custom-inference
    display_name: "custom-inference"
    type: model
    formats:
      - type: passthrough
    config:
      route:
        paths:
          - /custom-inference
    targets:
      - name: my-model
        provider: my-vllm-account
        config:
          type: vllm
          upstream_url: http://my-vllm-server.internal:8000/v1/infer
    policies: []
    capabilities:
      - generate
{% endentity_examples %}

In this example:

* `formats: [type: passthrough]` disables format translation and body parsing for the whole AI Model.
* `config.route.paths: [/custom-inference]` sets the base path clients send requests to. Because {{site.ai_gateway}} doesn't add a capability-specific suffix in passthrough mode, clients can call any path under this prefix.
* `targets[].config.upstream_url` sets the destination, including the path. For how the path is resolved, see [How upstream paths resolve](#how-upstream-paths-resolve).
* `provider: my-vllm-account` references an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) that holds the upstream connection and credentials, the same as any other AI Model.

Client authentication, [AI Consumer](/ai-gateway/entities/ai-consumer/) identity, and access control lists work unchanged, because none of them read the request body.

## How upstream paths resolve

The `upstream_url` on a target carries both the host and the path. How {{site.ai_gateway}} builds the upstream request depends on whether that URL includes a path:

{% table %}
columns:
  - title: "`upstream_url`"
    key: setting
  - title: Upstream request path
    key: behavior
rows:
  - setting: Set, with a path other than `/`
    behavior: "{{site.ai_gateway}} uses the configured path as-is and discards the client's request path."
  - setting: Set, with no path or only `/`
    behavior: "{{site.ai_gateway}} forwards the client's request path, stripping the AI Model's base path."
  - setting: Not set
    behavior: The provider's default host supplies the host, and {{site.ai_gateway}} forwards the client's request path. Providers with no default host reject the configuration.
{% endtable %}

Most providers have a built-in default host, so `upstream_url` is optional. Azure and Databricks have no default host and require it explicitly in passthrough mode.

## Observability in passthrough mode

The log phase still runs, so HTTP Log, File Log, OpenTelemetry, and Prometheus receive metadata for every passthrough request. What's available doesn't depend on payload shape:

* Request and response latency, in milliseconds
* HTTP status code
* Request and response byte counts
* AI Consumer identity, when an authentication Policy is attached
* AI Model and AI Model Provider identifiers

Token counts and cost are the exception, because {{site.ai_gateway}} has to read them out of the response body. See [Usage extraction and cost](#usage-extraction-and-cost).

### Usage extraction and cost

{{site.ai_gateway}} makes a best-effort attempt to extract usage metadata from passthrough responses, for both streaming and non-streaming traffic, in this order:

1. If the target's provider has a native adapter, {{site.ai_gateway}} uses that adapter's usage extraction logic.
1. If the adapter fails, or the provider has no adapter, {{site.ai_gateway}} falls back to reading an OpenAI-shaped `usage` object. Self-hosted servers that emulate the OpenAI API are usually covered by this fallback.
1. If neither succeeds, usage extraction is skipped.

When extraction is skipped, token and cost fields are empty in analytics and logs, and token-based rate limiting has nothing to count. The `input_cost` and `output_cost` settings on a target still apply, but only to requests whose token counts {{site.ai_gateway}} extracted successfully.

{:.warning}
> Don't rely on usage or cost data from passthrough traffic for billing or quota enforcement unless you've confirmed that extraction succeeds for your upstream's response shape. Configurable usage extraction paths aren't supported.

## What passthrough disables

Passthrough forwards the request unchanged, which rules out anything that rewrites or inspects it:

* **Format normalization**: no translation between the OpenAI shape and a provider shape, in either direction.
* **Model aliasing**: [`config.route.model`](/ai-gateway/entities/ai-model/#request-routing-rules) routing rules rewrite the request, so they're unavailable.
* **Semantic load balancing**: the `semantic` balancer algorithm compares prompt content against target descriptions, which requires a parsed body. Other [load balancing](/ai-gateway/load-balancing/) algorithms, including round-robin, priority, and lowest-latency, work normally.
* **The `realtime` capability**: passthrough doesn't support WebSockets.
* **Generation parameters**: the schema accepts `temperature`, `max_tokens`, `top_p`, and `top_k`, but they have no effect. {{site.ai_gateway}} logs a warning for each request when they're set. Set these in the client request instead.

A single AI Model can't mix passthrough with other formats. Every entry in `formats` must be `passthrough`, or validation rejects the configuration. Declare separate AI Models when you need both.

## Policy compatibility

Guardrail Policies and AI Rate Limiting Advanced run before the AI Model resolves its format, so a configuration flag on the Policy can't close these gaps. When a guardrail runs its own filters, {{site.ai_gateway}} hasn't yet determined that the request is a passthrough request.

Passthrough never parses the request or response body, so any policy that needs prompt or completion content has nothing to read. What still works depends on whether the target's provider has a native adapter in {{site.ai_gateway}}:

* **Native adapter**: Anthropic, Amazon Bedrock, Cohere, Gemini, and Hugging Face. {{site.ai_gateway}} uses the provider's own adapter to locate content and usage metadata in an otherwise unparsed payload.
* **No native adapter**: every other provider, including self-hosted servers such as vLLM, Ollama, and NVIDIA NIM. {{site.ai_gateway}} treats the payload as opaque bytes.

Core proxying works on both tiers. Authentication, credential signing, stream detection, and schema-agnostic forwarding run for every target regardless of adapter support. Only usage metadata extraction depends on the tier.

{:.warning}
> A policy that can't read the body doesn't fail the request. It silently does nothing, so protection you had on a typed route doesn't necessarily carry over to a passthrough route. Verify each policy against real traffic before you rely on it.

### Rate limiting and model selection

<!-- vale off -->
{% table %}
columns:
  - title: "Policy"
    key: name
  - title: Provider with a native adapter
    key: adapter
  - title: Provider without a native adapter
    key: driver
  - title: Notes
    key: notes
rows:
  - name: "[AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/)"
    adapter: Supported
    driver: Partial
    notes: Request-count limiting works on both tiers. Token-based limiting depends on successful usage extraction, which requires either a native adapter or an OpenAI-shaped `usage` object in the response.
  - name: AI Model Selector
    adapter: Partial
    driver: Not supported
    notes: Passthrough disables model aliasing because it rewrites the request. Remove this policy from passthrough targets. Explicitly configured path, body, and header sources still work on both tiers.
{% endtable %}
<!-- vale on -->

### Guardrails

Guardrails inspect prompt and response content, so they work only when a native adapter can locate that content.

<!-- vale off -->
{% table %}
columns:
  - title: "Policy"
    key: name
  - title: Provider with a native adapter
    key: adapter
  - title: Provider without a native adapter
    key: driver
rows:
  - name: "[AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/)"
    adapter: Supported
    driver: Not supported
  - name: "[AI Semantic Prompt Guard](/ai-gateway/policies/ai-semantic-prompt-guard/)"
    adapter: Supported
    driver: Not supported
  - name: "[AI Semantic Response Guard](/ai-gateway/policies/ai-semantic-response-guard/)"
    adapter: Supported
    driver: Not supported
  - name: "[AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/)"
    adapter: Supported
    driver: Not supported
  - name: "[AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/)"
    adapter: Supported
    driver: Not supported
  - name: "[AI GCP Model Armor](/ai-gateway/policies/ai-gcp-model-armor/)"
    adapter: Supported
    driver: Not supported
  - name: "[AI Lakera Guard](/ai-gateway/policies/ai-lakera-guard/)"
    adapter: Supported
    driver: Not supported
  - name: "[AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/)"
    adapter: Supported
    driver: Not supported
  - name: AI NVIDIA NeMo Guardrails
    adapter: Supported
    driver: Not supported
{% endtable %}
<!-- vale on -->

### Prompt manipulation

These policies write into a specific field in the request body, which requires knowing the payload schema.

<!-- vale off -->
{% table %}
columns:
  - title: "Policy"
    key: name
  - title: Provider with a native adapter
    key: adapter
  - title: Provider without a native adapter
    key: driver
rows:
  - name: "[AI Prompt Decorator](/ai-gateway/policies/ai-prompt-decorator/)"
    adapter: Supported
    driver: Not supported
  - name: "[AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/)"
    adapter: Not supported
    driver: Not supported
  - name: "[AI RAG Injector](/ai-gateway/policies/ai-rag-injector/)"
    adapter: Not supported
    driver: Not supported
  - name: "[AI Prompt Template](/ai-gateway/policies/ai-prompt-template/)"
    adapter: Not supported
    driver: Not supported
{% endtable %}
<!-- vale on -->

Only AI Prompt Decorator has an interface for writing into a native request body, which is why it works on the adapter tier and the others don't.

### Raw-byte transformation and sanitization

These policies operate on raw bytes rather than a parsed payload, so they work with passthrough on both tiers.

<!-- vale off -->
{% table %}
columns:
  - title: "Policy"
    key: name
  - title: Provider with a native adapter
    key: adapter
  - title: Provider without a native adapter
    key: driver
rows:
  - name: "[AI Request Transformer](/ai-gateway/policies/ai-request-transformer/)"
    adapter: Supported
    driver: Supported
  - name: "[AI Response Transformer](/ai-gateway/policies/ai-response-transformer/)"
    adapter: Supported
    driver: Supported
  - name: "[AI Sanitizer](/ai-gateway/policies/ai-sanitizer/) in PII mode"
    adapter: Supported
    driver: Supported
{% endtable %}
<!-- vale on -->

### Caching and evaluation

<!-- vale off -->
{% table %}
columns:
  - title: "Policy"
    key: name
  - title: Provider with a native adapter
    key: adapter
  - title: Provider without a native adapter
    key: driver
  - title: Notes
    key: notes
rows:
  - name: "[AI Semantic Cache](/ai-gateway/policies/ai-semantic-cache/)"
    adapter: Partial
    driver: Not supported
    notes: Cache-key vectorization works on the adapter tier, but storing a response for reuse requires a known response shape.
  - name: "[AI LLM as a Judge](/ai-gateway/policies/ai-llm-as-judge/)"
    adapter: Partial
    driver: Not supported
    notes: Request-side evaluation works on the adapter tier.
{% endtable %}
<!-- vale on -->

### Not affected by passthrough

MCP and agent-to-agent traffic runs on its own protocol stack and never reads a normalized chat body, so passthrough makes no difference to it:

* MCP JSON-RPC proxying, including its access control and session handling
* Agent-to-agent JSON-RPC and REST proxying
* OAuth 2.0 discovery and token validation for MCP

## Migrate from the `preserve` route type

`route_type: preserve` in the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin has no equivalent in {{site.ai_gateway}} 2.x. Passthrough replaces it. If you're converting a `preserve` configuration with [`kongctl convert ai-gateway`](/ai-gateway/v2-migration-guide/), the following sections cover what the converter can't infer.

### Field mapping

{% table %}
columns:
  - title: AI Proxy Advanced setting
    key: v1
  - title: AI Model setting
    key: v2
rows:
  - v1: "`config.targets[].route_type: preserve`"
    v2: "`formats[].type: passthrough`"
  - v1: "`model.options.upstream_url`"
    v2: "`targets[].config.upstream_url`"
  - v1: "`model.options.upstream_path`"
    v2: "No equivalent. Merge the path into `targets[].config.upstream_url`."
  - v1: "`model.options.temperature`, `max_tokens`, `top_p`, `top_k`"
    v2: "Accepted on `targets[].config` but inert under passthrough. Remove them."
{% endtable %}

Under `preserve`, `upstream_path` was honored only when `upstream_url` was unset, and applied as a literal path against the provider's default host. There's no separate path setting in 2.x, so `upstream_url` has to carry the full path. If you set both under `preserve`, `upstream_path` was already being ignored, so delete it.

### Client-path forwarding changed

Under `preserve`, path fallback used the raw incoming request path and ignored the Route's `strip_path` setting. An AI Model has no {{site.base_gateway}} Route, so the equivalent fallback strips the AI Model's `config.route.paths` prefix before forwarding, the way every other AI Model does.

If you relied on the full raw path reaching your upstream under `preserve`, set an explicit `upstream_url` with a fixed path so client-path forwarding doesn't apply at all. Otherwise, verify the path arriving upstream is still what your backend expects.

### Behavior that's now explicit

`preserve` left several interactions undefined, and support varied by plugin. Passthrough disables them consistently, as described in [What passthrough disables](#what-passthrough-disables): model aliasing, semantic load balancing, the `realtime` capability, and generation parameters.

Plugin behavior under `preserve` was also inconsistent. Some plugins passed traffic through silently, [AI RAG Injector](/ai-gateway/policies/ai-rag-injector/) returned a hard `400`, and [AI Semantic Cache](/ai-gateway/policies/ai-semantic-cache/) bypassed with a warning. Passthrough behavior is documented per Policy in [Policy compatibility](#policy-compatibility).

### Migration checklist

* Replace each `preserve` target with an AI Model whose `formats[].type` is `passthrough`.
* Merge any `upstream_path` value into `targets[].config.upstream_url`.
* Set `upstream_url` explicitly on Azure and Databricks targets, which have no default host.
* Verify the path arriving upstream, now that client-path forwarding strips the AI Model's base path.
* Split any plugin instance that mixed `preserve` with other route types into separate AI Models.
* Remove any dependency on model aliasing, semantic load balancing, the realtime capability, and generation parameters.
* Re-verify every guardrail Policy attached to a passthrough AI Model whose provider has no native adapter. A guardrail that can't read the body silently does nothing.

## Set up passthrough in {{site.konnect_short_name}}

To create a passthrough AI Model in the {{site.konnect_short_name}} UI:

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.ai_gateway}}**](/ai-gateway/).
1. In the {{site.ai_gateway}} sidebar, click [**Models**](/ai-gateway/entities/ai-model/).
1. Click **New model**.
1. In the **Name** field, enter `custom-inference`.
1. From the **LLM format** dropdown menu, select "Passthrough".
1. In the **Base path** field, enter `/custom-inference`.
1. From the **Provider** dropdown menu, select your AI Model Provider.
1. In the **Upstream URL** field, enter the full URL of your upstream endpoint, including the path.
1. Click **Save**.

The model configuration form changes when you select passthrough:

* The **Model Matching** section doesn't apply, because request and response bodies have an unknown shape.
* The **Capabilities** section has no route toggles, because requests are forwarded as the client sent them.
* The **Model Overview** test panel shows no example request, because any request shape is valid.
* {{site.konnect_short_name}} warns you when the selected provider has no native adapter, and when an attached Policy operates on parsed requests or responses. Policies that operate on raw bytes don't trigger a warning.
