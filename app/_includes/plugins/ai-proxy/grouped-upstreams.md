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

{:.warning}
> To use the `realtime/v1/realtime` route, users must configure the [`protocols`](/plugins/ai-proxy-advanced/reference/#schema--protocols) to `ws` and/or `wss` on both the service and on the route where the plugin is associated.