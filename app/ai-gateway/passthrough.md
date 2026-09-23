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

description: Proxy AI traffic that {{site.ai_gateway}} can't parse, forwarding request and response bodies byte-for-byte while keeping upstream authentication, rate limiting, and logging.

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
      {{site.ai_gateway}} reads token counts out of the response body using a native adapter for the target's declared `provider` (`anthropic`, `bedrock`, `cohere`, `gemini`, or `huggingface`), falling back to generic OpenAI-shape parsing when there's no adapter or the adapter finds nothing. If your upstream's response matches neither, for example a custom or self-hosted server with its own field names, token and cost fields stay empty.
      Latency, status codes, and byte counts are recorded for every passthrough request either way.

  - q: Do `temperature` and `max_tokens` work on a passthrough target?
    a: |
      No. The schema still accepts them, but they have no effect, because passthrough forwards the request body unchanged.
      {{site.ai_gateway}} logs a warning for each request when they're set. Set generation parameters in the client request instead.

  - q: What happens if I deploy a passthrough AI Model to an older data plane?
    a: |
      The data plane rejects the configuration at validation time, because it doesn't recognize `passthrough` as a format value.
      It never falls back to another format, which would send unparsed traffic down a transformation path that expects a known schema.
---

## What is passthrough?

Passthrough is a request and response format that forwards traffic to an upstream AI service without parsing or transforming it. {{site.ai_gateway}} reads no request body, enforces no `Content-Type`, and validates against no schema. Request and response bodies reach their destination byte-for-byte.

Every other format assumes {{site.ai_gateway}} understands the payload. The default `openai` format translates between the OpenAI shape and the provider's own shape, and a [native format](/ai-gateway/entities/ai-model/#request-and-response-formats) such as `anthropic` or `bedrock` skips that translation but still parses the payload to dispatch on a known capability. Passthrough drops both assumptions, so you can put {{site.ai_gateway}} in front of an AI service whose wire format it has never seen.

You keep everything that doesn't depend on payload shape:

* Upstream provider authentication, including AWS Signature Version 4, OAuth 2.0, and API keys
* AI Consumer authentication, identity, and access control lists
* Request-count rate limiting
* Logging and metrics

You give up format normalization and anything that rewrites the request. Content-aware features such as guardrails and token accounting depend on whether {{site.ai_gateway}} can make sense of your upstream's actual request and response shape. See [Recognized upstreams](#recognized-upstreams) and [Policy compatibility](#policy-compatibility) for the full breakdown.

Passthrough is additive and off until you configure it. Existing formats and AI Models are unaffected.

## When to use passthrough

Passthrough is for AI endpoints that fall outside the provider and capability matrix {{site.ai_gateway}} supports natively:

* **Self-hosted model servers** with proprietary request and response schemas, such as vLLM, Ollama, NVIDIA NIM, and fine-tuned inference endpoints.
* **Vendor preview APIs** whose schema is still changing ahead of general availability.
* **Non-LLM AI endpoints**, such as custom computer vision or speech APIs, that don't map to any [capability](/ai-gateway/entities/ai-model/#capabilities).

If your provider and API are supported, use a typed capability with the `openai` format or a native format instead. Those give you normalization, guardrails, semantic features, and token accounting with no extra configuration. Reach for passthrough when the alternative is bypassing {{site.ai_gateway}} altogether.

{:.info}
> If you're moving off the `preserve` route type in the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin, passthrough is its replacement. See [Migrate from the `preserve` route type](#migrate-from-the-preserve-route-type).

## Configure a passthrough AI Model

