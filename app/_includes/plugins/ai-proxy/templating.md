{% assign model_name = include.params.model_name %}
{% assign model_name_slug = model_name | slugify | prepend: 'schema--' %}

{% assign options = include.params.options %}
{% assign options_slug = options | slugify | prepend: 'schema--' %}

The plugin enables you to substitute values in the [`{{ model_name }}`](./reference/#{{ model_name_slug }}) and any parameter under [`{{ options }}`](./reference/#{{ options_slug }})
with specific placeholders, similar to those in the [Request Transformer Advanced](/plugins/request-transformer-advanced/)
templating system.

The following templated parameters are available:

* `$(headers.header_name)`: 
* `$(uri_captures.path_parameter_name)`
* `$(query_params.query_parameter_name)`

This can be used to OpenAI-compatible SDK with this plugin in multiple ways, depending on the required use case.

@todo: SDK examples