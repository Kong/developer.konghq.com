{% assign plugin = include.plugin %}

{% assign provider = include.params.provider %}
{% assign provider_slug = provider | slugify | prepend: 'schema--' %}

{% assign route_type = include.params.route_type %}
{% assign route_type_slug = route_type | slugify | prepend: 'schema--' %}

{% assign upstream_url = include.params.upstream_url %}
{% assign upstream_url_slug = upstream_url | slugify | prepend: 'schema--' %}

{% assign providers = site.data.plugins.ai-proxy.providers %}

{{site.ai_gateway}} transforms requests and responses according to the configured [`{{ provider }}`](./reference/#{{ provider_slug }}) and [`{{ route_type }}`](./reference/#{{ route_type_slug }}), using the OpenAI format by default. {% new_in 3.10 %} To use a provider's native format instead, set [`config.llm_format`](./reference/#schema--config-llm-format) to a value other than `openai`. The plugin then passes requests upstream without transformation. See [Supported native LLM formats](#supported-native-llm-formats) for available options.

The following table maps each route type to its [OpenAI API](https://platform.openai.com/docs/api-reference) reference and generative AI category. See the [AI provider reference pages](/ai-gateway/ai-providers/) for provider-specific details.

{% if plugin == "AI Proxy" %}
{% table %}
columns:
  - title: Route type
    key: route
  - title: OpenAI API reference
    key: reference
  - title: Gen AI Category
    key: category
  - title: Gateway min version
    key: version
rows:
  - route: "`llm/v1/chat`"
    reference: "[Chat completions](https://platform.openai.com/docs/api-reference/chat/create)"
    category: "`text/generation`"
    version: "3.6"
  - route: "`llm/v1/completions`"
    reference: "[Completions](https://platform.openai.com/docs/api-reference/completions)"
    category: "`text/generation`"
    version: "3.6"
  - route: "`llm/v1/embeddings`"
    reference: "[Embeddings](https://platform.openai.com/docs/api-reference/embeddings)"
    category: "`text/embeddings`"
    version: "3.11"
  - route: "`llm/v1/files`"
    reference: "[Files](https://platform.openai.com/docs/api-reference/files)"
    category: "N/A"
    version: "3.11"
  - route: "`llm/v1/batches`"
    reference: "[Batch](https://platform.openai.com/docs/api-reference/batch)"
    category: "N/A"
    version: "3.11"
  - route: "`llm/v1/assistants`"
    reference: "[Assistants](https://platform.openai.com/docs/api-reference/assistants)"
    category: "`text/generation`"
    version: "3.11"
  - route: "`llm/v1/responses`"
    reference: "[Responses](https://platform.openai.com/docs/api-reference/responses)"
    category: "`text/generation`"
    version: "3.11"
  - route: "`audio/v1/audio/speech`"
    reference: "[Create speech](https://platform.openai.com/docs/api-reference/audio/createSpeech)"
    category: "`audio/speech`"
    version: "3.11"
  - route: "`audio/v1/audio/transcriptions`"
    reference: "[Create transcription](https://platform.openai.com/docs/api-reference/audio/createTranscription)"
    category: "`audio/transcription`"
    version: "3.11"
  - route: "`audio/v1/audio/translations`"
    reference: "[Create translation](https://platform.openai.com/docs/api-reference/audio/createTranslation)"
    category: "`audio/transcription`"
    version: "3.11"
  - route: "`image/v1/images/generations`"
    reference: "[Create image](https://platform.openai.com/docs/api-reference/images)"
    category: "`image/generation`"
    version: "3.11"
  - route: "`image/v1/images/edits`"
    reference: "[Create image edit](https://platform.openai.com/docs/api-reference/images/createEdit)"
    category: "`image/generation`"
    version: "3.11"
  - route: "`video/v1/videos/generations`"
    reference: "[Create video](https://platform.openai.com/docs/api-reference/videos/create)"
    category: "`video/generation`"
    version: "3.13"
{% endtable %}
{% elsif plugin == "AI Proxy Advanced" %}
{% table %}
columns:
  - title: Route type
    key: route
  - title: OpenAI API reference
    key: reference
  - title: Gen AI category
    key: category
  - title: Min version
    key: version
rows:
  - route: "`llm/v1/chat`"
    reference: "[Chat completions](https://platform.openai.com/docs/api-reference/chat/create)"
    category: "`text/generation`"
    version: "3.6"
  - route: "`llm/v1/completions`"
    reference: "[Completions](https://platform.openai.com/docs/api-reference/completions)"
    category: "`text/generation`"
    version: "3.6"
  - route: "`llm/v1/embeddings`"
    reference: "[Embeddings](https://platform.openai.com/docs/api-reference/embeddings)"
    category: "`text/embeddings`"
    version: "3.11"
  - route: "`llm/v1/files`"
    reference: "[Files](https://platform.openai.com/docs/api-reference/files)"
    category: "N/A"
    version: "3.11"
  - route: "`llm/v1/batches`"
    reference: "[Batch](https://platform.openai.com/docs/api-reference/batch)"
    category: "N/A"
    version: "3.11"
  - route: "`llm/v1/assistants`"
    reference: "[Assistants](https://platform.openai.com/docs/api-reference/assistants)"
    category: "`text/generation`"
    version: "3.11"
  - route: "`llm/v1/responses`"
    reference: "[Responses](https://platform.openai.com/docs/api-reference/responses)"
    category: "`text/generation`"
    version: "3.11"
  - route: "`realtime/v1/realtime`"
    reference: "[Realtime](https://platform.openai.com/docs/api-reference/realtime)"
    category: "`realtime/generation`"
    version: "3.11"
  - route: "`audio/v1/audio/speech`"
    reference: "[Create speech](https://platform.openai.com/docs/api-reference/audio/createSpeech)"
    category: "`audio/speech`"
    version: "3.11"
  - route: "`audio/v1/audio/transcriptions`"
    reference: "[Create transcription](https://platform.openai.com/docs/api-reference/audio/createTranscription)"
    category: "`audio/transcription`"
    version: "3.11"
  - route: "`audio/v1/audio/translations`"
    reference: "[Create translation](https://platform.openai.com/docs/api-reference/audio/createTranslation)"
    category: "`audio/transcription`"
    version: "3.11"
  - route: "`image/v1/images/generations`"
    reference: "[Create image](https://platform.openai.com/docs/api-reference/images)"
    category: "`image/generation`"
    version: "3.11"
  - route: "`image/v1/images/edits`"
    reference: "[Create image edit](https://platform.openai.com/docs/api-reference/images/createEdit)"
    category: "`image/generation`"
    version: "3.11"
  - route: "`video/v1/videos/generations`"
    reference: "[Create video](https://platform.openai.com/docs/api-reference/videos/create)"
    category: "`video/generation`"
    version: "3.13"
{% endtable %}
{% endif %}

{:.info}
> Provider-specific parameters can be passed using the `extra_body` field in your request. See the [sample OpenAPI specification](https://github.com/kong/kong/blob/master/spec/fixtures/ai-proxy/oas.yaml) for detailed format examples.

## Supported native LLM formats {% new_in 3.10 %}

If you use a [provider’s](/ai-gateway/ai-providers/) native SDK, {{site.ai_gateway}} {% new_in 3.10 %} can proxy the request and return the upstream response without payload format conversion. Set `config.llm_format` to a value other than `openai` to preserve the provider’s native request and response formats.

In this mode, {{site.ai_gateway}} will still provide analytics, logging, and cost calculation.
When `config.llm_format` is set to a native format, only the corresponding provider is supported with its specific APIs.

<!-- vale off -->
{% table %}
columns:
  - title: Provider
    key: provider
  - title: LLM format
    key: llm_format
  - title: Native capabilities
    key: capabilities
rows:
  - llm_format: "`anthropic`"
    provider: "[Anthropic](/ai-gateway/ai-providers/anthropic/#supported-native-llm-formats-for-anthropic)"
    capabilities: Messages, batch processing
  - llm_format: "`bedrock`"
    provider: "[Amazon Bedrock](/ai-gateway/ai-providers/bedrock/#supported-native-llm-formats-for-amazon-bedrock)"
    capabilities: Converse, RAG (RetrieveAndGenerate), reranking, async invocation
  - llm_format: "`cohere`"
    provider: "[Cohere](/ai-gateway/ai-providers/cohere/#supported-native-llm-formats-for-cohere)"
    capabilities: Reranking
  - llm_format: "`gemini`"
    provider: "[Gemini](/ai-gateway/ai-providers/gemini/#supported-native-llm-formats-for-gemini)"
    capabilities: Content generation, embeddings, batches, file uploads
  - llm_format: "`gemini`"
    provider: "[Vertex AI](/ai-gateway/ai-providers/vertex/#supported-native-llm-formats-for-gemini-vertex)"
    capabilities: Content generation, embeddings, batches, reranking, long-running predictions
  - llm_format: "`huggingface`"
    provider: "[Hugging Face](/ai-gateway/ai-providers/huggingface/#supported-native-llm-formats-for-hugging-face)"
    capabilities: Text generation, streaming
{% endtable %}
<!-- vale on -->