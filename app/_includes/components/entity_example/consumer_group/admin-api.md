{% if page.collection == 'gateway_entities' %}
  To create a consumer group, call the [Admin API’s /consumer_groups endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/consumer_groups/post-consumer_groups).
{% endif %}
{% include components/entity_example/format/admin-api/snippet.md presenter=include.presenter %}
