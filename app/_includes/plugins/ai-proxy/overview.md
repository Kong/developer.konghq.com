{% assign plugin = include.plugin %}
{% assign provider = include.params.provider %}
{% assign route_type = include.params.route_type %}
{% assign options = include.params.options %}
{% assign providers = site.data.plugins.ai-proxy.providers %}

{{ page.description | liquify }}

The plugin accepts requests in one of a few defined and standardized formats, translates them to the configured target format, and then transforms the response back into a standard format.

## Overview of capabilities

The following tables present detailed feature support across all supported LLM providers.

### Core text generation feature

The following table summarizes provider support for core text generation features in {{ plugin }} plugin.

{% include plugins/ai-proxy/tables/supported-providers.html providers=providers %}

### Advanced text generation features {% new_in 3.11 %}

The following table summarizes provider support for advanced text generation via {{ plugin }} plugin.

{% include plugins/ai-proxy/tables/supported-providers-2.html providers=providers %}

### Audio capabilities {% new_in 3.11 %}

The following table shows which GenAI providers support audio-based features—text-to-speech, transcriptions, and translations—when accessed through the {{ plugin }} plugin.

{% include plugins/ai-proxy/tables/supported-providers-audio.html providers=providers %}

### Image and realtime capabilities {% new_in 3.11 %}

The table below lists support for image generation, image editing, and realtime interaction capabilities via the {{ plugin }} plugin.

{% include plugins/ai-proxy/tables/supported-providers-image.html providers=providers %}

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
* Recording of usage statistics of the configured LLM provider and model into your selected [Kong log](/plugins/?category=logging) plugin output
* Optionally, additionally recording all post-transformation request and response messages from users, to and from the configured LLM
* Fulfillment of requests to self-hosted models, based on select supported format transformations

Flattening all of the provider formats allows you to standardize the manipulation of the data before and after transmission. It also allows your to provide a choice of LLMs to the Kong consumers, using consistent request and response formats, regardless of the backend provider or model.

{:.info}
> {% new_in 3.11 %} This plugin supports REST-based full-text responses, including RESTful endpoints like `llm/v1/responses`. RESTful endpoints support multiple HTTP methods—for example, you can `POST` to create a response, `GET` to retrieve it, or `DELETE` to remove it.
