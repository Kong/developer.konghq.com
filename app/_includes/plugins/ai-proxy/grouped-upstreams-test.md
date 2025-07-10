{% navtabs "upstreams" %}

{% assign plugin = include.plugin %}

{% if plugin == "AI Proxy" %}
{% navtab "OpenAI" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="OpenAI" %}
{% endnavtab %}

{% navtab "Azure" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="Azure" %}
{% endnavtab %}



{% elsif plugin == "AI Proxy Advanced" %}
{% navtab "OpenAI" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="OpenAI" %}
{% endnavtab %}

{% navtab "Azure" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="Azure" %}
{% endnavtab %}
{% endif %}

{% navtab "Mistral" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="Mistral" %}
{% endnavtab %}

{% navtab "Amazon Bedrock" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="Amazon Bedrock" %}
{% endnavtab %}

{% navtab "Llama2" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="Llama2" %}
{% endnavtab %}

{% navtab "Anthropic" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="Anthropic" %}
{% endnavtab %}

{% navtab "Cohere" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="Cohere" %}
{% endnavtab %}

{% navtab "Hugging Face" %}
{% include plugins/ai-proxy/tables/upstream-paths/test-table.html providers=providers provider_name="Hugging Face" %}
{% endnavtab %}

{% endnavtabs %}


