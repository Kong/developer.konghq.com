{% if page.collection == 'gateway_entities' %}
  To create a route, call the Konnect [control plane config API's /routes endpoint](https://docs.konghq.com/konnect/api/control-plane-configuration/latest/#/Routes/create-route).
{% endif %}
{% include components/entity_example/format/konnect-api/snippet.md presenter=include.presenter %}
