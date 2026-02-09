{% case include.presenter.entity_type %}
{% when 'consumer' %}
To create a Consumer, call the Konnect [control plane config API’s `/consumers` endpoint](/api/konnect/control-planes-config/#/operations/create-consumer). 
{% when 'consumer_group' %}
To create a Consumer Group, call the Konnect [control plane config API’s `/consumer_groups` endpoint](/api/konnect/control-planes-config/#/operations/create-consumer_group).
{% when 'route' %}
To create a Route, call the Konnect [control plane config API's `/routes` endpoint](/api/konnect/control-planes-config/#/operations/create-route).
{% when 'service' %}
To create a Gateway Service, call the Konnect [control plane config API’s `/services` endpoint](/api/konnect/control-planes-config/#/operations/create-service).
{% when 'target' %}
To create a Target, call the Konnect [control plane config API’s `/targets` endpoint](/api/konnect/control-planes-config/#/operations/create-target-with-upstream). 
{% when 'upstream' %}
To create an Upstream, call the Konnect [control plane config API’s `/upstreams` endpoint](/api/konnect/control-planes-config/#/operations/create-upstream). 
{% when 'sni' %}
To create an SNI, call the Konnect [control plane config API’s `/snis` endpoint](/api/konnect/control-planes-config/#/operations/create-sni). 
{% when 'ca_certificate' %}
To create a CA Certificate, call the Konnect [control plane config API’s `/ca-certificates` endpoint](/api/konnect/control-planes-config/#/operations/create-ca_certificate). 
{% when 'certificate' %}
To create a Certificate, call the Konnect [control plane config API’s `/certificates` endpoint](/api/konnect/control-planes-config/#/operations/create-certificate). 
{% when 'vault' %}
To create a Vault entity, call the Konnect [control plane config API’s `/vaults` endpoint](/api/konnect/control-planes-config/#/operations/create-vault). 
{% when 'key' %}
To create a Key, call the Konnect [control plane config API’s `/keys` endpoint](/api/konnect/control-planes-config/#/operations/create-key). 
{% when 'key-set' %}
To create a Key Set, call the Konnect [control plane config API’s `/key-sets` endpoint](/api/konnect/control-planes-config/#/operations/create-key-set). 
{% when 'partial' %}
To create a Partial, call the Konnect [control plane config API’s `/partials` endpoint](/api/konnect/control-planes-config/#/operations/create-partial). 
{% when 'plugin' %}
Make the following request:
{% else %}
{% endcase %}

{% include components/entity_example/format/snippets/konnect-api.md presenter=include.presenter %}

{% if include.render_context %}
{% include components/entity_example/replace_variables.md missing_variables=include.presenter.missing_variables %}
{% if include.presenter.product == 'event-gateway' %}
See the [Konnect Event Gateway API reference](/api/konnect/event-gateway/) to learn about region-specific URLs and personal access tokens.
{% else %}
See the [Konnect API reference](/api/konnect/control-planes-config/) to learn about region-specific URLs and personal access tokens.
{% endif %}
{% endif %}
