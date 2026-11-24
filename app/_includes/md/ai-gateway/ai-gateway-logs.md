{%- assign new_in_38 = "" -%}
{%- if page.products contains 'gateway' -%}
{%- capture new_in_38 %}{% new_in 3.8 %} {% endcapture -%}
{%- endif %}
{{site.base_gateway}} collects logs for [{{site.ai_gateway}} Policies](/ai-gateway/policies/) and [{{site.ai_gateway}} plugins](/plugins/?category=ai). This allows you to aggregate AI usage analytics across various providers.

Each log entry includes the following details:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.$PLUGIN_NAME.payload.request`"
    description: The request payload.
  - property: "`ai.$PLUGIN_NAME.payload.response`"
    description: The response payload.
  - property: "`ai.$PLUGIN_NAME.usage.prompt_token`"
    description: The number of tokens used for prompting.
  - property: "`ai.$PLUGIN_NAME.usage.completion_token`"
    description: The number of tokens used for completion.
  - property: "`ai.$PLUGIN_NAME.usage.total_tokens`"
    description: The total number of tokens used.
  - property: "`ai.$PLUGIN_NAME.usage.cost`"
    description: The total cost of the request (input and output cost).
  - property: "`ai.$PLUGIN_NAME.usage.time_per_token`"
    description: |
      {{ new_in_38 }}The average time to generate an output token, in milliseconds.
  - property: "`ai.$PLUGIN_NAME.meta.request_model`"
    description:  The model used for the AI request.
  - property: "`ai.$PLUGIN_NAME.meta.provider_name`"
    description:  The name of the AI service provider.
  - property: "`ai.$PLUGIN_NAME.meta.response_model`"
    description:  The model used for the AI response.
  - property: "`ai.$PLUGIN_NAME.meta.plugin_id`"
    description:  The unique identifier of the plugin.
  - property: "`ai.$PLUGIN_NAME.meta.llm_latency`"
    description: |
      {{ new_in_38 }}The time, in milliseconds, it took the LLM provider to generate the full response.
  - property: "`ai.$PLUGIN_NAME.cache.cache_status`"
    description: |
      {{ new_in_38 }}The cache status. This can be `Hit`, `Miss`, `Bypass` or `Refresh`.
  - property: "`ai.$PLUGIN_NAME.cache.fetch_latency`"
    description: |
      {{ new_in_38 }}The time, in milliseconds, it took to return a cache response.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_provider`"
    description: |
      {{ new_in_38 }}For semantic caching, the provider used to generate the embeddings.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_model`"
    description: |
      {{ new_in_38 }}For semantic caching, the model used to generate the embeddings.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_latency`"
    description: |
      {{ new_in_38 }}For semantic caching, the time taken to generate the embeddings.{% endtable %}
<!--vale on-->
