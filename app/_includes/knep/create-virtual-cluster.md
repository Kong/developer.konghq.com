{% assign cluster = include.name %}
{% assign auth = include.auth %}

Use the following command to create the `{{cluster}}` virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: {{cluster}}_vc
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: {{cluster}}

{% if auth == true %}
  authentication:
    - type: sasl_plain
      mediation: terminate
      principals:
        - username: {{cluster}}_user
          password: {{cluster}}_password
  acl_mode: enforce_on_gateway
{% else %}
  authentication:
    - type: anonymous
  acl_mode: passthrough
{% endif %}

  namespace:
    prefix: {{cluster}}_
    mode: hide_prefix
    additional:
      topics:
        - type: exact_list
          conflict: warn
          exact_list:
            - backend: user_actions
extract_body:
  - name: id
    variable: {{cluster | upcase}}_VC_ID
capture: {{cluster | upcase}}_VC_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

This virtual cluster provides access to topics with the `{{cluster}}_` prefix, and the `user_actions` topic.