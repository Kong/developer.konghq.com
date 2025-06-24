{% assign plugin = include.plugin %}

{% assign provider = include.params.provider %}
{% assign provider_slug = provider | slugify | prepend: 'schema--' %}

{% assign route_type = include.params.route_type %}
{% assign route_type_slug = route_type | slugify | prepend: 'schema--' %}

{% assign upstream_url = include.params.upstream_url %}
{% assign upstream_url_slug = upstream_url | slugify | prepend: 'schema--' %}

{% assign providers = site.data.plugins.ai-proxy.providers %}


The plugin's [`route_type`](/plugins/ai-proxy/reference/#schema--config-route-type) should be set based on the target upstream endpoint and model, based on this capability matrix:

{:.warning}
> The following requirements are enforced by upstream providers:
>
> - For **Azure Responses API**, set `config.azure_api_version` to `"preview"`.
> - For **OpenAI** and **Azure Realtime APIs**, include the header `OpenAI-Beta: realtime=v1`.
> - Only **WebSocket** is supported—**WebRTC is not supported**.
> - For **OpenAI** and **Azure Assistant APIs**, include the header `OpenAI-Beta: assistants=v2`.
> - For requests with large payloads (e.g., image edits, audio transcription/translation), consider increasing `config.max_request_body_size` to **three times the raw binary size**.

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

#### Text generation inputs

The following examples show standardized text-based request formats for each supported `llm/v1/*` route. These formats are normalized across providers to help simplify downstream parsing and integration.

{% navtabs "text-generation" %}
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

{% new_in 3.9 %} With Amazon Bedrock, you can include your [guardrail](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) configuration in the request:

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

{% navtab "llm/v1/embeddings" %}
Supported in: {% new_in 3.11 %}
```json
  {
    "input": "The food was delicious and the waiter...",
    "model": "text-embedding-ada-002",
    "encoding_format": "float"
  }
```
{% endnavtab %}

{% navtab "llm/v1/files" %}
Supported in: {% new_in 3.11 %}
```json
curl http://localhost:8000 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F purpose="fine-tune" \
  -F file="@mydata.jsonl"
```
{% endnavtab %}

{% navtab "llm/v1/assisstants" %}
Supported in: {% new_in 3.11 %}
```json
{
    "instructions": "You are a personal math tutor. When asked a question, write and run Python code to answer the question.",
    "name": "Math Tutor",
    "tools": [{"type": "code_interpreter"}],
    "model": "gpt-4o"
  }
```
{% endnavtab %}

{% navtab "llm/v1/batches" %}
Supported in: {% new_in 3.11 %}
```json
{
    "input_file_id": "file-abc123",
    "endpoint": "/v1/chat/completions",
    "completion_window": "24h"
}
```
{% endnavtab %}

{% navtab "llm/v1/responses" %}
Supported in: {% new_in 3.11 %}
{:.info}
> This is a RESTful endpoint that supports all CRUD operations, but this preview example demonstrates only a `POST` request.


```json
  {
    "input": "Tell me a three sentence bedtime story about a unicorn."
  }
```
{% endnavtab %}

{% endnavtabs %}


#### Audio, image and realtime generation inputs

The following examples show standardized audio, image and realtime request formats for each supported route. These formats are normalized across providers to help simplify downstream parsing and integration.

{% navtabs "audio-image" %}

{% navtab "audio/v1/audio/speech" %}
Supported in: {% new_in 3.11 %}
```json
curl http://localhost:8000 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "input": "The quick brown fox jumped over the lazy dog.",
    "voice": "alloy"
  }' \
  --output speech.mp3
```
{% endnavtab %}

{% navtab "audio/v1/audio/transcriptions" %}
Supported in: {% new_in 3.11 %}
```json
curl http://localhost:8000/ \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F file="@/path/to/file/audio.mp3" \
  -F model="gpt-4o-transcribe"
```

{% endnavtab %}

