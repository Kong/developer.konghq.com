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

The AI Prompt Compressor Policy compresses retrieved chunks before sending them to a Large Language Model (LLM), reducing text length while preserving meaning. It supports multiple cache-aware compression backends that provide fast, high-quality, deterministic compression.

The AI Prompt Compressor Policy supports:

* **Ratio-based or target token compression**: for example, reduce a message to 80% of the original length or compress to 150 tokens.
* **Configurable compression ranges**: for example, compress prompts under 100 tokens with a 0.8 ratio or compress them to exactly 100 tokens.
* **Selective compression**: use `<LLMLINGUA>...</LLMLINGUA>` tags to target specific sections of the prompt. These tags work **only in the `inject_template` field of the [AI RAG Injector Policy](/ai-gateway/policies/ai-rag-injector/)** and must be used **in combination with the AI Prompt Compressor Policy**.

The following backends are available:

* [LLMLingua 2 library](https://github.com/microsoft/LLMLingua): use this to compress prose in user messages.
* [Headroom](https://github.com/headroomlabs-ai/headroom): use this to compress agent traffic such as tool results, large JSON payloads, search output, and logs returned by tools.

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

### Deterministic compression  

Prompt caching lets a provider reuse a token prefix it has already seen and bills that warm read at at much lower cost. For agentic and RAG workloads, where a large system prompt, tool definitions, and history repeat every turn, caching is the single biggest lever to reduce costs. Compression is the second best lever, it shrinks the tokens the provider still has to read. Deterministic compression is required since it ensures the same input results in the same output at a byte-for-byte level which then hits the cache. This allows both methods of cost reduction to coexist.

## LLMLingua based compression service

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

## Headroom Compression Service

Before using Headroom with AI Prompt Compressor Policy you must have a Headroom instance accessible to your {{site.ai_gateway}}.

You can do this with one of the following:

* [Local Headroom installation](https://docs.headroomlabs.ai/docs/installation)
* [Headroom Enterprise](https://www.headroomlabs.ai/)

### Configure Headroom connection

To configure an AI Prompt Compressor Policy with headroom as the compressor service:

{% entity_examples %}
type: policy
data:
  display_name: AI Prompt Compressor with Headroom
  name: my-ai-prompt-compressor
  type: ai-prompt-compressor
  config:
    lossy_backend: external
    headroom_endpoint: http://headroom-service:8787
    headroom_auth_token: !env HEADROOM_API_KEY
    headroom_target_ratio: 0.5
    headroom_protect_recent: 4
    headroom_timeout_ms: 5000
    keepalive_timeout: 60000
    log_text_data: false
    stop_on_error: true
    timeout: 10000
formats:
  - konnect-api
  - kongctl
{% endentity_examples %}

For more details, see the [configuration reference](/ai-gateway/policies/ai-prompt-compressor/reference/#configuration).

### Compressor Service endpoint

The compressor service exposes a [`/v1/compress`](https://docs.headroomlabs.ai/docs/proxy#post-v1compress) endpoint that compresses messages and returns them. This endpoint accepts openai and anthropic's message formats. For an enterprise deployment you must specify an API key, for a local deployment no PAI key is required. You can use this interface to compress prompts, check the current status, or integrate the service with the AI Prompt Compressor Policy.

### Headroom prompt flow

1. {{site.ai_gateway}} sends the user or agent's request to the AI Prompt Compressor.
2. The AI Prompt Compressor builds an OpenAI-format messages array from the eligible content. This operates on a per block basis, not the whole request, to ensure cache compatibility.
3. The AI Prompt Compressor sends a `POST` request to Headroom's `/v1/compress` endpoint with the content to compress and any configuration specified in the policy.
4. Headroom returns `200` with the compressed replacement messages and metadata. AI Prompt Compressor records `ccr_hashes` alongside the compressed block so a later retrieval request can be resolved.

If Headroom returns a failure response (such as a `400` invalid request, `503` service unavailable, `compression_timeout`, or `compression_error`) then the AI Prompt Compressor fails open. The original uncompressed message is sent to the upstream provider.

The following diagram illustrates how the AI Prompt Compressor Policy processes and compresses incoming prompts using Headroom:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    actor User as User/Agent
    participant KongAICompressor as AI Prompt Compressor Policy
    participant Headroom
    participant LLM as Large Language Model

    User->>KongAICompressor: Sends initial request
    activate KongAICompressor
    KongAICompressor->>KongAICompressor: Build OpenAI-format messages array per block

    KongAICompressor->>Headroom: POST /v1/compress
    activate Headroom

    alt Compression succeeds
        Headroom-->>KongAICompressor: Return 200 with compressed messages and metadata
        KongAICompressor->>KongAICompressor: Record ccr_hashes for later retrieval
    else Compression fails
        Headroom-->>KongAICompressor: Return failure response
        KongAICompressor->>KongAICompressor: Fail open, use original uncompressed message
    end
    deactivate Headroom

    KongAICompressor->>LLM: Send message to upstream provider
    deactivate KongAICompressor
    activate LLM
    LLM-->>User: Return response
    deactivate LLM
{% endmermaid %}
<!-- vale on -->



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

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}