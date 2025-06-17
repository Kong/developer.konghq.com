{% assign plugin = include.plugin %}

{% assign provider = include.params.provider %}
{% assign provider_slug = provider | slugify | prepend: 'schema--' %}

{% assign route_type = include.params.route_type %}
{% assign route_type_slug = route_type | slugify | prepend: 'schema--' %}

{% assign upstream_url = include.params.upstream_url %}
{% assign upstream_url_slug = upstream_url | slugify | prepend: 'schema--' %}

{% assign providers = site.data.plugins.ai-proxy.providers %}


The plugin's [`route_type`](/plugins/ai-proxy/reference/#schema--config-route-type) should be set based on the target upstream endpoint and model, based on this capability matrix:

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

The Kong AI Proxy accepts the following inputs formats, standardized across all providers. The `{{ route_type }}` must be configured respective to the required request and response format examples:

{% navtabs "ai-proxy-route-type" %}
{% navtab "llm/v1/chat" %}
```json
{
    "messages": [
        {
            "role": "system",
            "content": "You are a scientist."
        },
        {
            "role": "user",
            "content": "What is the theory of relativity?"
        }
    ]
}
```

{% new_in 3.9 %}With Amazon Bedrock, you can include your [guardrail](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) configuration in the request:
```json
{
    "messages": [
        {
            "role": "system",
            "content": "You are a scientist."
        },
        {
            "role": "user",
            "content": "What is the theory of relativity?"
        }
    ],
      "guardrailConfig": {
              "guardrailIdentifier":"<guardrail_identifier>",
              "guardrailVersion":"1",
              "trace":"enabled"
          }
}
```

{% endnavtab %}

{% navtab "llm/v1/completions" %}
```json
{
    "prompt": "You are a scientist. What is the theory of relativity?"
}
```
{% endnavtab %}

{% navtab "llm/v1/files" %}

```json
curl https://localhost:8000 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F purpose="fine-tune" \
  -F file="@mydata.jsonl"
```
{% endnavtab %}

{% navtab "llm/v1/batches" %}

```json
{
    "input_file_id": "file-abc123",
    "endpoint": "/v1/chat/completions",
    "completion_window": "24h"
}
```
{% endnavtab %}

{% navtab "llm/v1/assisstants" %}

```json
{
    "instructions": "You are a personal math tutor. When asked a question, write and run Python code to answer the question.",
    "name": "Math Tutor",
    "tools": [{"type": "code_interpreter"}],
    "model": "gpt-4o"
  }
```
{% endnavtab %}

{% navtab "llm/v1/audio/speech" %}

```json
curl https://localhost:8000 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini-tts",
    "input": "The quick brown fox jumped over the lazy dog.",
    "voice": "alloy"
  }' \
  --output speech.mp3
```
{% endnavtab%}
{% endnavtabs %}

### Response formats

Conversely, the response formats are also transformed to a standard format across all providers:

{% navtabs "ai-proxy-route-type" %}
{% navtab "llm/v1/chat" %}
```json
{
    "choices": [
        {
            "finish_reason": "stop",
            "index": 0,
            "message": {
                "content": "The theory of relativity is a...",
                "role": "assistant"
            }
        }
    ],
    "created": 1707769597,
    "id": "chatcmpl-ID",
    "model": "gpt-4-0613",
    "object": "chat.completion",
    "usage": {
        "completion_tokens": 5,
        "prompt_tokens": 26,
        "total_tokens": 31
    }
}
```
{% endnavtab %}

{% navtab "llm/v1/completions" %}

```json
{
    "choices": [
        {
            "finish_reason": "stop",
            "index": 0,
            "text": "The theory of relativity is a..."
        }
    ],
    "created": 1707769597,
    "id": "cmpl-ID",
    "model": "gpt-3.5-turbo-instruct",
    "object": "text_completion",
    "usage": {
        "completion_tokens": 10,
        "prompt_tokens": 7,
        "total_tokens": 17
    }
}
```
{% endnavtab %}

