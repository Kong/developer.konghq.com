{% assign plugin = include.plugin %}

{% assign provider = include.params.provider %}
{% assign provider_slug = provider | slugify | prepend: 'schema--' %}

{% assign route_type = include.params.route_type %}
{% assign route_type_slug = route_type | slugify | prepend: 'schema--' %}

{% assign upstream_url = include.params.upstream_url %}
{% assign upstream_url_slug = upstream_url | slugify | prepend: 'schema--' %}

{% assign providers = site.data.plugins.ai-proxy.providers %}


The plugin's [`route_type`](/plugins/ai-proxy/reference/#schema--config-route-type) should be set based on the target upstream endpoint and model, based on this capability matrix:

{% if plugin == "AI Proxy" %}

{:.warning}
> The following requirements are enforced by upstream providers:
>
> - For **Azure Responses API**, set `config.azure_api_version` to `"preview"`.
> - For **OpenAI** and **Azure Assistant APIs**, include the header `OpenAI-Beta: assistants=v2`.
> - For requests with large payloads (e.g., image edits, audio transcription/translation), consider increasing `config.max_request_body_size` to **three times the raw binary size**.

{% elsif plugin == "AI Proxy Advanced" %}

{:.warning}
> The following requirements are enforced by upstream providers:
>
> - For **Azure Responses API**, set `config.azure_api_version` to `"preview"`.
> - For **OpenAI** and **Azure Realtime APIs**, include the header `OpenAI-Beta: realtime=v1`.
> - Only **WebSocket** is supported—**WebRTC is not supported**.
> - For **OpenAI** and **Azure Assistant APIs**, include the header `OpenAI-Beta: assistants=v2`.
> - For requests with large payloads (e.g., image edits, audio transcription/translation), consider increasing `config.max_request_body_size` to **three times the raw binary size**.

{% endif %}

{% include plugins/ai-proxy/grouped-upstreams.md %}

The following upstream URL patterns are used:

{% include plugins/ai-proxy/tables/upstream-urls.html providers=providers upstream=upstream_url %}

