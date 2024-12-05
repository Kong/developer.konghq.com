{% case include.presenter.entity_type %}
{% when 'consumer' %}
  To create a consumer, call the Konnect [control plane config API’s /consumers endpoint](/api/konnect/control-planes-config/#/operations/create-consumer). 
{% when 'consumer_group' %}
  To create a consumer group, call the Konnect [control plane config API’s /consumer_groups endpoint](/api/konnect/control-planes-config/#/operations/create-consumer_group).
{% when 'route' %}
  To create a route, call the Konnect [control plane config API's /routes endpoint](/api/konnect/control-planes-config/#/operations/create-route).
{% when 'service' %}
  To create a service, call the Konnect [control plane config API’s /services endpoint](/api/konnect/control-planes-config/#/operations/create-service).
{% when 'target' %}
  To create a target, call the Konnect [control plane config API’s /targets endpoint](/api/konnect/control-planes-config/#/operations/create-target-with-upstream). 
{% when 'upstream' %}
  The following creates a new upstream called **{{ include.presenter.data['name'] }}**:
{% when workspace %}
  To create a workspace, call the [Admin API’s /workspaces endpoint](/api/gateway/admin-ee/#/operations/create-workspace).
{% when 'plugin' %}
  Make the following request:
{% else %}
{% endcase %}

{% include components/entity_example/format/snippets/konnect-api.md presenter=include.presenter %}

{% if include.render_context %}
{% include components/entity_example/replace_variables.md missing_variables=include.presenter.missing_variables %}
See the <a href="https://docs.konghq.com/konnect/api/">Konnect API reference</a> to learn about region-specific URLs and personal access tokens.
{% endif %}
