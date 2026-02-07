This example requires an existing {{site.konnect_short_name}} control plane and entities that we'll then connect to our Kubernetes cluster. Let's create these entities with the {{site.konnect_short_name}} API.

Run the following command to create a control plane and save its ID to your environment:
{% konnect_api_request %}
url: /v2/control-planes
status_code: 201
method: POST
body:
    name: gateway-control-plane
capture: CONTROL_PLANE_ID
jq: ".id"
{% endkonnect_api_request %}

Create a Gateway Service:
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/services
status_code: 201
method: POST
body:
    name: demo-service
    protocol: http
    host: httpbin.konghq.com
    path: /anything
capture: SERVICE_ID
jq: ".id"
{% endkonnect_api_request %}

Create a Route:
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/routes
status_code: 201
method: POST
body:
    name: demo-route
    paths:
        - /anything
    service:
        id: $SERVICE_ID
capture: ROUTE_ID
jq: ".id"
{% endkonnect_api_request %}

Create a Rate Limiting plugin:
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins
status_code: 201
method: POST
body:
    name: rate-limiting
    config:
        second: 5
        hour: 1000
        policy: local
capture: PLUGIN_ID
jq: ".id"
{% endkonnect_api_request %}