{:.warning}
> While only the **Llama2** and **Mistral** models are classed as self-hosted, the target URL can be overridden for any of the supported providers.
> For example, a self-hosted or otherwise OpenAI-compatible endpoint can be called by setting the same [`{{ upstream_url }}`](./reference/#{{ upstream_url_slug }}) plugin option.<br/><br/>
> {% new_in 3.10 %} If you are using each provider's native SDK, {{site.base_gateway}} allows you to transparently proxy the request without any transformation and return the response unmodified. This can be done by setting [`config.llm_format`](./reference/#schema--config-llm-format) to a value other than `openai`, such as `gemini` or `bedrock`. See the [section below](./#supported-native-llm-formats) for more details.
> <br><br>
> In this mode, {{site.base_gateway}} will still provide useful analytics, logging, and cost calculation.

### Input formats

{{site.base_gateway}} mediates the request and response format based on the selected [`{{ provider }}`](./reference/#{{ provider_slug }}) and [`{{ route_type }}`](./reference/#{{ route_type_slug }}).

{% new_in 3.10 %} By default, {{site.base_gateway}} uses the OpenAI format, but you can customize this using [`config.llm_format`](./reference/#schema--config-llm-format). If `llm_format` is not set to `openai`, the plugin will not transform the request when sending it upstream and will leave it as-is.

The {{site.base_gateway}} AI Proxy accepts the following inputs formats, standardized across all providers. The `{{ route_type }}` must be configured respective to the required request and response format examples.

#### Text generation inputs

The following examples show standardized text-based request formats for each supported `llm/v1/*` route. These formats are normalized across providers to help simplify downstream parsing and integration.

{% include plugins/ai-proxy/text-inputs.md %}

#### Audio and image generation inputs

The following examples show standardized audio and image request formats for each supported route. These formats are normalized across providers to help simplify downstream parsing and integration.

{% include plugins/ai-proxy/image-audio-inputs.md %}

### Response formats

Conversely, the response formats are also transformed to a standard format across all providers:

#### Text-based responses

{% include plugins/ai-proxy/text-responses.md %}

#### Image, and audio responses

The following examples show standardized response formats returned by supported `audio/` and `image/` routes. These formats are normalized across providers to support consistent multimodal output parsing.

{% include plugins/ai-proxy/image-audio-responses.md %}

The request and response formats are loosely modeled after OpenAI’s API. For detailed format specifications, see the [sample OpenAPI specification](https://github.com/kong/kong/blob/master/spec/fixtures/ai-proxy/oas.yaml).

## Supported native LLM formats

When [`config.llm_format`](./reference/#schema--config-llm-format) is set to a native format, only the corresponding provider is supported with its specific APIs as listed below.

<!-- vale off -->
{% table %}
columns:
  - title: LLM format
    key: llm_format
  - title: Provider
    key: provider
  - title: Supported APIs
    key: apis
rows:
  - llm_format: "[`gemini`](./examples/gemini-native-routes/)"
    provider: Gemini
    apis: |
      - `/v1beta/models/{model_name}:generateContent`
      - `/v1beta/models/{model_name}:streamGenerateContent`
      - `/v1beta/models/{model_name}:embedContent`
      - `/v1beta/models/{model_name}:batchEmbedContent`
      - `/v1beta/batches`
      - `/upload/{file_id}/files
      - `/v1beta/files`
  - llm_format: "[`gemini`](./examples/gemini-native-routes/)"
    provider: Vertex
    apis: |
      - `/v1/projects/{project_id}/locations/{location}/models/{model_name}:generateContent`
      - `/v1/projects/{project_id}/locations/{location}/models/{model_name}:streamGenerateContent`
      - `/v1/projects/{project_id}/locations/{location}/models/{model_name}:embedContent`
      - `/v1/projects/{project_id}/locations/{location}/models/{model_name}:batchEmbedContent`
      - `/v1/projects/{project_id}/locations/{location}/models/{model_name}:predictLongRunning`
      - `/v1/projects/{project_id}/locations/{location}/rankingConfigs/{config_name}:rank`
      - `/v1/projects/{project_id}/locations/{location}/batchPredictionJobs`
  - llm_format: "[`bedrock`](./examples/bedrock-native-routes/)"
    provider: Bedrock
    apis: |
      - `/model/{model_name}/converse`
      - `/model/{model_name}/converse-stream`
      - `/model/{model_name}/invoke`
      - `/model/{model_name}/invoke-with-response-stream`
      - `/model/{model_name}/retrieveAndGenerate`
      - `/model/{model_name}/retrieveAndGenerateStream`
      - `/model/{model_name}/rerank`
      - `/model/{model_name}/async-invoke`
      - `/model-invocations`
  - llm_format: "[`cohere`](./examples/cohere-native-routes/)"
    provider: Cohere
    apis: |
      - `/v1/rerank`
      - `/v2/rerank`
  - llm_format: "[`huggingface`](./examples/hugging-face-native-routes/)"
    provider: Hugging Face
    apis: |
      - `/generate`
      - `/generate_stream`
{% endtable %}
<!-- vale on -->

### Caveats and limitations

The following sections detail the provider and statistic logging limitations.

#### Provider-specific limitations

* **Anthropic**: Does not support `llm/v1/completions` or `llm/v1/embeddings`.
* **Llama2**: Raw format lacks support for `llm/v1/embeddings`.
* **Bedrock** and **Gemini**: Only support `auth.allow_override = false`.

#### Statistics logging limitations

* **Anthropic**: No statistics logging for `llm/v1/completions`.
* **OpenAI** and **Azure**: No statistics logging for assistants, batch, or audio APIs.
* **Bedrock**: No statistics logging for image generation or editing APIs.