{% navtab "audio/v1/audio/translations" %}
Supported in: {% new_in 3.11 %}
curl http://localhost:8000/ \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F file="@/path/to/file/german.m4a" \
  -F model="whisper-1"

{% endnavtab %}

{% navtab "image/v1/images/generations" %}
Supported in: {% new_in 3.11 %}
```json
{
  "prompt": "A cute baby sea otter",
  "n": 1,
  "size": "1024x1024"
}
```

{% endnavtab %}

{% navtab "image/v1/images/edits" %}
Supported in: {% new_in 3.11 %}
```json
curl -s -D >(grep -i x-request-id >&2) \
  -o >(jq -r '.data[0].b64_json' | base64 --decode > gift-basket.png) \
  -X POST "https://api.openai.com/v1/images/edits" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "model=gpt-image-1" \
  -F "image[]=@body-lotion.png" \
  -F "image[]=@bath-bomb.png" \
  -F "image[]=@incense-kit.png" \
  -F "image[]=@soap.png" \
  -F 'prompt=Create a lovely gift basket with these four items in it'

```

{% endnavtab %}

{% navtab "realtime/v1/realtime" %}
Supported in: {% new_in 3.11 %}
```json
{
  "model": "gpt-4o",
  "messages": [
    { "role": "system", "content": "You are a helpful assistant." },
    { "role": "user", "content": "Explain how rainbows form." }
  ]
}
```

{% endnavtab %}

{% endnavtabs %}

### Response formats

Conversely, the response formats are also transformed to a standard format across all providers:

#### Text-based responses


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

{% navtab "llm/v1/embeddings" %}
Supported in: {% new_in 3.11 %}
```json
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "embedding": [
        0.0023064255,
        -0.009327292,
        .... (1536 floats total for ada-002)
        -0.0028842222,
      ],
      "index": 0
    }
  ],
  "model": "text-embedding-ada-002",
  "usage": {
    "prompt_tokens": 8,
    "total_tokens": 8
  }
}
```
{% endnavtab %}

{% navtab "llm/v1/files" %}
Supported in: {% new_in 3.11 %}
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
Supported in: {% new_in 3.11 %}
```json
{
    "input_file_id": "file-abc123",
    "endpoint": "/v1/chat/completions",
    "completion_window": "24h"
}
```
{% endnavtab %}

{% navtab "llm/v1/assisstants" %}
Supported in: {% new_in 3.11 %}
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

{% navtab "llm/v1/responses" %}
Supported in: {% new_in 3.11 %}
```json
{
  "id": "resp_67ccd2bed1ec8190b14f964abc0542670bb6a6b452d3795b",
  "object": "response",
  "created_at": 1741476542,
  "status": "completed",
  "error": null,
  "incomplete_details": null,
  "instructions": null,
  "max_output_tokens": null,
  "model": "gpt-4.1-2025-04-14",
  "output": [
    {
      "type": "message",
      "id": "msg_67ccd2bf17f0819081ff3bb2cf6508e60bb6a6b452d3795b",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "In a peaceful grove beneath a silver moon, a unicorn named Lumina discovered a hidden pool that reflected the stars. As she dipped her horn into the water, the pool began to shimmer, revealing a pathway to a magical realm of endless night skies. Filled with wonder, Lumina whispered a wish for all who dream to find their own hidden magic, and as she glanced back, her hoofprints sparkled like stardust.",
          "annotations": []
        }
      ]
    }
  ],
  "parallel_tool_calls": true,
  "previous_response_id": null,
  "reasoning": {
    "effort": null,
    "summary": null
  },
  "store": true,
  "temperature": 1.0,
  "text": {
    "format": {
      "type": "text"
    }
  },
  "tool_choice": "auto",
  "tools": [],
  "top_p": 1.0,
  "truncation": "disabled",
  "usage": {
    "input_tokens": 36,
    "input_tokens_details": {
      "cached_tokens": 0
    },
    "output_tokens": 87,
    "output_tokens_details": {
      "reasoning_tokens": 0
    },
    "total_tokens": 123
  },
  "user": null,
  "metadata": {}
}
```

