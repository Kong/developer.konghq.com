{% assign plugin = include.plugin %}
{% assign id = plugin | slugify %}
{% assign provider = include.params.provider %}
{% assign route_type = include.params.route_type %}
{% assign options = include.params.options %}
{% assign providers = site.data.plugins.ai-proxy.providers %}


{{ page.description }}

The plugin accepts requests in one of a few defined and standardized formats, translates them to the configured target format, and then transforms the response back into a standard format.

<!-- if_version lte:3.6.x -->
The {{ plugin }} plugin supports `llm/v1/chat` and `llm/v1/completions` style requests for all of the following providers:
* OpenAI
* Cohere
* Azure
* Anthropic
* Mistral (raw and OLLAMA formats)
* Llama2 (raw, OLLAMA, and OpenAI formats)
<!-- endif_version -->
<!-- if_version gte:3.7.x -->
The following table describes which providers and requests the {{ plugin }} plugin supports:

{% include plugins/ai-proxy/tables/supported-providers.html providers=providers %}

## How it works

The {{ plugin }} plugin will mediate the following for you:

* Request and response formats appropriate for the configured `{{ provider }}` and `{{ route_type }}`
* The following service request coordinates (unless the model is self-hosted):
  * Protocol
  * Host name
  * Port
  * Path
  * HTTP method
* Authentication on behalf of the Kong API consumer
* Decorating the request with parameters from the `{{ options }}` block, appropriate for the chosen provider
* Recording of usage statistics of the configured LLM provider and model into your selected [Kong log](/hub/?category=logging) plugin output
* Optionally, additionally recording all post-transformation request and response messages from users, to and from the configured LLM
* Fulfillment of requests to self-hosted models, based on select supported format transformations

Flattening all of the provider formats allows you to standardize the manipulation of the data before and after transmission. It also allows your to provide a choice of LLMs to the Kong consumers, using consistent request and response formats, regardless of the backend provider or model.

This plugin currently only supports REST-based full text responses.