{% assign model_name = include.params.model_name %}
{% assign model_name_slug = model_name | slugify | prepend: 'schema--' %}

{% assign options = include.params.options %}
{% assign options_slug = options | slugify | prepend: 'schema--' %}

The plugin allows you to substitute values in the [`{{ model_name }}`](./reference/#{{ model_name_slug }}) and any parameter under [`{{ options }}`](./reference/#{{ options_slug }})
with specific placeholders, similar to those in the [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin.

The following templated parameters are available:

* `$(headers.header_name)`: The value of a specific request header.
* `$(uri_captures.path_parameter_name)`: The value of a captured URI path parameter.
* `$(query_params.query_parameter_name)`: The value of a query string parameter.

You can combine these parameters with an OpenAI-compatible SDK in multiple ways using the AI Proxy plugin, depending on your specific use case:

<!--vale off-->
{% table %}
columns:
  - title: Action
    key: action
  - title: Description
    key: description
rows:
  - action: "[Use chat route with dynamic model selection](./examples/sdk-dynamic-model-selection/)"
    description: |
      Configure a chat route that reads the target model from the request path instead of hardcoding it in the configuration.
  - action: "[Use the Azure deployment relevant to a specific model name](./examples/sdk-azure-deployment/)"
    description: |
      Configure a header capture to insert the requested model name directly into the plugin configuration for {{site.ai_gateway}} deployment with Azure OpenAI, as a string substitution.
  - action: "[Proxy multiple models deployed in the same Azure instance](./examples/sdk-multiple-providers/)"
    description: |
      Configure one route to proxy multiple models deployed in the same Azure instance.
{% endtable %}
<!--vale on-->

This can be used to OpenAI-compatible SDK with this plugin in multiple ways, depending on the required use case.

