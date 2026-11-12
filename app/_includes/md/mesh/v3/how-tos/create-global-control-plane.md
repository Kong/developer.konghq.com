1. Set the region where you will create the global control plane:

   ```sh
   export KONNECT_REGION='us'
   ```

1. Create a {{site.mesh_product_name}} v3 control plane in {{site.konnect_short_name}} and save its ID to your environment:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v1/mesh/control-planes
   region: $KONNECT_REGION
   status_code: 201 
   method: POST
   headers:
     - 'Content-Type: application/json'
   body:
     name: {{ include.name | default: 'example-cp' }}
     version: v3
   extract_body:
     - name: id
       variable: CONTROL_PLANE_ID
   capture:
     - variable: CONTROL_PLANE_ID
       jq: ".id"
   indent: 3
   {% endkonnect_api_request %}
   <!--vale on-->
