{% if include.render_context %}
{% case include.presenter.entity_type %}
{% when 'backend_cluster' %}
The following creates a new backend cluster called **{{ include.presenter.data['name'] }}**.
{% when 'virtual_cluster' %}
The following creates a new virtual cluster called **{{ include.presenter.data['name'] }}**.
{% when 'listener' %}
The following creates a new listener called **{{ include.presenter.data['name'] }}** with basic configuration.
{% when 'schema_registry' %}
The following creates a new schema registry called **{{ include.presenter.data['name'] }}**.
{% when 'static_key' %}
The following creates a new static key called **{{ include.presenter.data['name'] }}**.
{% when 'tls_trust_bundle' %}
The following creates a new TLS trust bundle called **{{ include.presenter.data['name'] }}**.
{% when 'event_gateway_policy' %}
The following example creates a new `{{ include.presenter.data['type'] }}` policy.
{% endcase %}
Add this snippet to an `event_gateways` resource in your declarative configuration file, and then [manage it with kongctl](/kongctl/declarative/#declarative-commands):
{% endif %}

{% include components/entity_example/format/snippets/kongctl.md presenter=include.presenter %}

{% if include.render_context %}
{% include components/entity_example/replace_variables.md missing_variables=include.presenter.missing_variables %}
{% endif %}
