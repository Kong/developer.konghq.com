## Partials {% new_in 3.13 %}

This plugin supports the `model` [Partial](/gateway/entities/partial/), which lets you define shared LLM provider, model name, authentication, and inference settings once and reuse them across multiple [{{site.ai_gateway}}](/ai-gateway/) plugins such as [AI Proxy Advanced](/plugins/ai-proxy-advanced/), [AI Request Transformer](/plugins/ai-request-transformer/), [AI Response Transformer](/plugins/ai-response-transformer/), and [AI LLM as Judge](/plugins/ai-llm-as-judge/).

{% table %}
columns:
  - title: Partial type
    key: type
  - title: Fields covered
    key: fields
rows:
  - type: "`model`"
    fields: "`config.llm`"
{% endtable %}

For setup instructions, see [AI plugin Partials](/gateway/entities/partial/#ai-plugin-partials).
