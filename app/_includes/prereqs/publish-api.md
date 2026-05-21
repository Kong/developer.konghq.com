
1. [Create an API](/api/konnect/api-builder/v3/#/operations/create-api) using the `/v3/apis` endpoint:
<!--vale off-->
{% capture create-api %}
{% konnect_api_request %}
url: /v3/apis
status_code: 201
method: POST
body:
    name: MyAPI
    attributes: {"env":["development"],"domains":["web","mobile"]}
{% endkonnect_api_request %}
<!--vale on-->
Export the ID of your API from the response:
```sh
export API_ID='YOUR-API-ID'
```
{% endcapture %}
{{ create-api | indent: 3 }}
1. First, send a request to the `/v2/control-planes` endpoint to [get the ID of the `quickstart` Control Plane](/api/konnect/control-planes/v2/#/operations/list-control-planes):
<!--vale off-->
{% capture list-cp %}
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bname%5D%5Bcontains%5D=quickstart
status_code: 201
method: GET
{% endkonnect_api_request %}
<!--vale on-->
Export your Control Plane ID:
```sh
export CONTROL_PLANE_ID='YOUR-CONTROL-PLANE-ID'
```
{% endcapture %}
{{ list-cp | indent: 3 }}
1. Next, [list Services](/api/konnect/control-planes-config/v2/#/operations/list-service) by using the `/v2/control-planes/{controlPlaneId}/core-entities/services` endpoint:
<!--vale off-->
{% capture list-services %}
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/services
status_code: 201
method: GET
{% endkonnect_api_request %}
<!--vale on-->
Export the ID of the `example-service`:
```sh
export SERVICE_ID='YOUR-GATEWAY-SERVICE-ID'
```
{% endcapture %}
{{ list-services | indent: 3 }}
1. [Associate the API with a Service](/api/konnect/api-builder/v3/#/operations/create-api-implementation) using the `/v3/apis/{apiId}/implementations` endpoint:
<!--vale off-->
{% capture associate-service %}
{% konnect_api_request %}
url: /v3/apis/$API_ID/implementations
status_code: 201
method: POST
body:
    service:
        control_plane_id: $CONTROL_PLANE_ID
        id: $SERVICE_ID
{% endkonnect_api_request %}
{% endcapture %}
{{ associate-service | indent: 3 }}
<!--vale on-->
1. Now you can [publish the API](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal) to your Dev Portal using the `/v3/apis/{apiId}/publications/{portalId}` endpoint:
<!--vale off-->
{% capture publish %}
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
{% endkonnect_api_request %}
{% endcapture %}
{{ publish | indent: 3 }}
<!--vale on-->