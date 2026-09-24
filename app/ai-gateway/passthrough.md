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

description: Proxy AI traffic that {{site.ai_gateway}} can't parse, forwarding unchanged request and response bodies while keeping upstream authentication, rate limiting, and logging.

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
  - q: Which Policies work with passthrough?
    a: |
      Policies that operate on raw bytes (AI Request Transformer, AI Response Transformer, AI Sanitizer in PII mode) and request-count rate limiting always work.
      Guardrails that read prompt or completion content (AI Prompt Guard, AI Semantic Prompt/Response Guard, AI AWS/Azure/GCP/Lakera/Custom Guardrails) and Policies that write into a specific body field (AI Prompt Decorator, AI Prompt Compressor, AI RAG Injector, AI Prompt Template, AI Semantic Cache) aren't supported: passthrough doesn't parse the body into a shape these Policies can read or write. MCP and agent-to-agent traffic isn't affected either way.

---

## What is passthrough?

In an [AI Model](/ai-gateway/entities/ai-model/), the `passthrough` format forwards traffic to an upstream AI service without transforming it. {{site.ai_gateway}} doesn't transform the request or response body, doesn't enforce any `Content-Type`, and doesn't validate the payload against any schema. Request and response bodies reach their destination byte-for-byte. This allows you to put {{site.ai_gateway}} in front of any AI service and keep all the capabilities that don't depend on the payload shape:

* Upstream provider authentication, including AWS Signature Version 4, OAuth 2.0, and API keys
* AI Consumer authentication, identity, and access control lists
* Request-count rate limiting
* Logging and metrics

