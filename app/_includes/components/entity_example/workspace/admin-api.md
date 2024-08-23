{% if page.collection == 'gateway_entities' %}
  To create a workspace, call the [Admin API’s /workspaces endpoint](https://docs.konghq.com/gateway/api/admin-ee/latest/#/Workspaces/create-workspace).
  The following creates a new workspace called **{{ include.presenter.data['name'] }}**:
{% endif %}
{% include components/entity_example/format/admin-api/snippet.md presenter=include.presenter %}
