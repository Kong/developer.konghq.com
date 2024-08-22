{% if page.collection == 'gateway_entities' %}
  To create a consumer, call the [Admin API’s /consumers endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Consumers/create-consumer).
  The following creates a new consumer called **{{ include.presenter.data['username'] }}**:
{% endif %}
{% include components/entity_example/format/admin-api/snippet.md presenter=include.presenter %}
