{% if page.collection == 'gateway_entities' %}
  To create a consumer, call the Konnect [control plane config API’s /consumers endpoint](https://docs.konghq.com/konnect/api/control-plane-configuration/latest/#/Consumers). 
  The following creates a new consumer called **{{ include.presenter.data['username'] }}**:
{% endif %}
{% include components/entity_example/format/konnect-api/snippet.md presenter=include.presenter %}
