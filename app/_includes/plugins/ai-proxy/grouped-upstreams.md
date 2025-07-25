{% assign plugin = include.plugin %}

{% navtabs "upstreams" %}

{% if plugin == "AI Proxy" %}
{% navtab "Azure" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Azure"
    plugin=plugin %}

{:.info}
> **[1]**: If you use the `text-embedding-ada-002` as an embedding model, you must set a fixed dimension of `1536`, as required by the official model specification. Alternatively, use the `text-embedding-3-small` model, which supports dynamic dimensions and works without specifying a fixed value.

{% endnavtab %}

{% navtab "OpenAI" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="OpenAI"
    plugin=plugin %}

{:.info}
> **[1]**: If you use the `text-embedding-ada-002` as an embedding model, you must set a fixed dimension of `1536`, as required by the official model specification. Alternatively, use the `text-embedding-3-small` model, which supports dynamic dimensions and works without specifying a fixed value.

{% endnavtab %}

{% elsif plugin == "AI Proxy Advanced" %}
{% navtab "Azure" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Azure"
    plugin=plugin %}

{:.info}
> **[1]**: If you use the `text-embedding-ada-002` as an embedding model, you must set a fixed dimension of `1536`, as required by the official model specification. Alternatively, use the `text-embedding-3-small` model, which supports dynamic dimensions and works without specifying a fixed value.

{% endnavtab %}

{% navtab "OpenAI" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="OpenAI"
    plugin=plugin %}

{:.info}
> **[1]**: If you use the `text-embedding-ada-002` as an embedding model, you must set a fixed dimension of `1536`, as required by the official model specification. Alternatively, use the `text-embedding-3-small` model, which supports dynamic dimensions and works without specifying a fixed value.

{% endnavtab %}
{% endif %}

{% navtab "Amazon Bedrock" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Amazon Bedrock"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Anthropic" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Anthropic"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Cohere" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Cohere"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Gemini" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Gemini"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Gemini Vertex" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Gemini Vertex"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Hugging Face" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Hugging Face"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Llama2" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Llama2"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Mistral" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Mistral"
    plugin=plugin %}
{% endnavtab %}

{% endnavtabs %}
