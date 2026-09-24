---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Compress prompts before they reach the upstream LLM to stay within context limits, cut token costs, and reduce latency.'
categories:
  - ai
tags:
  - ai
  - performance
search_aliases:
  - headroom
  - LLMLingua
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

The AI Prompt Compressor Policy compresses messages before sending them to a Large Language Model (LLM), reducing text length while preserving meaning. It supports multiple cache-aware compression providers.

The AI Prompt Compressor Policy supports:

- **Ratio-based or target token compression**: For example, reduce a message to 80% of the original length or compress to 150 tokens.
- **Configurable compression ranges**: For example, compress prompts under 100 tokens with a 0.8 ratio or compress them to exactly 100 tokens.
- **Selective compression with LLMLingua**: Use `<LLMLINGUA>...</LLMLINGUA>` tags to target specific sections of the prompt. These tags work **only in the `inject_template` field of the [AI RAG Injector Policy](/ai-gateway/policies/ai-rag-injector/)** and must be used **in combination with the AI Prompt Compressor Policy**.

The following compression providers are available:

- `kong`: Use the [LLMLingua 2 library](https://github.com/microsoft/LLMLingua) to compress prose in user messages.
- `headroom`: Use [Headroom](https://github.com/headroomlabs-ai/headroom) to compress agent traffic such as tool results, large JSON payloads, search output, and logs returned by tools.

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
  - option: Cost reduction
    description: |
      Reducing token count in prompts decreases API costs when calling large language models, especially for high-volume use cases.
  - option: Token limit management
    description: |
      Compress verbose inputs like chat history or documents to stay within the LLM's context window. Prevents truncation of important content.
  - option: Latency reduction
    description: |
      Smaller prompts result in faster request/response cycles, improving performance for real-time applications like voice assistants.
  - option: Dynamic prompt optimization
    description: |
      Automatically strip verbose or low-value content before sending to the LLM, keeping the focus on what's most relevant.
{% endtable %}
<!-- vale on -->

### Deterministic compression  

Prompt caching lets a provider reuse a token prefix it has already seen and bills that warm read at much lower cost. For agentic and RAG workloads, where a large system prompt, tool definitions, and history repeat every turn, caching is the single biggest lever to reduce costs. Compression is the second best lever, it shrinks the tokens the provider still has to read. Deterministic compression is required since it ensures the same input results in the same output at a byte-for-byte level which then hits the cache. This allows both methods of cost reduction to coexist.

## LLMLingua compressor service

Kong provides a Docker image for a compressor service, which compresses LLM prompts before sending them upstream. It uses [LLMLingua 2](https://github.com/microsoft/LLMLingua) to reduce prompt size, which helps you manage token limits and maintain context fidelity. The compressor service supports both HTTP and JSON-RPC APIs and is designed to work with the AI Prompt Compressor Policy in {{site.ai_gateway}}.

{% include prereqs/cloudsmith.md %}

### Image configuration options

You can configure the compressor service image using environment variables. These affect model selection, hardware usage, logging, and worker behavior.

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

### Compressor Service endpoints

The compressor service exposes both REST and JSON-RPC endpoints. You can use these interfaces to compress prompts, check the current status, or integrate the service with the AI Prompt Compressor Policy and other upstream services.

* **POST `/llm/v1/compressPrompt`**: Compresses a prompt using either a compression ratio or a target token count. Supports selective compression via `<LLMLINGUA>` tags.

* **GET `/status`**: Returns information about the currently loaded LLMLingua model and device settings (for example, CPU or GPU).

* **POST `/`**: JSON-RPC endpoint that supports the `llm.v1.compressPrompt` method. Use this to invoke compression programmatically over JSON-RPC.

### LLMLINGUA prompt flow

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

### Prompt compression options

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

## Headroom compressor service {% new_in 2.2 %}

{:.warning}
> This feature is currently in [Tech Preview](/stages-of-software-availability/#tech-preview) and should not be used in a production environment.

Before you use Headroom with the AI Prompt Compressor Policy, you need a Headroom instance accessible to your {{site.ai_gateway}}.

You can do this with one of the following:

* [Local Headroom installation](https://docs.headroomlabs.ai/docs/installation)
* [Headroom Enterprise](https://www.headroomlabs.ai/)

### Configure Headroom connection

To configure an AI Prompt Compressor Policy with Headroom as the compressor service, do the following:

{% entity_example %}
type: policy
data:
  display_name: AI Prompt Compressor with Headroom
  name: my-ai-prompt-compressor
  type: ai-prompt-compressor
  config:
    compression_ranges:
    - min_tokens: 20
      max_tokens: 100
      value: 0.8
    provider: headroom
    compressor_url: http://headroom-service:8787/v1/compress
    timeout: 45000
    keepalive_timeout: 60000
    log_text_data: false
    stop_on_error: true
    headroom:
      proxy_token: ${headroom_proxy_token}
      ssl_verify: true
      session_id_headers:
        - x-claude-code-session-id
        - x-claude-code-agent-id
        - thread-id
        - session-id
        - x-session-id
variables:
  headroom_proxy_token:
    value: $HEADROOM_PROXY_TOKEN
    description: Your Headroom provider authentication token.
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

For more details, see the [configuration reference](/ai-gateway/policies/ai-prompt-compressor/reference/#configuration).

### Compressor Service endpoint

The compressor service exposes a [`/v1/compress`](https://docs.headroomlabs.ai/docs/proxy#post-v1compress) endpoint that compresses messages and returns them. This endpoint accepts OpenAI and Anthropic's message formats. Requests in unsupported formats are forwarded unchanged. You can use this interface to compress prompts, check the current status, or integrate the service with the AI Prompt Compressor Policy.

Headroom uses loopback-trust by default. It answers unauthenticated calls on `127.0.0.1`, and returns `404` to non-loopback callers unless it's started with `HEADROOM_COMPRESS_ALLOW_REMOTE=1`. You can run Headroom as a co-located sidecar reachable from the {{site.ai_gateway}} data plane without authentication, or point the Policy at a remote instance and configure a bearer token, sent as both the `X-Headroom-Proxy-Token` and `Authorization: Bearer` headers.

### Headroom prompt flow

The AI Prompt Compressor Policy uses Headroom in a stateful mode and derives a session identifier for each conversation, based on the configured `config.headroom.session_id_headers`, an [AI Consumer](/ai-gateway/entities/ai-consumer/), or a `credential`. Headroom can recognize the turns it has already compressed for that conversation. Recognized turns are replayed unchanged instead of compressed again. This ensures the upstream LLM provider's cache hits on repeated turns. 

If a session identifier isn't present, then every client that opens with the same prompt shares one session state on the Headroom side. If sessions collide, then only one will hit the upstream cache.

1. {{site.ai_gateway}} sends the user or agent's request to the AI Prompt Compressor.
2. The AI Prompt Compressor builds a messages array from the whole conversation.
3. The AI Prompt Compressor sends a `POST` request to Headroom's `/v1/compress` endpoint with the messages array and a session identifier for the conversation.
4. If Headroom recognizes the session identifier, it replays the turns it already compressed unchanged and compresses only the new messages. Otherwise, it compresses the whole conversation.
5. Headroom returns `200` with the compressed messages and metadata.

If the call to Headroom fails, the AI Prompt Compressor rejects the request by default. For details, see [Failure behavior](#failure-handling).

The following diagram illustrates how the AI Prompt Compressor Policy processes and compresses incoming prompts using Headroom:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    actor User as User/Agent
    participant KongAICompressor as AI Prompt Compressor Policy
    participant Headroom
    participant LLM as LLM Provider

    User->>KongAICompressor: Sends request
    activate KongAICompressor
    KongAICompressor->>Headroom: POST /v1/compress with messages and session ID

    alt Session recognized
        Headroom->>Headroom: Replay cached turns, compress only new messages
    else New session
        Headroom->>Headroom: Compress whole conversation
    end

    alt Compression succeeds
        Headroom-->>KongAICompressor: Return 200 with compressed messages and metadata
        KongAICompressor->>LLM: Send compressed messages to upstream provider
        LLM-->>KongAICompressor: Return response
        KongAICompressor-->>User: Return response
    else Compression fails
        Headroom-->>KongAICompressor: Return failure response
        KongAICompressor--xUser: Return HTTP 500, request not forwarded
    end
    deactivate KongAICompressor
{% endmermaid %}
<!-- vale on -->

### Failure handling

By default, if the call to Headroom fails, times out, or returns an error, the Policy returns an HTTP `500` to the client rather than forwarding the request uncompressed.

A `503` response indicating a compression timeout is retried automatically before the Policy gives up; every other non-`200` response (for example a `400` from a bad configuration, or a `401` from a missing or incorrect bearer token) fails immediately.

### Limitations

- Deterministic compression requires sessions which is only available in **Headroom v0.37.0 or newer**. Older images silently ignore the session id and run stateless.
- Headroom sessions are held in memory on a single Headroom process. You must point every data plane node at its own sidecar, or all of them at one shared instance. Never point an {{site.ai_gateway}} data plane at a load-balanced set of Headroom instances, since a session's turns must all reach the same process.
- No MCP tool-response compression: only the LLM request path is supported.
- Switching models mid conversation will change the session identifier and break caching.
- Only requests with a `messages` or `input` conversation array are sent to Headroom. Other formats are forwarded uncompressed.

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}