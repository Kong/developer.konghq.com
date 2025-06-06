{% assign plugin = include.plugin %}

{% assign provider = include.params.provider %}
{% assign provider_slug = provider | slugify | prepend: 'schema--' %}

{% assign route_type = include.params.route_type %}
{% assign route_type_slug = route_type | slugify | prepend: 'schema--' %}

{% assign upstream_url = include.params.upstream_url %}
{% assign upstream_url_slug = upstream_url | slugify | prepend: 'schema--' %}

{% assign providers = site.data.plugins.ai-proxy.providers %}


The plugin's [`{{ route_type }}`](./reference/#{{ route_type_slug }}) should be set based on the target upstream endpoint and model, based on this capability matrix:

{% include plugins/ai-proxy/tables/upstream-paths.html providers=providers %}

The following upstream URL patterns are used:

{% include plugins/ai-proxy/tables/upstream-urls.html providers=providers upstream=upstream_url %}

{:.warning}
> While only the **Llama2** and **Mistral** models are classed as self-hosted, the target URL can be overridden for any of the supported providers.
> For example, a self-hosted or otherwise OpenAI-compatible endpoint can be called by setting the same [`{{ upstream_url }}`](./reference/#{{ upstream_url_slug }}) plugin option.<br/><br/>
> {% new_in 3.10 %} If you are using each provider's native SDK, {{site.base_gateway}} allows you to transparently proxy the request without any transformation and return the response unmodified. This can be done by setting [`config.llm_format`](./reference/#schema--config-llm-format) to a value other than `openai`, such as `gemini` or `bedrock`.
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
{% endnavtabs %}

The request and response formats are loosely based on OpenAI.
See the [sample OpenAPI specification](https://github.com/kong/kong/blob/master/spec/fixtures/ai-proxy/oas.yaml) for more detail on the supported formats.