## Partials {% new_in 3.13 %}

This plugin supports `vectordb` and `embeddings` [Partials](/gateway/entities/partial/), which let you define shared vector database and embeddings configuration once and reuse it across multiple [{{site.ai_gateway}}](/ai-gateway/) plugins. This is useful when running this plugin alongside others that use the same vector database and embeddings model, such as [AI Semantic Cache](/plugins/ai-semantic-cache/), [AI RAG Injector](/plugins/ai-rag-injector/), [AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/), [AI Semantic Response Guard](/plugins/ai-semantic-response-guard/), and [AI Proxy Advanced](/plugins/ai-proxy-advanced/).

{% table %}
columns:
  - title: Partial type
    key: type
  - title: Fields covered
    key: fields
rows:
  - type: "`vectordb`"
    fields: "`config.vectordb`"
  - type: "`embeddings`"
    fields: "`config.embeddings`"
{% endtable %}

For setup instructions, see [AI plugin Partials](/gateway/entities/partial/#ai-plugin-partials).
