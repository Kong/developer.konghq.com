The zone uses a system account access token with the `Connector` role on this control plane.

1. Create a system account and save its `id` as `{{ include.var_prefix }}ACCOUNT_ID`:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/system-accounts
   region: global
   status_code: 201
   method: POST
   headers:
     - 'Content-Type: application/json'
   body:
     name: mesh-{{ include.zone | default: 'zone-1' }}
     description: Connect {{ include.zone | default: 'zone-1' }}
     konnect_managed: false
   extract_body:
     - name: id
       variable: {{ include.var_prefix }}ACCOUNT_ID
   capture:
     - variable: {{ include.var_prefix }}ACCOUNT_ID
       jq: ".id"
   indent: 3
   {% endkonnect_api_request %}
   <!--vale on-->

1. Assign the account the `Connector` role on the control plane:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/system-accounts/${{ include.var_prefix }}ACCOUNT_ID/assigned-roles
   region: global
   status_code: 201
   method: POST
   headers:
     - 'Content-Type: application/json'
   body:
     role_name: Connector
     entity_type_name: Mesh Control Planes
     entity_id: $CONTROL_PLANE_ID
     entity_region: $KONNECT_REGION
   indent: 3
   {% endkonnect_api_request %}
   <!--vale on-->

1. Set the token to expire in 30 days. Change the number of days if your organization's token policy requires a shorter lifetime:

   ```sh
   export TOKEN_EXPIRES_AT=$(jq -nr 'now + 30*24*60*60 | todate')
   ```

1. Create the token and save the returned `token` as `{{ include.var_prefix }}CONTROL_PLANE_TOKEN`:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/system-accounts/${{ include.var_prefix }}ACCOUNT_ID/access-tokens
   region: global
   status_code: 201
   method: POST
   headers:
     - 'Content-Type: application/json'
   body:
     name: {{ include.zone | default: 'zone-1' }}
     expires_at: $TOKEN_EXPIRES_AT
   extract_body:
     - name: token
       variable: {{ include.var_prefix }}CONTROL_PLANE_TOKEN
   capture:
     - variable: {{ include.var_prefix }}CONTROL_PLANE_TOKEN
       jq: ".token"
   indent: 3
   {% endkonnect_api_request %}
   <!--vale on-->
