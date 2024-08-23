{% if page.collection == 'gateway_entities' %}
  To create a target, call the Konnect [control plane config API’s /targets endpoint](https://docs.konghq.com/konnect/api/control-plane-configuration/latest/#/Targets/create-target-with-upstream). 
{% endif %}
{% include components/entity_example/format/konnect-api/snippet.md presenter=include.presenter %}
