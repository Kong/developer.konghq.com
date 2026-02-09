{% if include.render_context %}
{% case include.presenter.entity_type %}
{% when 'consumer' %}
To create a Consumer, call the [Admin API’s `/consumers` endpoint](/api/gateway/admin-ee/#/operations/create-consumer).
{% when 'consumer_group' %}
To create a Consumer Group, call the [Admin API’s `/consumer_groups` endpoint](/api/gateway/admin-ee/#/operations/create-consumer_group).
{% when 'route' %}
To create a Route, call the [Admin API’s `/routes` endpoint](/api/gateway/admin-ee/#/operations/create-route).
{% when 'service' %}
To create a Gateway Service, call the [Admin API’s `/services` endpoint](/api/gateway/admin-ee/#/operations/create-service).
{% when 'target' %}
To create a Target, call the [Admin API’s `/targets` endpoint](/api/gateway/admin-ee/#/operations/create-target-with-upstream).
{% when 'upstream' %}
To create a Upstream, call the [Admin API’s `/upstreams` endpoint](/api/gateway/admin-ee/#/operations/create-upstream).
{% when 'workspace' %}
To create a Workspace, call the [Admin API’s `/workspaces` endpoint](/api/gateway/admin-ee/#/operations/create-workspace).
{% when 'event_hook' %}
To create an Event Hook, call the [Admin API’s `/event-hooks` endpoint](/api/gateway/admin-ee/#/operations/create-event-hooks).
{% when 'sni' %}
To create an SNI, call the [Admin API’s `/snis` endpoint](/api/gateway/admin-ee/#/operations/create-sni).
{% when 'admin' %}
To create an Admin, call the [Admin API’s `/admins` endpoint](/api/gateway/admin-ee/#/operations/create-admins).
{% when 'group' %}
To create a Group, call the [Admin API’s `/groups` endpoint](/api/gateway/admin-ee/#/operations/post-groups).
{% when 'ca_certificate' %}
To create a CA Certificate, call the [Admin API’s `/ca_certificates` endpoint](/api/gateway/admin-ee/#/operations/create-ca_certificate).
{% when 'certificate' %}
To create a Certificate, call the [Admin API’s `/certificates` endpoint](/api/gateway/admin-ee/#/operations/create-certificate).
{% when 'vault' %}
To create a Vault entity, call the [Admin API’s `/vaults` endpoint](/api/gateway/admin-ee/#/operations/create-vault).
{% when 'partial' %}
To create a Partial, call the [Admin API’s `/partials` endpoint](/api/gateway/admin-ee/#/operations/create-partial).
{% when 'key' %}
To create a Key, call the [Admin API’s `/keys` endpoint](/api/gateway/admin-ee/#/operations/create-key).
{% when 'key-set' %}
To create a Key Set, call the [Admin API’s `/key-sets` endpoint](/api/gateway/admin-ee/#/operations/create-key-set).
{% when 'plugin' %}
Make the following request:
{% else %}
{% endcase %}
{% endif %}
{% if page.output_format == 'markdown' %}
{% include components/entity_example/format/snippets/admin-api.md presenter=include.presenter %}
{% else %}
<div data-deployment-topology="on-prem"  markdown="1" data-test-step="{{ include.presenter.data_validate_on_prem | escape }}">
{% include components/entity_example/format/snippets/admin-api.md presenter=include.presenter %}
</div>
{% endif %}
{% if include.render_context %}
{% include components/entity_example/replace_variables.md missing_variables=include.presenter.missing_variables %}
{% endif %}
