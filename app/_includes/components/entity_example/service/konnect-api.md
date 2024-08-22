{% if page.collection == 'gateway_entities' %}
  To create a service, call the Konnect [control plane config API’s /services endpoint](https://docs.konghq.com/konnect/api/control-plane-configuration/latest/#/Services/create-service).
{% endif %}
{% include components/entity_example/format/konnect-api/snippet.md presenter=include.presenter %}
