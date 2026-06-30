{% case include.presenter.entity_type %}
{% when 'consumer' %}
To create a Consumer, call the Konnect [control plane config API's `/consumers` endpoint](/api/konnect/control-planes-config/#/operations/create-consumer). 
{% when 'consumer_group' %}
To create a Consumer Group, call the Konnect [control plane config API's `/consumer_groups` endpoint](/api/konnect/control-planes-config/#/operations/create-consumer_group).
{% when 'route' %}
To create a Route, call the Konnect [control plane config API's `/routes` endpoint](/api/konnect/control-planes-config/#/operations/create-route).
{% when 'service' %}
To create a Gateway Service, call the Konnect [control plane config API's `/services` endpoint](/api/konnect/control-planes-config/#/operations/create-service).
{% when 'target' %}
To create a Target, call the Konnect [control plane config API's `/targets` endpoint](/api/konnect/control-planes-config/#/operations/create-target-with-upstream). 
{% when 'upstream' %}
To create an Upstream, call the Konnect [control plane config API's `/upstreams` endpoint](/api/konnect/control-planes-config/#/operations/create-upstream). 
{% when 'sni' %}
To create an SNI, call the Konnect [control plane config API's `/snis` endpoint](/api/konnect/control-planes-config/#/operations/create-sni). 
{% when 'ca_certificate' %}
To create a CA Certificate, call the Konnect [control plane config API's `/ca-certificates` endpoint](/api/konnect/control-planes-config/#/operations/create-ca_certificate). 
{% when 'certificate' %}
To create a Certificate, call the Konnect [control plane config API's `/certificates` endpoint](/api/konnect/control-planes-config/#/operations/create-certificate). 
{% when 'vault' %}
To create a Vault entity, call the Konnect [control plane config API's `/vaults` endpoint](/api/konnect/control-planes-config/#/operations/create-vault). 
{% when 'key' %}
To create a Key, call the Konnect [control plane config API's `/keys` endpoint](/api/konnect/control-planes-config/#/operations/create-key). 
{% when 'key-set' %}
To create a Key Set, call the Konnect [control plane config API's `/key-sets` endpoint](/api/konnect/control-planes-config/#/operations/create-key-set). 
{% when 'partial' %}
To create a Partial, call the Konnect [control plane config API's `/partials` endpoint](/api/konnect/control-planes-config/#/operations/create-partial). 
{% when 'plugin' %}
Make the following request:
{% when 'backend_cluster' %}
To create a backend cluster, call the Event Gateway API's [`/backend-clusters`](/api/konnect/event-gateway/#/operations/create-event-gateway-backend-cluster) endpoint.
{% when 'virtual_cluster' %}
To create a virtual cluster, call the Event Gateway API's [`/virtual-clusters`](/api/konnect/event-gateway/#/operations/create-event-gateway-virtual-cluster) endpoint.
{% when 'listener' %}
To create a listener, call the Event Gateway API's [`/listeners`](/api/konnect/event-gateway/#/operations/create-event-gateway-listener) endpoint.
{% when 'schema_registry' %}
To create a schema registry, call the Event Gateway API's [`/schema-registries`](/api/konnect/event-gateway/#/operations/create-event-gateway-schema-registry) endpoint.
{% when 'static_key' %}
To create a static key, call the Event Gateway API's [`/static-keys`](/api/konnect/event-gateway/v1/#/operations/create-event-gateway-static-key) endpoint.
{% when 'tls_trust_bundle' %}
To create a TLS trust bundle, call the Event Gateway API's [`/tls-trust-bundles`](/api/konnect/event-gateway/v1/#/operations/create-event-gateway-tls-trust-bundle) endpoint.
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
