{% assign plugin = include.plugin %}

{% navtabs "upstreams" %}

{% if plugin == "AI Proxy" %}
{% navtab "OpenAI" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="OpenAI"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Azure" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Azure"
    plugin=plugin %}
{% endnavtab %}

{% elsif plugin == "AI Proxy Advanced" %}
{% navtab "OpenAI" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="OpenAI"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Azure" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Azure"
    plugin=plugin %}
{% endnavtab %}
{% endif %}

{% navtab "Mistral" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Mistral"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Amazon Bedrock" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Amazon Bedrock"
    plugin=plugin %}
{% endnavtab %}

{% navtab "Llama2" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Llama2"
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

{% navtab "Hugging Face" %}
  {% include plugins/ai-proxy/tables/upstream-paths/upstream-paths.html
    providers=providers
    provider_name="Hugging Face"
    plugin=plugin %}
{% endnavtab %}

{% endnavtabs %}
