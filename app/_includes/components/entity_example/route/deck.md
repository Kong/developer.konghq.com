{% if page.collection == 'gateway_entities' %}
  The following creates a new route called **{{ include.presenter.data['name'] }}** with basic configuration:
{% endif %}
{% include components/entity_example/format/deck/snippet.md presenter=include.presenter %}
