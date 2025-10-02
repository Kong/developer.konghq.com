---
title: 'AI Prompt Compressor'
name: 'AI Prompt Compressor'

content_type: plugin
tier: ai_gateway_enterprise
publisher: kong-inc
description: Compress prompts before they are sent to LLMs to reduce costs, and improve latency

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.11'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-prompt-compressor.png

categories:
  - ai

tags:
  - ai

related_resources:
  - text: About AI Gateway
    url: /ai-gateway/
  - text: All AI Gateway plugins
    url: /plugins/?category=ai
  - text: AI RAG Injector
    url: /plugins/ai-rag-injector/
  - text: AI Prompt Decorator
    url: /plugins/ai-prompt-decorator/
  - text: Control prompt size with the AI Compressor plugin
    url: /how-to/compress-llm-prompts/

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
---

The **Kong AI Prompt Compressor** plugin compresses retrieved chunks before sending them to a Large Language Model (LLM), reducing text length while preserving meaning. It uses the [LLMLingua 2 library](https://github.com/microsoft/LLMLingua) for fast, high-quality compression. The plugin supports:

* **Ratio-based or target token compression** — for example, reduce a message to 80% of the original length or compress to 150 tokens.
* **Configurable compression ranges** — for example, compress prompts under 100 tokens with a 0.8 ratio or compress them to exactly 100 tokens.
* **Selective compression** using `<LLMLINGUA>...</LLMLINGUA>` tags to target specific sections of the prompt. These tags work **only in the `inject_template` field of the [AI RAG Injector plugin](/plugins/ai-rag-injector/)** and must be used **in combination with the AI Prompt Compressor**.

## Why use prompt compression

Efficient prompt compression helps you manage token limits, cut costs, and speed up LLM requests — all while keeping sensitive data safe and your prompts focused.

The table below outlines common use cases for the plugin and the configuration options available to tailor its behavior.

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

Kong provides a Docker image for the AI Prompt Compressor service, which compresses LLM prompts before sending them upstream. It uses [LLMLingua 2](https://github.com/microsoft/LLMLingua) to reduce prompt size, which helps you manage token limits and maintain context fidelity. The service supports both HTTP and JSON-RPC APIs and is designed to work with the AI Prompt Compressor plugin in AI Gateway.

{% include prereqs/cloudsmith.md %}

### Image configuration options

You can configure the Kong Compressor Service using environment variables. These affect model selection, hardware usage, logging, and worker behavior.

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

The compressor service exposes both REST and JSON-RPC endpoints. You can use these interfaces to compress prompts, check the current status, or integrate with upstream services and plugins.

* **POST `/llm/v1/compressPrompt`**: Compresses a prompt using either a compression ratio or a target token count. Supports selective compression via `<LLMLINGUA>` tags.

* **GET `/status`**: Returns information about the currently loaded LLMLingua model and device settings (for example, CPU or GPU).

* **POST `/`**: JSON-RPC endpoint that supports the `llm.v1.compressPrompt` method. Use this to invoke compression programmatically over JSON-RPC.

## Prompt compression options

The AI Prompt Compressor plugin offers flexible compression controls to fit different use cases. You can choose between full-prompt compression, conditional strategies, or selectively compressing only parts of the prompt:

<!-- vale off -->
{% table%}
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

1. The user sends the final prompt to the AI Prompt Compressor plugin.
1. The plugin checks the prompt for `<LLMLINGUA>`...`</LLMLINGUA>` tags.
    - If tags are found, only the tagged sections are sent to LLMLingua 2 for compression.
    - If no tags are found, the entire prompt is sent to LLMLingua 2 for compression.
1. Compression is applied based on configured rules—by ratio, target token count, or conditional length-based rules.
1. The compressed prompt is returned to the plugin.
1. The plugin sends the compressed prompt to the Large Language Model (LLM).
1. The LLM processes the prompt and returns the response to the user.

The diagram below illustrates how the AI Prompt Compressor plugin processes and compresses incoming prompts based on tagging and configured rules.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    actor User
    participant KongAICompressor as AI Prompt Compressor Plugin
    participant LLMLingua2 as LLMLingua 2 Compressor
    participant LLM as Large Language Model

    User->>KongAICompressor: Sends final prompt
    activate KongAICompressor
    KongAICompressor->>KongAICompressor: Check for LLMLINGUA tags

    alt Tagged content found
        KongAICompressor->>LLMLingua2: Compress tagged sections
        activate LLMLingua2
        LLMLingua2-->>KongAICompressor: Return compressed sections
        deactivate LLMLingua2
    else No LLMlingua tags
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

The AI Prompt Compressor plugin applies structured compression to preserve essential context of prompts sent by users, rather than trimming prompts arbitrarily or risking token overflows. This ensures the LLM receives a well-formed, focused prompt keeping token usage under control.
