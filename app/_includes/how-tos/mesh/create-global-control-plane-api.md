Before you can add services or apply configurations, you must create a global control plane.

1. Create the control plane by sending a request to the Mesh control planes API:

{% capture request %}
{% konnect_api_request %}
url: /v1/mesh/control-planes
status_code: 201
method: POST
body:
  name: example-cp
{% endkonnect_api_request %}
{% endcapture %}

{{request | indent}}

1. Export the control plane `id` so you can reference it when you create a zone:

   ```sh
   export CONTROL_PLANE_ID='YOUR_CONTROL_PLANE_ID'
   ```

The global control plane is now created but has no functionality until you connect a zone.
