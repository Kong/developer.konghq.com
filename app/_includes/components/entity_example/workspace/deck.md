{% if page.collection == 'gateway_entities' %}
  The following creates a new workspace called **{{ include.presenter.data['name'] }}**:
{% endif %}
{% include components/entity_example/format/deck/snippet.md presenter=include.presenter %}
