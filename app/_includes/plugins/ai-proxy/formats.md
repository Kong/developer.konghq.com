{% assign plugin = include.plugin %}

{% assign provider = include.params.provider %}
{% assign provider_slug = provider | slugify | prepend: 'schema--' %}

{% assign route_type = include.params.route_type %}
{% assign route_type_slug = route_type | slugify | prepend: 'schema--' %}

{% assign upstream_url = include.params.upstream_url %}
{% assign upstream_url_slug = upstream_url | slugify | prepend: 'schema--' %}

{% assign providers = site.data.plugins.ai-proxy.providers %}

Kong AI Gateway mediates the request and response format based on the selected [`{{ provider }}`](./reference/#{{ provider_slug }}) and [`{{ route_type }}`](./reference/#{{ route_type_slug }}).

The `{{ route_type }}` must be configured respective to the required request and response format examples. Check specific [AI provider's reference page](/ai-gateway/ai-providers/) for more details.

{:.info}
> {% new_in 3.10 %} By default, Kong AI Gateway uses the OpenAI format, but you can customize this using [`config.llm_format`](./reference/#schema--config-llm-format). If `llm_format` is not set to `openai`, the plugin will not transform the request when sending it upstream and will leave it as-is.
>
> See the [section below](#supported-native-llm-formats) for more details.

### Input formats

The {{ plugin }} plugin accepts the following inputs formats, standardized across all providers.

#### Text generation inputs

The following examples show standardized text-based request formats for each supported `llm/v1/*` route. These formats are normalized across providers to help simplify downstream parsing and integration.

{% include plugins/ai-proxy/text-inputs.md %}

#### Audio, image and video generation inputs

The following examples show standardized audio and image request formats for each supported route. These formats are normalized across providers to help simplify downstream parsing and integration.

{% include plugins/ai-proxy/image-audio-inputs.md %}

### Response formats

Conversely, the response formats are also transformed to a standard format across all providers:

#### Text-based responses

{% include plugins/ai-proxy/text-responses.md %}

#### Image, audio and video responses

The following examples show standardized response formats returned by supported `audio/` and `image/` routes. These formats are normalized across providers to support consistent multimodal output parsing.

{% include plugins/ai-proxy/image-audio-responses.md %}

The request and response formats are loosely modeled after OpenAI’s API. For detailed format specifications, see the [sample OpenAPI specification](https://github.com/kong/kong/blob/master/spec/fixtures/ai-proxy/oas.yaml).

## Supported native LLM formats {% new_in 3.10 %}

If you use a [provider’s](/ai-gateway/ai-providers/) native SDK, Kong AI Gateway {% new_in 3.10 %} can proxy the request and return the upstream response without payload format conversion. Set `config.llm_format` to a value other than `openai` to preserve the provider’s native request and response formats.

In this mode, Kong AI Gateway will still provide analytics, logging, and cost calculation.
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