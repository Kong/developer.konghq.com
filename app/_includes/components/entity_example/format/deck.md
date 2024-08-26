{% if page.collection == 'gateway_entities' %}
{% case include.presenter.entity_type %}
{% when 'consumer' %}
  The following creates a new consumer called **{{ include.presenter.data['username'] }}**:
{% when 'consumer_group' %}
  The following creates a new Consumer Group called **{{ include.presenter.data['name'] }}**:
{% when 'route' %}
  The following creates a new route called **{{ include.presenter.data['name'] }}** with basic configuration:
{% when 'service' %}
  The following creates a new service called **{{ include.presenter.data['name'] }}** with basic configuration:
{% when 'target' %}
  To create a target, call the [Admin API’s /targets endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Targets).
{% when 'upstream' %}
  The following creates a new upstream called **{{ include.presenter.data['name'] }}**:
{% when workspace %}
  The following creates a new workspace called **{{ include.presenter.data['name'] }}**:
{% else %}
{% endcase %}
{% endif %}
{% include components/entity_example/format/snippets/deck.md presenter=include.presenter %}
