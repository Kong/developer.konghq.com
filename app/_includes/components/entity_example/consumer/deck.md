{% if page.collection == 'gateway_entities' %}
  The following creates a new consumer called **{{ include.presenter.data['username'] }}**:
{% endif %}
{% include components/entity_example/format/deck/snippet.md presenter=include.presenter %}
