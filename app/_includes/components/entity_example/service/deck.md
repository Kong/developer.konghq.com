{% if page.collection == 'gateway_entities' %}
  The following creates a new service called **{{ include.presenter.data['name'] }}** with basic configuration:
{% endif %}
{% include components/entity_example/format/deck/snippet.md presenter=include.presenter %}
