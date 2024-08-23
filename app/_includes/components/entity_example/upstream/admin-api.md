{% if page.collection == 'gateway_entities' %}
  To create a upstream, call the [Admin API’s /upstreams endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Upstreams/create-upstream).
  The following creates a new upstream called **{{ include.presenter.data['name'] }}**:
{% endif %}
{% include components/entity_example/format/admin-api/snippet.md presenter=include.presenter %}
