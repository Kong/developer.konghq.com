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

You can combine these parameters with an OpenAI-compatible SDK in multiple ways using the AI Proxy and AI Proxy Advanced plugins, depending on your specific use case:

<!--vale off-->
{% table %}
columns:
  - title: Action
    key: action
  - title: Description
    key: description
rows:
  - action: "[Select different models dynamically on one provider](./examples/sdk-dynamic-model-selection/)"
    description: |
      Allow users to select the target model based on a request header or parameter. Supports flexible routing across different models on the same provider.
  - action: "[Select different providers dynamically](./examples/sdk-dynamic-provider-selection/)"
    description: |
      Proxy the same request to different LLM providers, allowing users to dynamically choose their preferred provider.
  - action: "[Target multiple Azure deployments with two routes](./examples/sdk-static-azure-deployments/)"
    description: |
      Use two static routes to expose different Azure OpenAI deployments. Each route maps to a specific deployment.
  - action: "[Target multiple Azure deployments dynamically on one route](./examples/sdk-dynamic-azure-deployments/)"
    description: |
      Use one dynamic route with URI captures to route requests to different Azure OpenAI deployments based on the path.
  - action: "[Use unsupported models with OpenAI-compatible SDKs](./examples/sdk-unsupported-model/)"
    description: |
      Proxy models that are not officially supported, like Whisper-2, through an OpenAI-compatible interface using preserve routing.
{% endtable %}
<!--vale on-->


