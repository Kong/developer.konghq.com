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

See the following table for capabilities supported in {{ site.base_gateway }} version {% new_in 3.11 %} or later:

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
  - title: "Embeddings"
    description: Offers unified text-to-vector embedding with support for multiple providers and analytics.
    openai_compatible: true
    examples: |
      * [`llm/v1/embeddings`](./examples/embeddings-route-type/)<br>

  - title: "Assistants and responses"
    description: Powers persistent tool-using agents and exposes metadata for debugging and evaluation.
    openai_compatible: true
    examples: |
      * [`llm/v1/assistants`](./examples/assistants-route-type/)<br>
      * [`llm/v1/responses`](./examples/responses-route-type/)<br>

  - title: "Batch and files"
    description: Supports parallel LLM requests and file upload for long documents and structured input.
    openai_compatible: true
    examples: |
      * [`llm/v1/batch`](./examples/batches-route-type/)<br>
      * [`llm/v1/files`](./examples/files-route-type/)<br>
      * [`llm/v1/batches` Send asynchronous requests to LLMs](/how-to/send-asychronous-llm-requests/)

  - title: "Audio"
    description: Enables speech-to-text, text-to-speech, and real-time translation for voice agents and multilingual UIs.
    openai_compatible: true
    examples: |
      * [`/v1/audio/transcriptions`](./examples/audio-transcription-openai/)<br>
      * [`/v1/audio/speech`](./examples/audio-speech-openai/)<br>

  - title: "Image generation and editing"
    description: Generates or modifies images from text prompts for multimodal agent input/output.
    openai_compatible: true
    examples: |
      * [`/v1/images/generations`](./examples/image-generation-openai/)<br>
      * [`/v1/images/edits`](./examples/image-edits-openai/)<br>

  - title: "AWS Bedrock agent APIs"
    description: Enables advanced orchestration and real-time RAG via Converse and RetrieveAndGenerate endpoints.
    openai_compatible: false
    examples: |
      * [`/converse`](./#supported-native-llm-formats)<br>
      * [`/retrieveAndGenerate`](./#supported-native-llm-formats)<br>

  - title: "Hugging Face text generation"
    description: Provides text generation and streaming using open-source Hugging Face models.
    openai_compatible: false
    examples: |
      * [`/text-generation`](./#supported-native-llm-formats)<br>

  - title: "Rerank"
    description: Improves relevance in RAG pipelines by reordering documents based on context.
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
  - title: "Embeddings"
    description: Offers unified text-to-vector embedding with support for multiple providers and analytics.
    openai_compatible: true
    examples: |
      * [`/v1/embeddings`](./examples/embeddings-route-type/)

  - title: "Assistants and responses"
    description: Powers persistent tool-using agents and exposes metadata for debugging and evaluation.
    openai_compatible: true
    examples: |
      * [`/v1/assistants`](./examples/assistants-route-type/)<br>
      * [`/v1/responses`](./examples/responses-route-type/)<br>
      * [Secure GitHub MCP Server traffic using `llm/v1/responses` route type](/mcp/secure-mcp-traffic/)<br>

  - title: "Batch and files"
    description: Supports parallel LLM requests and file upload for long documents and structured input.
    openai_compatible: true
    examples: |
      * [`/v1/batch`](./examples/batches-route-type/)<br>
      * [`/v1/files`](./examples/files-route-type/)<br>
      * [`llm/v1/batches` Send asynchronous requests to LLMs](/how-to/send-asychronous-llm-requests/)

  - title: "Audio"
    description: Enables speech-to-text, text-to-speech, and real-time translation for voice agents and multilingual UIs.
    openai_compatible: true
    examples: |
      * [`/v1/audio/transcriptions`](./examples/audio-transcription-openai/)<br>
      * [`/v1/audio/speech`](./examples/audio-speech-openai/)<br>

  - title: "Image generation and editing"
    description: Generates or modifies images from text prompts for multimodal agent input/output.
    openai_compatible: true
    examples: |
      * [`/v1/images/generations`](./examples/image-generation-openai/)<br>
      * [`/v1/images/edits`](./examples/image-edits-openai/)<br>

  - title: "Realtime streaming"
    description: "Stream completions token-by-token for low-latency, interactive experiences, and live analytics."
    openai_compatible: true
    examples: |
      * [`/v1/realtime`](./examples/realtime-route-openai/)<br>

  - title: "AWS Bedrock agent APIs"
    description: Enables advanced orchestration and real-time RAG via Converse and RetrieveAndGenerate endpoints.
    openai_compatible: false
    examples: |
      * [`/converse`](./#supported-native-llm-formats)<br>
      * [`/retrieveAndGenerate`](./#supported-native-llm-formats)<br>

  - title: "Hugging Face text generation"
    description: Provides text generation and streaming using open-source Hugging Face models.
    openai_compatible: false
    examples: |
      * [`/text-generation`](./#supported-native-llm-formats)<br>

  - title: "Rerank"
    description: Improves relevance in RAG pipelines by reordering documents based on context using Bedrock or Cohere `/rerank` APIs.
    openai_compatible: false
    examples: |
      * [`/rerank`](./#supported-native-llm-formats)<br>
{% endfeature_table %}

{% endif %}

<!-- vale on -->

### Core text generation

The following reference tables detail feature availability across supported LLM providers when used with the {{ plugin }} plugin.

Support for chat, completions, and embeddings:

{% include plugins/ai-proxy/tables/supported-providers-text.html providers=providers %}

{:.neutral}
> The following providers are supported by the legacy [Completions API](https://platform.openai.com/docs/api-reference/completions):
> * OpenAI
> * Azure OpenAI
> * Cohere
> * Llama2
> * Amazon Bedrock
> * Gemini
> * Hugging Face

### Advanced text generation {% new_in 3.11 %}

Support for function calling, tool use, and batch processing:

{% include plugins/ai-proxy/tables/supported-providers-processing.html providers=providers %}

### Audio features {% new_in 3.11 %}

Support for text-to-speech, transcription, and translation:

{% include plugins/ai-proxy/tables/supported-providers-audio.html providers=providers %}

### Image features {% new_in 3.11 %}

Support for image generation, image editing{% if plugin == "AI Proxy Advanced" %}, and realtime streaming{% endif %} interaction:

{% include plugins/ai-proxy/tables/supported-providers-image.html providers=providers plugin=plugin %}

### Video features {% new_in 3.13 %}

Support for video generation:

{% include plugins/ai-proxy/tables/supported-providers-video.html providers=providers plugin=plugin %}

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
