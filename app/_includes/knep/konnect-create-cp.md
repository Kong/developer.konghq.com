Use the {{site.event_gateway}} API to create a new Event Gateway control plane:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways
status_code: 201
method: POST
body:
    name: {% if include.name %}{{ include.name }}{% else %}My Event Gateway{% endif %}
{% endkonnect_api_request %}
<!--vale on-->

Export the Event Gateway ID to your environment:

```sh
export KONNECT_GATEWAY_CLUSTER_ID="YOUR-EVENT-GATEWAY-ID"
```