{% if page.collection == 'gateway_entities' %}
{% case include.presenter.entity_type %}
{% when 'consumer' %}
  To create a consumer, call the [Admin API’s /consumers endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Consumers/create-consumer).
  The following creates a new consumer called **{{ include.presenter.data['username'] }}**:
{% when 'consumer_group' %}
  To create a consumer group, call the [Admin API’s /consumer_groups endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/consumer_groups/post-consumer_groups).
{% when 'route' %}
  To create a route, call the [Admin API’s /routes endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Routes/create-route).
{% when 'service' %}
  To create a service, call the [Admin API’s /services endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Services/create-service).
{% when 'target' %}
  To create a target, call the [Admin API’s /targets endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Targets).
{% when 'upstream' %}
  To create a upstream, call the [Admin API’s /upstreams endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Upstreams/create-upstream).
  The following creates a new upstream called **{{ include.presenter.data['name'] }}**:
{% when workspace %}
  To create a workspace, call the [Admin API’s /workspaces endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Workspaces/create-workspace).
  The following creates a new workspace called **{{ include.presenter.data['name'] }}**:
{% else %}
{% endcase %}
{% endif %}
{% include components/entity_example/format/snippets/admin-api.md presenter=include.presenter %}
