{% assign plugin = include.plugin %}
{% assign id = plugin | slugify %}

## Get started with the {{ plugin }} plugin

* [Configuration reference](/plugins/{{ id }}/reference/)
* Learn how to use the plugin with different providers:
  * [OpenAI](/plugins/{{ id }}/examples/openai-chat-route/)
  * [Cohere](/plugins/{{ id }}/examples/cohere-chat-route/)
  * [Azure](/plugins/{{ id }}/examples/azure-chat-route/)
  * [Anthropic](/plugins/{{ id }}/examples/anthropic-chat-route/)
  * [Mistral](/plugins/{{ id }}/examples/mistral-chat-route/)
  * [Llama2](/plugins/{{ id }}/examples/llama2-chat-route/)
  * [Gemini/Vertex](/plugins/{{ id }}/examples/gemini-chat-route/)
  * [Amazon Bedrock](/plugins/{{ id }}/examples/bedrock-chat-route/)
  * [Hugging Face](/plugins/{{ id }}/examples/huggingface-chat-route/)

{% include plugins/ai-plugins.md %}