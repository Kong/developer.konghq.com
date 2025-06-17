{% assign plugin = include.plugin %}
{% assign provider = include.params.provider %}
{% assign route_type = include.params.route_type %}
{% assign options = include.params.options %}
{% assign providers = site.data.plugins.ai-proxy.providers %}

{{ page.description | liquify }}

{{ plugin }} plugin accepts requests in one of a few defined and standardized formats, translates them to the configured target format, and then transforms the response back into a standard format.

## Overview of Capabilities

The following tables detail feature availability across supported LLM providers when used with the {{ plugin }} plugin.

### Core Text Generation

This table outlines support for core text generation features such as chat, completions, and embeddings.

{% include plugins/ai-proxy/tables/supported-providers.html providers=providers %}

### Advanced Text Generation {% new_in 3.11 %}

This table highlights support for advanced text generation features, including function calling, tool use, and batch processing.

{% include plugins/ai-proxy/tables/supported-providers-2.html providers=providers %}

### Audio Features {% new_in 3.11 %}

This table shows which providers support audio-based capabilities—text-to-speech, transcription, and translation.

{% include plugins/ai-proxy/tables/supported-providers-audio.html providers=providers %}

### Image and Realtime Features {% new_in 3.11 %}

This table lists support for image generation, image editing, and realtime interaction features.

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
> {% new_in 3.11 %} {{ plugin }} supports REST-based full-text responses, including RESTful endpoints such as `llm/v1/responses`, `llm/v1/files`, `llm/v1/assisstants` and `llm/v1/batches`. RESTful endpoints support CRUD operations— you can `POST` to create a response, `GET` to retrieve it, or `DELETE` to remove it.
