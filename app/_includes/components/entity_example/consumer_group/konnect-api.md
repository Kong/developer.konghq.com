{% if page.collection == 'gateway_entities' %}
  To create a consumer group, call the Konnect [control plane config API’s /consumer_groups endpoint](https://docs.konghq.com/konnect/api/control-plane-configuration/latest/#/Consumer%20Groups/create-consumer_group).
{% endif %}
{% include components/entity_example/format/konnect-api/snippet.md presenter=include.presenter %}