{% endnavtab %}
{% endnavtabs %}

#### Image, audio and realtime responses

The following examples show standardized response formats returned by supported `audio/`, `image/`, and `/realtime` routes. These formats are normalized across providers to support consistent multimodal output parsing.

{% navtabs "responses-audio-image-realtime" %}

{% navtab "llm/v1/audio/file/speech" %}

Supported in: {% new_in 3.11 %}

The response contains the audio file content of `speech.mp3`.

{% endnavtab %}

{% navtab "audio/v1/audio/transcriptions" %}
Supported in: {% new_in 3.11 %}
```json
{
  "text": "Imagine the wildest idea that you've ever had, and you're curious about how it might scale to something that's a 100, a 1,000 times bigger. This is a place where you can get to do that.",
  "usage": {
    "type": "tokens",
    "input_tokens": 14,
    "input_token_details": {
      "text_tokens": 0,
      "audio_tokens": 14
    },
    "output_tokens": 45,
    "total_tokens": 59
  }
}
```
{% endnavtab %}

{% navtab "audio/v1/audio/translations" %}
Supported in: {% new_in 3.11 %}
```json
{
  "text": "Hello, my name is Wolfgang and I come from Germany. Where are you heading today?"
}
```
{% endnavtab %}

{% navtab "image/v1/images/generations" %}
Supported in: {% new_in 3.11 %}
```json
{
  "created": 1713833628,
  "data": [
    {
      "b64_json": "..."
    }
  ],
  "usage": {
    "total_tokens": 100,
    "input_tokens": 50,
    "output_tokens": 50,
    "input_tokens_details": {
      "text_tokens": 10,
      "image_tokens": 40
    }
  }
}
```
{% endnavtab %}

{% navtab "image/v1/images/edit" %}
Supported in: {% new_in 3.11 %}
```json
{
  "created": 1713833628,
  "data": [
    {
      "b64_json": "..."
    }
  ],
  "usage": {
    "total_tokens": 100,
    "input_tokens": 50,
    "output_tokens": 50,
    "input_tokens_details": {
      "text_tokens": 10,
      "image_tokens": 40
    }
  }
}
```
{% endnavtab %}

{% navtab "realtime/v1/realtime" %}
```json
{ "type": "message_fragment", "content": "Rainbows form when light is refracted, reflected, and dispersed in water droplets." }
```
{% endnavtab %}
{% endnavtabs %}

The request and response formats are loosely modeled after OpenAI’s API. For detailed format specifications, see the [sample OpenAPI specification](https://github.com/kong/kong/blob/master/spec/fixtures/ai-proxy/oas.yaml).

## Supported native LLM formats

{% navtabs "llm_format_providers" %}

{% navtab "Gemini native format" %}

When [`config.llm_format`](./reference/#schema--config-llm-format) is set to `gemini`, only the Gemini provider is supported. The following Gemini APIs are available:

* `/generateContent`
* `/streamGenerateContent`
{% endnavtab %}

{% navtab "Bedrock native format" %}

When `llm_format` is set to `bedrock`, only the Bedrock provider is supported. Supported Bedrock APIs include:

* `/converse`
* `/converse-stream`
* `/retrieveAndGenerate`
* `/retrieveAndGenerateStream`
* `/rerank`
{% endnavtab %}

{% navtab "Cohere native format" %}
When [`config.llm_format`](./reference/#schema--config-llm-format) is set to `cohere`, only the Cohere provider is supported. Available Cohere APIs are:

* `/v1/rerank`
* `/v2/rerank`
{% endnavtab %}

{% navtab "Hugging Face native format" %}
When `llm_format` is set to `"huggingface"`, only the Hugging Face provider is supported. The following Hugging Face APIs are supported:

* `/generate`
* `/generate_stream`

{% endnavtab %}

{% endnavtabs %}

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