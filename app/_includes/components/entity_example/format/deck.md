{% if include.render_context %}
{% case include.presenter.entity_type %}
{% when 'consumer' %}
The following creates a new Consumer called **{{ include.presenter.data['username'] }}**:
{% when 'consumer_group' %}
The following creates a new Consumer Group called **{{ include.presenter.data['name'] }}**:
{% when 'route' %}
The following creates a new Route called **{{ include.presenter.data['name'] }}** with basic configuration:
{% when 'service' %}
The following creates a new Gateway Service called **{{ include.presenter.data['name'] }}** with basic configuration:
{% when 'target' %}
The following creates a new Target called **{{ include.presenter.data['name'] }}**:
{% when 'upstream' %}
The following creates a new Upstream called **{{ include.presenter.data['name'] }}**:
{% when workspace %}
The following creates a new Workspace called **{{ include.presenter.data['name'] }}**:
{% when certificate %}
The following creates a new Certificate:
{% when ca_certificate %}
The following creates a new CA Certificate:
{% when 'plugin' %}
Add this section to your [`kong.yaml`](/deck/get-started/) configuration file:
{% else %}
{% endcase %}
{% endif %}

{% include components/entity_example/format/snippets/deck.md presenter=include.presenter %}

{% if include.render_context %}
{% include components/entity_example/replace_variables.md missing_variables=include.presenter.missing_variables %}
{% endif %}
