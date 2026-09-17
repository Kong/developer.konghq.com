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
      {{site.ai_gateway}} maps token fields automatically only for upstreams it recognizes by URL. Self-hosted and model-agnostic upstreams can serve any model, so they have no fixed response shape.
      Set [`targets[].token_ref`](#extract-content-and-usage) to tell {{site.ai_gateway}} where the token counts are. Latency, status codes, and byte counts are recorded either way.

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

You give up format normalization and anything that rewrites the request. Content-aware features such as guardrails and token accounting are opt-in: {{site.ai_gateway}} handles them automatically for upstreams it recognizes, and you can enable them for anything else with the [`content_ref` and `token_ref`](#extract-content-and-usage) fields. For the full breakdown, see [Policy compatibility](#policy-compatibility).

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

{{site.ai_gateway}} inspects each target's `upstream_url`, matching on hostname and path suffix, to work out which upstream it's talking to. When it recognizes one, it applies that provider's built-in field mappings, so guardrails and token accounting work with no extra configuration. Amazon Bedrock, Gemini, Vertex AI, and Anthropic are recognized this way.

Some upstreams can't be recognized by URL alone, because they can host any model behind an operator-chosen path and therefore have no fixed request or response shape:

* Amazon SageMaker
* vLLM
* Ollama
* Llama 2 and other self-hosted servers
* Custom and preview APIs

For these, supply the field locations yourself with `content_ref` and `token_ref`.

<!-- TODO: confirm the full list of upstreams in the provider-path detection registry before publishing, and whether Vertex AI ships token paths separately from Gemini. -->

## Extract content and usage

Two optional fields on each target let you tell {{site.ai_gateway}} where to find the parts of an otherwise opaque payload that it needs:

{% table %}
columns:
  - title: Field
    key: field
  - title: What it does
    key: purpose
rows:
  - field: "`targets[].content_ref`"
    purpose: A JSONPath expression that locates the prompt content in the request body. {{site.ai_gateway}} extracts it into shared context so guardrail Policies can inspect it.
  - field: "`targets[].token_ref`"
    purpose: Maps custom response fields to the standard usage fields, so token counts and cost are recorded for the request.
{% endtable %}

Both fields override the built-in mappings, so leave them unset for [recognized upstreams](#recognized-upstreams) and set them for anything else. Both sit at the top level of a target, alongside `name`, `provider`, and `allow_auth_override`:

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
        content_ref: "$.messages[*].content"
        token_ref:
          prompt_tokens: "$.usage.input_count"
          completion_tokens: "$.usage.output_count"
        config:
          type: vllm
          upstream_url: http://my-vllm-server.internal:8000/v1/infer
    policies: []
    capabilities:
      - generate
{% endentity_examples %}

{{site.ai_gateway}} validates only the shape of these fields, not whether the expressions match your payload. A JSONPath that resolves to nothing is a runtime miss rather than a configuration error: the request still succeeds, and the content or token counts are simply absent. Test both against real traffic after you configure them.

## Observability in passthrough mode

The log phase still runs, so HTTP Log, File Log, OpenTelemetry, and Prometheus receive metadata for every passthrough request. The following is available regardless of payload shape:

* Request and response latency, in milliseconds
* HTTP status code
* Request and response byte counts
* AI Consumer identity, when an authentication Policy is attached
* AI Model and AI Model Provider identifiers

### Token usage and cost

Token counts and cost have to be read out of the response body, so they depend on {{site.ai_gateway}} knowing where to look. For a [recognized upstream](#recognized-upstreams), the built-in field mappings handle it. For anything else, set [`token_ref`](#extract-content-and-usage).

Extraction works for both buffered and streaming responses. On a streaming response, {{site.ai_gateway}} reads usage from each event as it passes through, including the nested shape Anthropic uses in its `message_start` event, and inflates gzip-encoded streams before reading them. Once token counts are available, cost calculation and token-based rate limiting both work from them.

The `input_cost` and `output_cost` settings on a target apply only to requests whose token counts {{site.ai_gateway}} could read. If extraction finds nothing, token and cost fields stay empty in analytics and logs, and [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) has nothing to meter. Request-count limiting is unaffected.

{:.warning}
> Before you rely on passthrough usage data for billing or quota enforcement, confirm that extraction actually succeeds against your upstream's real responses, streaming and buffered.

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

### Works with no extra configuration

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
    notes: Request-count limiting always works. Token-based limiting needs token extraction, either from a recognized upstream or from `token_ref`.
{% endtable %}
<!-- vale on -->

### Needs a recognized upstream or `content_ref`

These Policies read prompt or completion content. They work automatically for a [recognized upstream](#recognized-upstreams), and for any other upstream once you set [`content_ref`](#extract-content-and-usage). Without either, they're skipped.

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
  - v1: "`config.targets[].auth.allow_override`"
    v2: "`targets[].allow_auth_override`"
  - v1: "`model.options.temperature`, `max_tokens`, `top_p`, `top_k`"
    v2: "Accepted on `targets[].config` but inert under passthrough. Remove them."
{% endtable %}

Under `preserve`, `upstream_path` was honored only when `upstream_url` was unset, and applied as a literal path against the provider's default host. There's no separate path setting in 2.x, so `upstream_url` has to carry the full path. If you set both under `preserve`, `upstream_path` was already being ignored, so delete it.

### Client-path forwarding changed

Under `preserve`, path fallback used the raw incoming request path and ignored the Route's `strip_path` setting. An AI Model has no {{site.base_gateway}} Route, so the equivalent fallback strips the AI Model's `config.route.paths` prefix before forwarding, the way every other AI Model does.

If you relied on the full raw path reaching your upstream under `preserve`, set an explicit `upstream_url` with a fixed path so client-path forwarding doesn't apply at all. Otherwise, verify the path arriving upstream is still what your backend expects.

### Guardrails need reconnecting

Plugin behavior under `preserve` was inconsistent. Some plugins passed traffic through silently, AI RAG Injector returned a hard `400`, and AI Semantic Cache bypassed with a warning. Under passthrough, behavior is defined per Policy in [Policy compatibility](#policy-compatibility), and content-reading guardrails can be reconnected with [`content_ref`](#extract-content-and-usage) rather than lost.

Token accounting works the same way. If your `preserve` targets produced no usage data, set [`token_ref`](#extract-content-and-usage) to get token counts and cost back.

### Migration checklist

* Replace each `preserve` target with an AI Model whose `formats[].type` is `passthrough`.
* Merge any `upstream_path` value into `targets[].config.upstream_url`.
* Set `upstream_url` explicitly on Azure and Databricks targets, which have no default host and fail at request time without it.
* Verify the path arriving upstream, now that client-path forwarding strips the AI Model's base path.
* Split any plugin instance that mixed `preserve` with other route types into separate AI Models.
* Remove any dependency on model aliasing, semantic load balancing, the realtime capability, and generation parameters.
* Set `content_ref` on targets whose guardrails need prompt content, and `token_ref` on targets that need token counts and cost.
* Re-verify every guardrail Policy attached to a passthrough AI Model. A guardrail that can't read the body is skipped, not enforced.

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
1. In the **Content ref** field, enter a JSONPath expression for the prompt content, if your upstream isn't recognized and you need guardrails.
1. In the **Token ref** field, enter the JSONPath mappings for token counts, if your upstream isn't recognized and you need usage data.
1. Click **Save**.

The model configuration form changes when you select passthrough:

* The **Model Matching** section doesn't apply, because request and response bodies have an unknown shape.
* The **Capabilities** section has no route toggles, because requests are forwarded as the client sent them.
* The **Model Overview** test panel shows no example request, because any request shape is valid.
* {{site.konnect_short_name}} warns you when the selected upstream isn't recognized, and when an attached Policy operates on parsed requests or responses. Policies that operate on raw bytes don't trigger a warning.
