---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Compress prompts with LLMLingua 2 before they reach the upstream LLM to stay within context limits, cut token costs, and reduce latency.'
categories:
  - ai
tags:
  - ai
  - performance

related_resources:
  - text: AI RAG Injector Policy
    url: /ai-gateway/policies/ai-rag-injector/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: Model cost management
    url: /ai-gateway/model-cost-management/
  - text: Forward proxy support
    url: /ai-gateway/forward-proxy/
---

The AI Prompt Compressor Policy compresses retrieved chunks before sending them to a Large Language Model (LLM), reducing text length while preserving meaning. It uses the [LLMLingua 2 library](https://github.com/microsoft/LLMLingua) for fast, high-quality compression. The AI Prompt Compressor Policy supports:

* **Ratio-based or target token compression**: for example, reduce a message to 80% of the original length or compress to 150 tokens.
* **Configurable compression ranges**: for example, compress prompts under 100 tokens with a 0.8 ratio or compress them to exactly 100 tokens.
* **Selective compression**: use `<LLMLINGUA>...</LLMLINGUA>` tags to target specific sections of the prompt. These tags work **only in the `inject_template` field of the [AI RAG Injector Policy](/ai-gateway/policies/ai-rag-injector/)** and must be used **in combination with the AI Prompt Compressor Policy**.
* **A choice of compression providers**: compress with Kong's built-in LLMLingua 2 service, or with an external [Headroom](#headroom-compression-provider) compression backend.

## Why use prompt compression

Efficient prompt compression helps you manage token limits, cut costs, and speed up LLM requests, all while keeping sensitive data safe and your prompts focused.

The following table outlines common use cases for the AI Prompt Compressor Policy and the configuration options available to tailor its behavior.

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: option
  - title: Description
    key: description
rows:
  - option: Token limit management
    description: |
      Compress verbose inputs like chat history or documents to stay within the LLM's context window. Prevents truncation of important content.
  - option: Cost reduction
    description: |
      Reducing token count in prompts decreases API costs when calling large language models, especially for high-volume use cases.
  - option: Latency reduction
    description: |
      Smaller prompts result in faster request/response cycles, improving performance for real-time applications like voice assistants.
  - option: Data privacy
    description: |
      Compress or abstract sensitive or personally identifiable information to maintain privacy and comply with data protection standards.
  - option: Dynamic prompt optimization
    description: |
      Automatically strip verbose or low-value content before sending to the LLM, keeping the focus on what's most relevant.
{% endtable %}
<!-- vale on -->

## AI Prompt Compression Service

Kong provides a Docker image for the AI Prompt Compressor service, which compresses LLM prompts before sending them upstream. It uses [LLMLingua 2](https://github.com/microsoft/LLMLingua) to reduce prompt size, which helps you manage token limits and maintain context fidelity. The service supports both HTTP and JSON-RPC APIs and is designed to work with the AI Prompt Compressor Policy in {{site.ai_gateway}}.

{% include prereqs/cloudsmith.md %}

### Image configuration options

You can configure the Kong AI Prompt Compressor Service using environment variables. These affect model selection, hardware usage, logging, and worker behavior.

<!-- vale off -->
{% table %}
columns:
  - title: Configuration option
    key: option
  - title: Description
    key: description
rows:
  - option: LLMLINGUA_MODEL_NAME
    description: |
      Specifies the LLMLingua 2 model to use for compression. Defaults to `microsoft/llmlingua-2-xlm-roberta-large-meetingbank`.
  - option: LLMLINGUA_DEVICE_MAP
    description: |
      Device on which to run the model. Supported values include `cpu`, `cuda`, `auto`, or `mps`.
  - option: LLMLINGUA_LOG_LEVEL
    description: |
      Log level for the LLMLingua compression logic. Set to `info`, `debug`, or `warning` based on your needs.
  - option: GUNICORN_WORKERS
    description: |
      Number of Gunicorn worker processes (for Docker deployments only). Defaults to `2`.
  - option: GUNICORN_LOG_LEVEL
    description: |
      Log level for Gunicorn server output (for Docker deployments only). Defaults to `info`.
{% endtable %}
<!-- vale on -->

### Compression endpoints

The AI Prompt Compressor Service exposes both REST and JSON-RPC endpoints. You can use these interfaces to compress prompts, check the current status, or integrate the service with the AI Prompt Compressor Policy and other upstream services.

* **POST `/llm/v1/compressPrompt`**: Compresses a prompt using either a compression ratio or a target token count. Supports selective compression via `<LLMLINGUA>` tags.

* **GET `/status`**: Returns information about the currently loaded LLMLingua model and device settings (for example, CPU or GPU).

* **POST `/`**: JSON-RPC endpoint that supports the `llm.v1.compressPrompt` method. Use this to invoke compression programmatically over JSON-RPC.

## Prompt compression options

The AI Prompt Compressor Policy offers flexible compression controls to fit different use cases. You can choose between full-prompt compression, conditional strategies, or selectively compressing only parts of the prompt:

<!-- vale off -->
{% table %}
columns:
  - title: Configuration Option
    key: option
  - title: Description
    key: description
rows:
  - option: Compression by ratio
    description: |
      Compress the prompt to a percentage of its original length (for example, reduce to 80%). This allows for consistent shrinkage regardless of the initial size.
  - option: Compression by token count
    description: |
      Compress the prompt to a specific token target (for example, 150 tokens). Useful when working close to LLM context window limits.
  - option: Conditional rules
    description: |
      Apply different compression strategies based on prompt length. For example, compress prompts under 100 tokens using a 0.8 ratio, and compress longer prompts to a fixed token count.
  - option: Selective compression with tags
    description: |
      Wrap sections of the prompt in `<LLMLINGUA>...</LLMLINGUA>` to target only specific parts for compression, preserving untagged content as-is.
{% endtable %}
<!-- vale on -->

## How it works

1. The user sends the final prompt to the AI Prompt Compressor Policy.
1. The AI Prompt Compressor Policy checks the prompt for `<LLMLINGUA>`...`</LLMLINGUA>` tags.
    - If tags are found, only the tagged sections are sent to LLMLingua 2 for compression.
    - If no tags are found, the entire prompt is sent to LLMLingua 2 for compression.
1. LLMLingua 2 applies the compression using the rule that matches the prompt's configuration you set with the policy: by ratio, target token count, or conditional length-based rules.
1. The compressed prompt is returned to the AI Prompt Compressor Policy.
1. The AI Prompt Compressor Policy sends the compressed prompt to the Large Language Model (LLM).
1. The LLM processes the prompt and returns the response to the user.

The following diagram illustrates how the AI Prompt Compressor Policy processes and compresses incoming prompts based on tagging and configured rules.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    actor User
    participant KongAICompressor as AI Prompt Compressor Policy
    participant LLMLingua2 as LLMLingua 2 Compressor
    participant LLM as Large Language Model

    User->>KongAICompressor: Sends final prompt
    activate KongAICompressor
    KongAICompressor->>KongAICompressor: Check for LLMLINGUA tags

    alt If tagged content found
        KongAICompressor->>LLMLingua2: Compress tagged sections
        activate LLMLingua2
        LLMLingua2-->>KongAICompressor: Return compressed sections
        deactivate LLMLingua2
    else If no LLMlingua tags
        KongAICompressor->>LLMLingua2: Compress entire prompt
        activate LLMLingua2
        LLMLingua2-->>KongAICompressor: Return compressed prompt
        deactivate LLMLingua2
    end

    KongAICompressor->>LLM: Send compressed prompt
    deactivate KongAICompressor
    activate LLM
    LLM-->>User: Return response
    deactivate LLM
{% endmermaid %}
<!-- vale on -->

The AI Prompt Compressor Policy applies structured compression to preserve essential context of prompts sent by users, rather than trimming prompts arbitrarily or risking token overflows. This ensures the LLM receives a well-formed, focused prompt keeping token usage under control.

## Headroom compression provider

As an alternative to the built-in LLMLingua 2 service, the AI Prompt Compressor Policy can compress requests through [Headroom](https://github.com/headroomlabs-ai/headroom), a local-first compression proxy. Kong calls Headroom's direct `POST /v1/compress` API rather than routing traffic through Headroom's transparent proxy mode, so {{site.konnect_short_name}} remains the sole point of egress to the upstream LLM. Headroom itself is an unmanaged, operator-deployed dependency: {{site.konnect_short_name}} doesn't deploy, health check, or configure the Headroom process.

### How Headroom compression works

The Headroom provider compresses the entire `messages` array of a request in one call, rather than compressing individual tagged sections. A request is only compressed when it has a `messages` array (an OpenAI-shaped or native Anthropic-shaped request) and a resolvable model name (from the request body or from the model negotiated by an AI Model or AI Model Chain). Any other request shape, such as a completions-style `prompt` or a Responses-style `input` list, is forwarded to the upstream LLM unchanged.

Each request also carries a session ID derived from the conversation, either from a configurable set of request headers or, if none are present, from the model name, system prompt, and first user message. Headroom uses this session ID to replay an already-compressed prefix byte-for-byte on later turns of the same conversation, which keeps the upstream LLM provider's own prompt cache hitting. This session-aware replay requires Headroom v0.37.0 or newer; older Headroom versions ignore the session ID and compress each request independently, without keeping session state.

### Deployment and trust model

Headroom trusts the loopback interface by default:

* **Loopback deployment (recommended)**: run Headroom as a sidecar bound to `127.0.0.1` alongside the Kong node. No token is required, and Headroom rejects non-loopback callers on `/v1/compress` regardless of any token.
* **Non-loopback deployment**: if your topology requires Headroom to bind elsewhere, configure a proxy token so the plugin can authenticate. Headroom must also be started with remote callers explicitly allowed, or it continues to reject requests with `404`.

Because Headroom keeps session state in memory on a single process, point every Kong node at its own Headroom sidecar, or at one shared Headroom instance, never at a load-balanced set of Headroom instances.

### Failure handling

By default, a failed Headroom call (an unreachable endpoint, a timeout, or a non-`200` response) causes the Policy to reject the request. Set `stop_on_error` to `false` to instead forward the request uncompressed and log the failure. A `503` response with `compression_timeout` is retried automatically before either outcome.

### Configuration

<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: option
  - title: Description
    key: description
rows:
  - option: endpoint
    description: |
      The Headroom `/v1/compress` endpoint to call. Defaults to `http://127.0.0.1:8787/v1/compress`.
  - option: proxy_token
    description: |
      Bearer token sent to Headroom. Required only when `endpoint` isn't a loopback address.
  - option: timeout
    description: |
      Request timeout, in milliseconds, for the call to Headroom. Defaults to `60000`.
  - option: ssl_verify
    description: |
      Whether to verify the TLS certificate when `endpoint` is an `https` URL. Defaults to `true`.
  - option: use_forward_proxy
    description: |
      Whether to route the call to Headroom through the Policy's configured forward proxy. `auto` (default) uses the proxy only when `endpoint` isn't loopback. See [Forward proxy support](/ai-gateway/forward-proxy/).
  - option: session_id_headers
    description: |
      Request headers used to derive the conversation's session ID. Use headers that stay stable across every turn of a conversation.
  - option: stop_on_error
    description: |
      Whether a failed Headroom call rejects the request (`true`, default) or forwards it uncompressed (`false`).
{% endtable %}
<!-- vale on -->

### Example configurations

Headroom co-located on loopback, no token required:

```yaml
plugins:
  - name: ai-prompt-compressor
    route: my-llm-route
    config:
      providers:
        - name: headroom
          headroom:
            endpoint: http://127.0.0.1:8787/v1/compress
```

Headroom reachable over a private network, with a token:

```yaml
plugins:
  - name: ai-prompt-compressor
    route: my-llm-route
    config:
      providers:
        - name: headroom
          headroom:
            endpoint: http://headroom.internal:8787/v1/compress
            proxy_token: "{vault://headroom-token}"
```

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}