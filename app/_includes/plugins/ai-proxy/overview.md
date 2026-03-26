{% assign plugin = include.plugin %}
{% assign provider = include.params.provider %}
{% assign route_type = include.params.route_type %}
{% assign options = include.params.options %}
{% assign providers = site.data.plugins.ai-proxy.providers %}

{{ page.description | liquify }}

{{ plugin }} plugin accepts requests in one of a few defined and standardized OpenAI formats, translates them to the configured target format, and then transforms the response back into a standard format.

{% new_in 3.10 %} To use {{ plugin }} with non-OpenAI format without conversion, see [section below](./#supported-native-llm-formats) for more details.

## Overview of capabilities

{{ plugin }} plugin supports capabilities across batch processing, multimodal embeddings, agents, audio, image, streaming, and more, spanning multiple providers.

For {{ site.base_gateway }} versions 3.6 or earlier:

* **Chat Completions APIs**: Multi-turn conversations with system/user/assistant roles.

* **Completions API**: Generates free-form text from a prompt.

  {:.warning}
  > OpenAI has marked this endpoint as [legacy](https://platform.openai.com/docs/api-reference/completions) and recommends using the [Chat Completions API](https://platform.openai.com/docs/guides/text?api-mode=responses) for developing new applications.

See the following table for capabilities supported in {{site.ai_gateway}}:

<!-- vale off -->
{% if plugin == "AI Proxy" %}

{% feature_table %}
item_title: API capability
columns:
  - title: Description
    key: description
  - title: Examples
    key: examples
  - title: OpenAI format
    key: openai_compatible

features:
  - title: "Chat completions"
    description: Generates conversational responses from a sequence of messages using supported LLM providers.
    openai_compatible: true
    examples: |
      * [`llm/v1/chat`](./examples/openai-chat-route/)<br>

  - title: "Embeddings"
    description: Converts text to vector representations for semantic search and similarity matching.
    openai_compatible: true
    examples: |
      * [`llm/v1/embeddings`](./examples/embeddings-route-type/)<br>

  - title: "Function calling"
    description: Allows models to invoke external tools and APIs based on conversation context.
    openai_compatible: true
    examples: |
      * llm/v1/chat

  - title: "Assistants and responses"
    description: Powers persistent tool-using agents and exposes metadata for debugging and evaluation.
    openai_compatible: true
    examples: |
      * [`llm/v1/assistants`](./examples/assistants-route-type/)<br>
      * [`llm/v1/responses`](./examples/responses-route-type/)<br>

  - title: "Batches and files"
    description: Supports asynchronous bulk LLM requests and file uploads for long documents and structured input.
    openai_compatible: true
    examples: |
      * [`llm/v1/batches`](./examples/batches-route-type/)<br>
      * [`llm/v1/files`](./examples/files-route-type/)<br>
      * [Send asynchronous requests to LLMs](/how-to/send-asychronous-llm-requests/)

  - title: "Audio"
    description: Enables speech-to-text, text-to-speech, and translation for voice applications.
    openai_compatible: true
    examples: |
      * [`audio/v1/audio/transcriptions`](./examples/audio-transcription-openai/)<br>
      * [`audio/v1/audio/speech`](./examples/audio-speech-openai/)<br>
      * [`audio/v1/audio/translations`](./examples/audio-translation-openai/)<br>

  - title: "Image generation and editing"
    description: Generates or modifies images from text prompts.
    openai_compatible: true
    examples: |
      * [`image/v1/images/generations`](./examples/image-generation-openai/)<br>
      * [`image/v1/images/edits`](./examples/image-edits-openai/)<br>

  - title: "Video generation"
    description: Generates videos from text prompts.
    openai_compatible: true
    examples: |
      * [`video/v1/videos/generations`](./examples/video-generation-openai/)<br>

  - title: "AWS Bedrock native APIs"
    description: |
      Enables advanced orchestration and real-time RAG via Converse and RetrieveAndGenerate endpoints.
      <br><br>
      Available only when using [native LLM format](./#supported-native-llm-formats) for Bedrock.
    openai_compatible: false
    examples: |
      * [`/converse`](./#supported-native-llm-formats)<br>
      * [`/retrieveAndGenerate`](./#supported-native-llm-formats)<br>

  - title: "Hugging Face native APIs"
    description: |
      Provides text generation and streaming using Hugging Face models.
      <br><br>
      Available only when using [native LLM format](./#supported-native-llm-formats) for Hugging Face.
    openai_compatible: false
    examples: |
      * [`/generate`](./#supported-native-llm-formats)<br>

  - title: "Rerank"
    description: |
      Reorders documents by relevance for RAG pipelines using Bedrock or Cohere rerank APIs.
      <br><br>
      Available only when using [native LLM format](./#supported-native-llm-formats) for Bedrock and Cohere.
    openai_compatible: false
    examples: |
      * [`/rerank`](./#supported-native-llm-formats)<br>
{% endfeature_table %}

{% elsif plugin == "AI Proxy Advanced" %}

{% feature_table %}
item_title: API capability
columns:
  - title: Description
    key: description
  - title: Examples
    key: examples
  - title: OpenAI format
    key: openai_compatible

features:
  - title: "Chat completions"
    description: Generates conversational responses from a sequence of messages using supported LLM providers.
    openai_compatible: true
    examples: |
      * [`llm/v1/chat`](./examples/openai-chat-route/)<br>

  - title: "Embeddings"
    description: Converts text to vector representations for semantic search and similarity matching.
    openai_compatible: true
    examples: |
      * [`llm/v1/embeddings`](./examples/embeddings-route-type/)<br>

  - title: "Function calling"
    description: Allows models to invoke external tools and APIs based on conversation context.
    openai_compatible: true
    examples: |
      * "`llm/v1/chat`"

  - title: "Assistants and responses"
    description: Powers persistent tool-using agents and exposes metadata for debugging and evaluation.
    openai_compatible: true
    examples: |
      * [`llm/v1/assistants`](./examples/assistants-route-type/)<br>
      * [`llm/v1/responses`](./examples/responses-route-type/)<br>

  - title: "Batches and files"
    description: Supports asynchronous bulk LLM requests and file uploads for long documents and structured input.
    openai_compatible: true
    examples: |
      * [`llm/v1/batches`](./examples/batches-route-type/)<br>
      * [`llm/v1/files`](./examples/files-route-type/)<br>
      * [Send asynchronous requests to LLMs](/how-to/send-asychronous-llm-requests/)

  - title: "Audio"
    description: Enables speech-to-text, text-to-speech, and translation for voice applications.
    openai_compatible: true
    examples: |
      * [`audio/v1/audio/transcriptions`](./examples/audio-transcription-openai/)<br>
      * [`audio/v1/audio/speech`](./examples/audio-speech-openai/)<br>
      * [`audio/v1/audio/translations`](./examples/audio-translation-openai/)<br>

  - title: "Image generation and editing"
    description: Generates or modifies images from text prompts.
    openai_compatible: true
    examples: |
      * [`image/v1/images/generations`](./examples/image-generation-openai/)<br>
      * [`image/v1/images/edits`](./examples/image-edits-openai/)<br>

  - title: "Video generation"
    description: Generates videos from text prompts.
    openai_compatible: true
    examples: |
      * [`video/v1/videos/generations`](./examples/video-generation-openai/)<br>

  - title: "Realtime"
    description: Bidirectional WebSocket streaming for low-latency, interactive voice and text applications.
    openai_compatible: true
    examples: |
      * [`realtime/v1/realtime`](./examples/realtime-route-openai/)<br>

  - title: "AWS Bedrock native APIs"
    description: |
      Enables advanced orchestration and real-time RAG via Converse and RetrieveAndGenerate endpoints.
      <br><br>
      Available only when using [native LLM format](./#supported-native-llm-formats) for Bedrock.
    openai_compatible: false
    examples: |
      * [`/converse`](./#supported-native-llm-formats)<br>
      * [`/retrieveAndGenerate`](./#supported-native-llm-formats)<br>

  - title: "Hugging Face native APIs"
    description: |
      Provides text generation and streaming using Hugging Face models.
      <br><br>
      Available only when using [native LLM format](./#supported-native-llm-formats) for Hugging Face.
    openai_compatible: false
    examples: |
      * [`/generate`](./#supported-native-llm-formats)<br>

  - title: "Rerank"
    description: |
      Reorders documents by relevance for RAG pipelines using Bedrock or Cohere rerank APIs.
      <br><br>
      Available only when using [native LLM format](./#supported-native-llm-formats) for Bedrock and Cohere.
    openai_compatible: false
    examples: |
      * [`/rerank`](./#supported-native-llm-formats)<br>
{% endfeature_table %}

{% endif %}

<!-- vale on -->

{:.neutral}
> The following providers are supported by the legacy [Completions API](https://platform.openai.com/docs/api-reference/completions):
> * OpenAI
> * Azure OpenAI
> * Cohere
> * Llama2
> * Amazon Bedrock
> * Gemini
> * Hugging Face

## Supported AI providers

{{site.ai_gateway}} supports proxying requests to the following AI providers. Each provider page documents supported capabilities, configuration requirements, and provider-specific details.

{:.info}
> For detailed capability support, configuration requirements, and provider-specific limitations, see the individual [provider reference pages](/ai-gateway/ai-providers/).

{% html_tag type="div" css_classes="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3" %}
{% include cards/third_party_tool.md icon="openai.svg" content="OpenAI" %}
{% include cards/third_party_tool.md icon="azure.svg" content="Azure OpenAI" %}
{% include cards/third_party_tool.md icon="bedrock.svg" content="Amazon Bedrock" %}
{% include cards/third_party_tool.md icon="anthropic.svg" content="Anthropic" %}
{% include cards/third_party_tool.md icon="gemini.svg" content="Gemini" %}
{% include cards/third_party_tool.md icon="vertex.svg" content="Vertex AI" %}
{% include cards/third_party_tool.md icon="cohere.svg" content="Cohere" %}
{% include cards/third_party_tool.md icon="mistral.svg" content="Mistral" %}
{% include cards/third_party_tool.md icon="huggingface.svg" content="Hugging Face" %}
{% include cards/third_party_tool.md icon="metaai.svg" content="Llama" %}
{% include cards/third_party_tool.md icon="xai.svg" content="xAI" %}
{% include cards/third_party_tool.md icon="dashscope.svg" content="Alibaba Cloud DashScope" %}
{% include cards/third_party_tool.md icon="cerebras.svg" content="Cerebras" %}
{% include cards/third_party_tool.md icon="deepseek.svg" content="DeepSeek" %}
{% include cards/third_party_tool.md icon="ollama.svg" content="Ollama" %}
{% include cards/third_party_tool.md icon="databricks.svg" content="Databricks" %}
{% endhtml_tag %}

## How it works

The {{ plugin }} plugin will mediate the following for you:

* Request and response formats appropriate for the configured `{{ provider }}` and `{{ route_type }}`
* The following service request coordinates (unless the model is self-hosted):
  * Protocol
  * Host name
  * Port
  * Path
  * HTTP method
* Authentication on behalf of the Kong API consumer
* Decorating the request with parameters from the `{{ options }}` block, appropriate for the chosen provider
* Recording of usage statistics of the configured LLM provider and model into your selected [Kong log](/plugins/?category=logging) plugin output
* Optionally, additionally recording all post-transformation request and response messages from users, to and from the configured LLM
* Fulfillment of requests to self-hosted models, based on select supported format transformations

Flattening all of the provider formats allows you to standardize the manipulation of the data before and after transmission. It also allows your to provide a choice of LLMs to the {{site.base_gateway}} Consumers, using consistent request and response formats, regardless of the backend provider or model.

{:.info}
> {% new_in 3.11 %} {{ plugin }} supports REST-based full-text responses, including RESTful endpoints such as `llm/v1/responses`, `llm/v1/files`, `llm/v1/assisstants` and `llm/v1/batches`. RESTful endpoints support CRUD operations— you can `POST` to create a response, `GET` to retrieve it, or `DELETE` to remove it.
