{% assign insecure = include.insecure %}

Use the following command to create a [backend cluster](/event-gateway/entities/backend-cluster/) that connects to the Kafka servers you set up:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: backend_cluster
  bootstrap_servers:
    - kafka1:9092
    - kafka2:9092
    - kafka3:9092
  authentication:
    type: anonymous
  tls:
    enabled: false

  {% if insecure == true %}
  insecure_allow_anonymous_virtual_cluster_auth: true
  {% endif %}
  
extract_body:
  - name: id
    variable: BACKEND_CLUSTER_ID
capture: BACKEND_CLUSTER_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->