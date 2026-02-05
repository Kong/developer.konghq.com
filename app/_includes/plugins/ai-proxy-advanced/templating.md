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
  - action: "[Use one chat route with dynamic Azure OpenAI deployments](./examples/sdk-azure-one-route/)"
    description: |
      Configure a dynamic route to target multiple Azure OpenAI model deployments.
  - action: "[Use multiple routes to map mulitple Azure Deployment](./examples/sdk-multiple-azure-deployments/)"
    description: |
       Use separate Routes to map Azure OpenAI SDK requests to specific deployments of GPT-3.5 and GPT-4.
{% endtable %}
<!--vale on-->