AI Models using the passthrough format don't support format normalization or anything that rewrites the request. Token accounting depends on whether {{site.ai_gateway}} can make sense of your upstream's actual response shape; see [Token usage and cost](#token-usage-and-cost). Guardrails aren't supported under passthrough, since there's no parsed body for them to read.

### Use cases

Passthrough is useful for AI endpoints that fall outside the [providers](/ai-gateway/ai-providers/) that {{site.ai_gateway}} supports natively. For example:

* Self-hosted model servers with proprietary request and response schemas.
* Vendor preview APIs whose schema is still changing ahead of general availability.
* Non-LLM AI endpoints, such as custom computer vision or speech APIs, that don't map to any [capability](/ai-gateway/entities/ai-model/#capabilities).

{:.info}
> If you're moving off the `preserve` route type in the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin, passthrough is its replacement. See [Migrate from the `preserve` route type](#migrate-from-the-preserve-route-type).

## Configure a passthrough AI Model

Set [`formats[].type`](/ai-gateway/entities/ai-model/#schema-aigateway-model-formats-type) to `passthrough` on the [AI Model](/ai-gateway/entities/ai-model/). The following example proxies a self-hosted Triton Inference Server instance that exposes a schema {{site.ai_gateway}} doesn't recognize:

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
        provider: my-triton-account
        config:
          type: openai
          upstream_url: http://my-triton-server.internal:8000/v2/models/my-model/infer
    policies: []
    capabilities:
      - generate
{% endentity_examples %}

In this example:

* `formats: [type: passthrough]` disables format translation and body parsing for the whole AI Model.
* `config.route.paths: [/custom-inference]` sets the base path clients send requests to. Passthrough adds no capability-specific suffix, so clients can call any path under this prefix.
* `targets[].config.upstream_url` sets the destination, including the path. See [Upstream paths](#upstream-paths).
* `targets[].config.type` selects `openai` here for its API-key authentication behavior, not because the upstream is OpenAI. Passthrough never checks this value against the actual payload shape, so pick whichever supported type's auth mechanism matches your upstream, such as `openai` for a plain API key or `bedrock` for AWS Signature Version 4.
* `provider: my-triton-account` references an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) that holds the upstream connection and credentials, the same as any other AI Model.

Credentials still come from the AI Model Provider, and {{site.ai_gateway}} signs each upstream request as it normally would. Passthrough skips format transformation, not authentication, so AWS Signature Version 4, OAuth 2.0, and API key auth all work. Set [`targets[].allow_auth_override`](/ai-gateway/entities/ai-model/#schema-aigateway-target-allow-auth-override) to `true` if you want request-level credentials to take precedence instead.

## Upstream paths

The `upstream_url` on a target carries both the host and the path. The way {{site.ai_gateway}} builds the upstream request depends on whether that URL includes a path. The following examples assume an AI Model with `config.route.paths: [/custom-inference]`, a target whose provider defaults to `https://api.openai.com`, and a client request sent to `/custom-inference/v1/chat/completions`:

{% table %}
columns:
  - title: "`upstream_url`"
    key: setting
  - title: Upstream request path
    key: behavior
  - title: Example
    key: example
rows:
  - setting: Set, with a path other than `/`
    behavior: "{{site.ai_gateway}} uses the configured path as-is and discards the client's request path."
    example: "`upstream_url: http://my-server.internal:8000/v2/models/my-model/infer` sends every request to `http://my-server.internal:8000/v2/models/my-model/infer`, no matter what path the client used."
  - setting: Set, with no path or only `/`
    behavior: "{{site.ai_gateway}} forwards the client's request path, stripping the AI Model's base path."
    example: "`upstream_url: http://my-server.internal:8000/` sends the request to `http://my-server.internal:8000/v1/chat/completions`, the client's path with `/custom-inference` stripped."
  - setting: Not set
    behavior: "The provider's default host supplies the host, and {{site.ai_gateway}} forwards the client's request path."
    example: "No `upstream_url` sends the request to `https://api.openai.com/v1/chat/completions`, the provider's default host plus the client's path with `/custom-inference` stripped."
{% endtable %}

## Observability in passthrough mode

The log phase still runs, so HTTP Log, File Log, OpenTelemetry, and Prometheus receive metadata for every passthrough request. The following is available regardless of payload shape:

* Request and response latency, in milliseconds
* HTTP status code
* Request and response byte counts
* AI Consumer identity, when an authentication Policy is attached
* AI Model and AI Model Provider identifiers

### Token usage and cost

Whether {{site.ai_gateway}} can report token counts and cost for a passthrough request depends on your target's `provider`:

* `anthropic`, `bedrock`, `cohere`, `gemini`, or `huggingface` token counts and cost are extracted reliably, for both streaming and buffered responses.
* With an OpenAI-compatible custom or self-hosted server, such as vLLM or Ollama, returning an OpenAI-shaped `usage` object, token counts can populate. However, this isn't guaranteed, since passthrough forwards whatever shape your upstream actually returns.
* With anything else, for example Amazon SageMaker, Llama 2, and other custom or self-hosted servers with their own response shape, {{site.ai_gateway}} has no way to locate token counts, and usage stays empty.

Cost calculation and token-based rate limiting only work when token counts are available. The `input_cost` and `output_cost` settings on a target apply only to requests whose token counts {{site.ai_gateway}} could read, and [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) has nothing to meter when extraction fails.

{:.warning}
> Before you rely on passthrough usage data for billing or quota enforcement, confirm that your target's `provider` has a native adapter, or that its response includes an OpenAI-shaped `usage` object, and that token counts appear for real traffic, streaming and buffered.

### Streaming detection

{{site.ai_gateway}} detects a streaming response from the request itself through: 
* A `"stream": true` field in the body
* An `Accept: text/event-stream` header
* A known streaming path for providers that signal streaming through the URL instead of the body

If none of these match, {{site.ai_gateway}} buffers the response instead of streaming it. The client still gets the full, unmodified response, but all at once instead of incrementally. If your upstream signals streaming some other way, send `"stream": true` in the request body or set the `Accept` header yourself.

## Migrate from the `preserve` route type

[`kongctl convert ai-gateway`](/ai-gateway/v2-migration-guide/) doesn't have any special handling for `route_type: preserve`. To migrate, recreate the AI Model manually using [Configure a passthrough AI Model](#configure-a-passthrough-ai-model) as a starting point, and use the following sections as a manual field-by-field reference for what `preserve` used to do.

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
{% endtable %}

### Client path forwarding

Under `preserve`, path fallback used the raw incoming request path and ignored the Route's `strip_path` setting. If you relied on the full raw path reaching your upstream under `preserve`, set an explicit `upstream_url` with a fixed path on the new AI Model so client-path forwarding doesn't apply at all. Otherwise, verify the path arriving upstream is still what your backend expects once you've recreated the target.

### Migration steps

* Don't rely on `kongctl convert ai-gateway` for `preserve` targets: it warns and skips them, producing no output for them at all. Recreate each one as a new AI Model manually.
* Set `formats[].type` to `passthrough` on the new AI Model.
* Merge any `upstream_path` value into `targets[].config.upstream_url`.
* Set `upstream_url` explicitly on Azure and Databricks targets, which have no default host. Azure fails at request time without it; Databricks fails configuration validation instead.
* Verify the path arriving upstream, now that client-path forwarding strips the AI Model's base path.
* Split any plugin instance that mixed `preserve` with other route types into separate AI Models.
* Remove any dependency on model aliasing, semantic load balancing, the realtime capability, and generation parameters.