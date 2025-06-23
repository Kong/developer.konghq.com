{% navtabs "upstreams" %}
{% navtab "OpenAI" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths-openai.html providers=providers %}
{% endnavtab %}

{% navtab "Azure" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths-azure.html providers=providers %}
{% endnavtab %}

{% navtab "Mistral" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths-mistral.html providers=providers %}
{% endnavtab %}

{% navtab "Amazon Bedrock" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths-bedrock.html providers=providers %}
{% endnavtab %}

{% navtab "Llama2" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths-llama2.html providers=providers %}
{% endnavtab %}

{% navtab "Anthropic" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths-anthropic.html providers=providers %}
{% endnavtab %}

{% navtab "Cohere" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths-cohere.html providers=providers %}
{% endnavtab %}

{% navtab "Hugging Face" %}
{% include plugins/ai-proxy/tables/upstream-paths/upstream-paths-huggingface.html providers=providers %}
{% endnavtab %}
{% endnavtabs %}
