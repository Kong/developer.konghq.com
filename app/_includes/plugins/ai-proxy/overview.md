{% assign plugin = include.plugin %}
{% assign provider = include.params.provider %}
{% assign route_type = include.params.route_type %}
{% assign options = include.params.options %}
{% assign providers = site.data.plugins.ai-proxy.providers %}

{{ page.description | liquify }}

{{ plugin }} plugin accepts requests in one of a few defined and standardized OpenAI formats, translates them to the configured target format, and then transforms the response back into a standard format.

{% new_in 3.10 %} To use {{ plugin }} with non-OpenAI format without conversion, see [section below](./#supported-native-llm-formats) for more details.

## Overview of capabilities

{{ plugin }} plugin supports capabilities across batch processing, multimodal embeddings, agents, audio, image, streaming, and more, spanning multiple providers:

For {{ site.base_gateway }} versions 3.6 or earlier:

* **Chat Completions APIs**: Multi-turn conversations with system/user/assistant roles.

* **Completions API**: Generates free-form text from a prompt. **OpenAI has marked this endpoint as legacy and recommends using the Chat Completions API for new applications.**

For {{ site.base_gateway }} version {% new_in 3.11 %}:

{% if plugin == "AI Proxy" %}

* **Batch, assistants, and files APIs**: Support parallel LLM calls for efficiency. Assistants enable stateful, tool-augmented agents. Files provide persistent document storage for richer context across sessions.
* **Audio capabilities APIs**: Provide speech-to-text transcription, real-time translation, and text-to-speech synthesis for voice agents, multilingual interfaces, and meeting analysis.
* **Image generation and editing APIs**: Generate and modify images from text prompts to support multimodal agents with visual input and output.
* **Responses API**: Return response metadata for debugging, evaluation, and response tuning.
* **AWS Bedrock agent APIs**: Support advanced orchestration and real-time RAG with `Converse`, `ConverseStream`, `RetrieveAndGenerate`, and `RetrieveAndGenerateStream`.
* **Hugging Face text generation**: Enable text generation and streaming using open-source Hugging Face models.
* **Embeddings API**: Provide unified text-to-vector embedding generation with multi-vendor support and analytics.
* **Rerank API**: Improve relevance of retrieved documents and results in RAG pipelines for [Cohere and Bedrock](./#supported-native-llm-formats). Send any list of candidates to be re-ordered based on prompt context to boost final LLM response quality through better grounding.

{% elsif plugin == "AI Proxy Advanced" %}

* **Batch, assistants, and files APIs**: Support parallel LLM calls for efficiency. Assistants enable stateful, tool-augmented agents. Files provide persistent document storage for richer context across sessions.
* **Audio capabilities APIs**: Provide speech-to-text transcription, real-time translation, and text-to-speech synthesis for voice agents, multilingual interfaces, and meeting analysis.
* **Image generation and editing APIs**: Generate and modify images from text prompts to support multimodal agents with visual input and output.
* **Responses API**: Return response metadata for debugging, evaluation, and response tuning.
* **AWS Bedrock agent APIs**: Support advanced orchestration and real-time RAG with `Converse`, `ConverseStream`, `RetrieveAndGenerate`, and `RetrieveAndGenerateStream`.
* **Hugging Face text generation**: Enable text generation and streaming using open-source Hugging Face models.
* **Embeddings API**: Provide unified text-to-vector embedding generation with multi-vendor support and analytics.
* **Rerank API**: Improve relevance of retrieved documents and results in RAG pipelines for [Cohere and Bedrock](./#supported-native-llm-formats). Send any list of candidates to be re-ordered based on prompt context to boost final LLM response quality through better grounding.
* **Realtime streaming**: Stream completions token-by-token for low-latency, interactive experiences and live analytics.


{% endif %}

The following reference tables detail feature availability across supported LLM providers when used with the {{ plugin }} plugin.

### Core text generation

Support for chat, completions, and embeddings.

{% include plugins/ai-proxy/tables/supported-providers-text.html providers=providers %}

The following providers are supported by the legacy Completions API:
* OpenAI
* Azure OpenAI
* Cohere
* Llama2
* Amazon Bedrock
* Gemini
* Hugging Face

### Advanced text generation {% new_in 3.11 %}

Support for function calling, tool use, and batch processing.

{% include plugins/ai-proxy/tables/supported-providers-processing.html providers=providers %}

### Audio features {% new_in 3.11 %}

Support for text-to-speech, transcription, and translation.

{% include plugins/ai-proxy/tables/supported-providers-audio.html providers=providers %}

{% if plugin == "AI Proxy" %}

### Image features {% new_in 3.11 %}

Support for image generation, and image editing interaction.

{% include plugins/ai-proxy/tables/supported-providers-image-ai-proxy.html providers=providers %}

{% elsif plugin == "AI Proxy Advanced" %}

### Image and realtime features {% new_in 3.11 %}

Support for image generation, image editing, and realtime interaction.

{% include plugins/ai-proxy/tables/supported-providers-image-ai-proxy-advanced.html providers=providers %}

{% endif %}


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