{% navtab "llm/v1/files" %}

```json
{
  "id": "file-abc123",
  "object": "file",
  "bytes": 120000,
  "created_at": 1677610602,
  "filename": "mydata.jsonl",
  "purpose": "fine-tune",
}
```
{% endnavtab %}

{% navtab "llm/v1/batches" %}

```json
{
    "input_file_id": "file-abc123",
    "endpoint": "/v1/chat/completions",
    "completion_window": "24h"
}
```
{% endnavtab %}

```json
{
  "id": "batch_abc123",
  "object": "batch",
  "endpoint": "/v1/chat/completions",
  "errors": null,
  "input_file_id": "file-abc123",
  "completion_window": "24h",
  "status": "validating",
  "output_file_id": null,
  "error_file_id": null,
  "created_at": 1711471533,
  "in_progress_at": null,
  "expires_at": null,
  "finalizing_at": null,
  "completed_at": null,
  "failed_at": null,
  "expired_at": null,
  "cancelling_at": null,
  "cancelled_at": null,
  "request_counts": {
    "total": 0,
    "completed": 0,
    "failed": 0
  },
  "metadata": {
    "customer_id": "user_123456789",
    "batch_description": "Nightly eval job",
  }
}
```
{% navtab "llm/v1/assisstants" %}

```json
{
  "id": "asst_abc123",
  "object": "assistant",
  "created_at": 1698984975,
  "name": "Math Tutor",
  "description": null,
  "model": "gpt-4o",
  "instructions": "You are a personal math tutor. When asked a question, write and run Python code to answer the question.",
  "tools": [
    {
      "type": "code_interpreter"
    }
  ],
  "metadata": {},
  "top_p": 1.0,
  "temperature": 1.0,
  "response_format": "auto"
}
```

{% endnavtab %}

{% navtab "llm/v1/audio/file/speech" %}

The audio file content `speech.mp3`

{% endnavtab %}
{% endnavtabs %}


The request and response formats are loosely modeled after OpenAI’s API. For detailed format specifications, see the [sample OpenAPI specification](https://github.com/kong/kong/blob/master/spec/fixtures/ai-proxy/oas.yaml).

## Supported native LLM formats

{% navtabs "llm_format_providers" %}

{% navtab "Gemini native format" %}
When `llm_format` is set to `"gemini"`, only the Gemini provider is supported. The following Gemini APIs are available:

* `/generateContent`
* `/streamGenerateContent`
{% endnavtab %}

{% navtab "Bedrock native format" %}
When `llm_format` is set to `"bedrock"`, only the Bedrock provider is supported. Supported Bedrock APIs include:

* `/converse`
* `/converse-stream`
* `/retrieveAndGenerate`
* `/retrieveAndGenerateStream`
* `/rerank`
{% endnavtab %}

{% navtab "Cohere native format" %}
When `llm_format` is set to `"cohere"`, only the Cohere provider is supported. Available Cohere APIs are:

* `/v1/rerank`
* `/v2/rerank`
{% endnavtab %}

{% navtab "Hugging Face native format" %}
When `llm_format` is set to `"huggingface"`, only the Hugging Face provider is supported. The following Hugging Face APIs are supported:

* `/generate`
* `/generate-stream`
{% endnavtab %}

{% endnavtabs %}

### Caveats and limitations

#### Provider-specific limitations

* **Anthropic**: Does not support `llm/v1/completions` or `llm/v1/embeddings`.
* **Llama2**: Raw format lacks support for `llm/v1/embeddings`.
* **Bedrock** and **Gemini**: Only support `auth.allow_override = false`.

#### Statistics logging limitations

* **Anthropic**: No statistics logging for `llm/v1/completions`.
* **OpenAI** and **Azure**: No statistics logging for assistants, batch, or audio APIs.
* **Bedrock**: No statistics logging for image generation or editing APIs.
