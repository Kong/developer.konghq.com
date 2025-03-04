{% if include.render_context %}
{% case include.presenter.entity_type %}
{% when 'consumer' %}
  To create a Consumer, call the [Admin API’s /consumers endpoint](/api/gateway/admin-ee/#/operations/create-consumer).
{% when 'consumer_group' %}
  To create a Consumer Group, call the [Admin API’s /consumer_groups endpoint](/api/gateway/admin-ee/#/operations/post-consumer_groups).
{% when 'route' %}
  To create a Route, call the [Admin API’s /routes endpoint](/api/gateway/admin-ee/#/operations/create-route).
{% when 'service' %}
  To create a Gateway Service, call the [Admin API’s /services endpoint](/api/gateway/admin-ee/#/operations/create-service).
{% when 'target' %}
  To create a Target, call the [Admin API’s /targets endpoint](/api/gateway/admin-ee/#/operations/create-target-with-upstream).
{% when 'upstream' %}
  To create a Upstream, call the [Admin API’s /upstreams endpoint](/api/gateway/admin-ee/#/operations/create-upstream).
{% when 'workspace' %}
  To create a Workspace, call the [Admin API’s /workspaces endpoint](/api/gateway/admin-ee/#/operations/create-workspace).
{% when 'event_hook' %}
  To create an Event Hook, call the [Admin API’s /event-hooks endpoint](/api/gateway/admin-ee/#/operations/post-event-hooks).
{% when 'plugin' %}
  Make the following request:
{% else %}
{% endcase %}
{% endif %}

<div data-deployment-topology="on-prem"  markdown="1" data-test-step="{{ include.presenter.data_validate_on_prem | escape }}">
{% include components/entity_example/format/snippets/admin-api.md presenter=include.presenter %}
</div>

{% if include.render_context %}
{% include components/entity_example/replace_variables.md missing_variables=include.presenter.missing_variables %}
{% endif %}