Set [`formats[].type`](/ai-gateway/entities/ai-model/#schema-aigateway-model-formats-type) to `passthrough` on the [AI Model](/ai-gateway/entities/ai-model/). The following example proxies a self-hosted vLLM server that exposes a schema {{site.ai_gateway}} doesn't recognize:

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
* `config.route.paths: [/custom-inference]` sets the base path clients send requests to. Passthrough adds no capability-specific suffix, so clients can call any path under this prefix.
* `targets[].config.upstream_url` sets the destination, including the path. See [How upstream paths resolve](#how-upstream-paths-resolve).
* `provider: my-vllm-account` references an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) that holds the upstream connection and credentials, the same as any other AI Model.

Credentials still come from the AI Model Provider, and {{site.ai_gateway}} signs each upstream request as it normally would. Passthrough skips format transformation, not authentication, so AWS Signature Version 4, OAuth 2.0, and API key auth all work. Set [`targets[].allow_auth_override`](/ai-gateway/entities/ai-model/#schema-aigateway-target-allow-auth-override) to `true` if you want request-level credentials to take precedence instead.

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
    behavior: "The provider's default host supplies the host, and {{site.ai_gateway}} forwards the client's request path."
{% endtable %}

{:.warning}
> Passthrough relaxes the schema requirements for fields it doesn't use, so a target that's missing a required `upstream_url` still passes configuration validation. Azure and Databricks have no default host, so a passthrough target using either one fails at request time with a `500` instead. Always set `upstream_url` explicitly on Azure and Databricks targets.

## Recognized upstreams

Token and cost extraction depends on whether {{site.ai_gateway}} can parse the response body, and that depends on the target's declared `provider`, not its `upstream_url`. {{site.ai_gateway}} has a native response adapter for five providers: `anthropic`, `bedrock`, `cohere`, `gemini` (including Vertex AI), and `huggingface`. When a target's `provider` is one of these, {{site.ai_gateway}} tries that adapter's extraction logic first, against both buffered and streaming responses.

If no adapter matches the target's `provider`, or the adapter finds no usage data, {{site.ai_gateway}} falls back to generic parsing: it looks for a top-level, OpenAI-shaped `usage` object in the JSON response. This can still populate token counts for an OpenAI-compatible self-hosted server, such as vLLM or Ollama returning an OpenAI-shaped `usage` block, but there's no guarantee, since passthrough forwards whatever shape the upstream actually returns.

For everything else, for example Amazon SageMaker, Llama 2, and other custom or self-hosted servers whose response matches neither an adapter nor the OpenAI shape, {{site.ai_gateway}} has no way to locate token counts in the payload. Traffic proxies normally, and latency, status codes, byte counts, and AI Consumer identity are all still recorded, but usage data stays empty.

Guardrail Policies don't depend on this same mechanism. See [Policy compatibility](#policy-compatibility).

## Observability in passthrough mode

The log phase still runs, so HTTP Log, File Log, OpenTelemetry, and Prometheus receive metadata for every passthrough request. The following is available regardless of payload shape:

* Request and response latency, in milliseconds
* HTTP status code
* Request and response byte counts
* AI Consumer identity, when an authentication Policy is attached
* AI Model and AI Model Provider identifiers

### Token usage and cost

Token counts and cost depend on whether {{site.ai_gateway}} can extract usage from the response body, as described in [Recognized upstreams](#recognized-upstreams). Extraction works for both buffered and streaming responses, and inflates gzip-encoded streams before reading them.

Some providers split usage across multiple events instead of sending one self-contained payload:

* Anthropic sends prompt, cache, and completion tokens across separate `message_start` and `message_delta` events, which {{site.ai_gateway}} merges into a single usage record.
* Amazon Bedrock's `InvokeModelWithResponseStream` API carries the authoritative counts in a base64-encoded `amazon-bedrock-invocationMetrics` field on the final chunk; its `ConverseStream` API sends usage in a dedicated `metadata` event.
* Cohere also splits usage across streaming events.
* Gemini and Hugging Face send a self-contained usage shape on every event, so no merging is needed.

Once token counts are available, cost calculation and token-based rate limiting both work from them. The `input_cost` and `output_cost` settings on a target apply only to requests whose token counts {{site.ai_gateway}} could read.

Where extraction fails, token and cost fields stay empty in analytics and logs, and [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) has nothing to meter. Request-count limiting is unaffected.

{:.warning}
> Before you rely on passthrough usage data for billing or quota enforcement, confirm that your target's `provider` has a native adapter, or that its response includes an OpenAI-shaped `usage` object, and that token counts appear for real traffic, streaming and buffered.

### Streaming detection

{{site.ai_gateway}} has to identify a streaming response so it doesn't buffer the whole generation before returning it. It checks, in order:

1. A `"stream": true` field in the request body.
1. An `Accept: text/event-stream` request header.
1. A known streaming path or query pattern in the request, which covers upstreams that signal streaming in the URL rather than the body. This includes Gemini's `:streamGenerateContent` with `alt=sse`, Amazon Bedrock's `/converse-stream` and `/invoke-with-response-stream`, and Amazon SageMaker's `/invocations-response-stream`.

If none of these match, {{site.ai_gateway}} treats the response as buffered. Response bytes still reach the client unchanged, but the client waits for the full generation instead of receiving it incrementally. If your upstream streams using a signal that isn't in this list, send `"stream": true` in the request body or set the `Accept` header on the client.

## What passthrough disables

Passthrough forwards the request unchanged, which rules out anything that rewrites or restructures it:

* **Format normalization**: no translation between the OpenAI shape and a provider shape, in either direction.
* **Model aliasing**: [`config.route.model`](/ai-gateway/entities/ai-model/#request-routing-rules) routing rules rewrite the request, so they're unavailable.
* **Semantic load balancing**: the `semantic` algorithm matches prompt content against each target's `semantic_description`, which needs a parsed body. Other [load balancing](/ai-gateway/load-balancing/) algorithms, including round-robin, priority, and lowest-latency, work normally.
* **The `realtime` capability**: passthrough doesn't support WebSockets.
* **Generation parameters**: the schema accepts `temperature`, `max_tokens`, `top_p`, and `top_k`, but they have no effect. {{site.ai_gateway}} logs a warning for each request when they're set. Set these in the client request instead.

A single AI Model can't mix passthrough with other formats. Every entry in `formats` must be `passthrough`, or validation rejects the configuration. Declare separate AI Models when you need both.

## Policy compatibility

{:.warning}
> A Policy that can't read the body doesn't fail the request. It's skipped, so valid traffic keeps flowing but the protection you had on a typed AI Model doesn't carry over. Verify every guardrail against real passthrough traffic before you rely on it.

### Works with any upstream

<!-- vale off -->
{% table %}
columns:
  - title: Policy
    key: name
  - title: Notes
    key: notes
rows:
  - name: "[AI Request Transformer](/ai-gateway/policies/ai-request-transformer/)"
    notes: Operates on raw bytes, so payload shape is irrelevant.
  - name: "[AI Response Transformer](/ai-gateway/policies/ai-response-transformer/)"
    notes: Operates on raw bytes, so payload shape is irrelevant.
  - name: "[AI Sanitizer](/ai-gateway/policies/ai-sanitizer/) in PII mode"
    notes: Operates on raw bytes, so payload shape is irrelevant.
  - name: "[AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/)"
    notes: Request-count limiting always works. Token-based limiting needs a recognized upstream.
{% endtable %}
<!-- vale on -->

### Depends on your upstream's request and response shape

These Policies read prompt or completion content out of the request or response body. Under passthrough, that's a separate mechanism from the token and cost extraction in [Recognized upstreams](#recognized-upstreams): {{site.ai_gateway}} makes a best-effort attempt to read the prompt from common request shapes, such as an OpenAI-style `messages` or `input` array, and falls back to provider-specific extraction for requests those don't match. Whether a given Policy actually works depends on how closely your upstream's real request and response shapes match what the Policy or that fallback extraction expects, not on a fixed provider list. A Policy that can't locate the content it needs is skipped rather than failing the request.

<!-- vale off -->
{% table %}
columns:
  - title: Policy
    key: name
rows:
  - name: "[AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/)"
  - name: "[AI Semantic Prompt Guard](/ai-gateway/policies/ai-semantic-prompt-guard/)"
  - name: "[AI Semantic Response Guard](/ai-gateway/policies/ai-semantic-response-guard/)"
  - name: "[AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/)"
  - name: "[AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/)"
  - name: "[AI GCP Model Armor](/ai-gateway/policies/ai-gcp-model-armor/)"
  - name: "[AI Lakera Guard](/ai-gateway/policies/ai-lakera-guard/)"
  - name: "[AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/)"
  - name: AI NVIDIA NeMo Guardrails
{% endtable %}
<!-- vale on -->

### Not supported

<!-- vale off -->
{% table %}
columns:
  - title: Policy
    key: name
  - title: Reason
    key: notes
rows:
  - name: "[AI Prompt Decorator](/ai-gateway/policies/ai-prompt-decorator/)"
    notes: Has to write into a specific request body field, which needs a known schema.
  - name: "[AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/)"
    notes: Has to write into a specific request body field, which needs a known schema.
  - name: "[AI RAG Injector](/ai-gateway/policies/ai-rag-injector/)"
    notes: Has to write into a specific request body field, which needs a known schema.
  - name: "[AI Prompt Template](/ai-gateway/policies/ai-prompt-template/)"
    notes: Has to write into a specific request body field, which needs a known schema.
  - name: "[AI Semantic Cache](/ai-gateway/policies/ai-semantic-cache/)"
    notes: Storing and replaying a response needs a known response shape.
{% endtable %}
<!-- vale on -->

### Not affected by passthrough

MCP and agent-to-agent traffic runs on its own protocol stack and never reads a normalized chat body, so passthrough makes no difference to it:

* MCP JSON-RPC proxying, including its access control and session handling
* Agent-to-agent JSON-RPC and REST proxying
* OAuth 2.0 discovery and token validation for MCP

## Migrate from the `preserve` route type

`route_type: preserve` in the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin has no equivalent in {{site.ai_gateway}} 2.x, and it isn't coming back. Passthrough replaces it. If you're converting a `preserve` configuration with [`kongctl convert ai-gateway`](/ai-gateway/v2-migration-guide/), the following sections cover what the converter can't infer.

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
  - v1: "`config.targets[].auth.allow_override`"
    v2: "`targets[].allow_auth_override`"
  - v1: "`model.options.temperature`, `max_tokens`, `top_p`, `top_k`"
    v2: "Accepted on `targets[].config` but inert under passthrough. Remove them."
{% endtable %}

Under `preserve`, `upstream_path` was honored only when `upstream_url` was unset, and applied as a literal path against the provider's default host. There's no separate path setting in 2.x, so `upstream_url` has to carry the full path. If you set both under `preserve`, `upstream_path` was already being ignored, so delete it.

### Client-path forwarding changed

Under `preserve`, path fallback used the raw incoming request path and ignored the Route's `strip_path` setting. An AI Model has no {{site.base_gateway}} Route, so the equivalent fallback strips the AI Model's `config.route.paths` prefix before forwarding, the way every other AI Model does.

If you relied on the full raw path reaching your upstream under `preserve`, set an explicit `upstream_url` with a fixed path so client-path forwarding doesn't apply at all. Otherwise, verify the path arriving upstream is still what your backend expects.

### Re-verify guardrails

Plugin behavior under `preserve` was inconsistent. Some plugins passed traffic through silently, AI RAG Injector returned a hard `400`, and AI Semantic Cache bypassed with a warning. Under passthrough, behavior is defined per Policy in [Policy compatibility](#policy-compatibility): a guardrail is skipped when it can't locate the content it needs in your upstream's actual request or response shape, and usage data is empty when your target's `provider` has no matching adapter and the response isn't OpenAI-shaped either. See [Recognized upstreams](#recognized-upstreams).

If your `preserve` targets pointed at a self-hosted or model-agnostic upstream, both are plausible: check each guardrail and usage data against real traffic rather than assuming either works. If you need guaranteed guardrail or usage support, use a typed capability with a native format instead of passthrough.

### Migration checklist

* Replace each `preserve` target with an AI Model whose `formats[].type` is `passthrough`.
* Merge any `upstream_path` value into `targets[].config.upstream_url`.
* Set `upstream_url` explicitly on Azure and Databricks targets, which have no default host and fail at request time without it.
* Verify the path arriving upstream, now that client-path forwarding strips the AI Model's base path.
* Split any plugin instance that mixed `preserve` with other route types into separate AI Models.
* Remove any dependency on model aliasing, semantic load balancing, the realtime capability, and generation parameters.
* Check whether each target's `provider` has a native adapter, or its response is OpenAI-shaped, and confirm you can accept empty usage data where neither applies.
* Re-verify every guardrail Policy attached to a passthrough AI Model against real traffic. A guardrail that can't locate the content it needs in your upstream's shape is skipped, not enforced.

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
* {{site.konnect_short_name}} warns you when the selected upstream isn't recognized, and when an attached Policy operates on parsed requests or responses. Policies that operate on raw bytes don't trigger a warning.
