{% assign plugin = include.plugin %}
{% assign id = plugin | slugify %}

## Get started with the {{ plugin }} plugin

* [Configuration reference](/plugins/{{ id }}/reference/)
* [Basic configuration example](/plugins/{{ id }}/how-to/basic-example/)
* Learn how to use the plugin with different providers:
  * [OpenAI](/plugins/{{ id }}/how-to/llm-provider-integration-guides/openai/)
  * [Cohere](/plugins/{{ id }}/how-to/llm-provider-integration-guides/cohere/)
  * [Azure](/plugins/{{ id }}/how-to/llm-provider-integration-guides/azure/)
  * [Anthropic](/plugins/{{ id }}/how-to/llm-provider-integration-guides/anthropic/)
  * [Mistral](/plugins/{{ id }}/how-to/llm-provider-integration-guides/mistral/)
  * [Llama2](/plugins/{{ id }}/how-to/llm-provider-integration-guides/llama2/)
  * [Gemini/Vertex](/plugins/{{ id }}/how-to/llm-provider-integration-guides/gemini/)
  * [Amazon Bedrock](/plugins/{{ id }}/how-to/llm-provider-integration-guides/bedrock/)