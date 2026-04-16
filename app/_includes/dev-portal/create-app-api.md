You can pre-create applications and application registrations on behalf of a developer or team using the {{site.konnect_short_name}} API.

1. Create a developer application by sending a `POST` request to the `/portals/{portalId}/applications` endpoint:
{% capture create-application %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/applications
method: POST
status_code: 201
body:
  name: "KongAir Application"
  description: "A portal application provisioned for a developer by a Portal Admin."
  auth_strategy_id: "$AUTH_STRATEGY_ID"
  owner:
    id: "$DEVELOPER_ID"
    type: "developer"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{create-application | indent: 3}}

1. Copy and export the application ID:
  ```sh
  export APPLICATION_ID='YOUR APPLICATION ID'
  ```

1. Create an application registration by sending a `POST` request to the `/portals/{portalId}/applications/{applicationId}/registrations` endpoint:
{% capture create-application-registration %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/applications/$APPLICATION_ID/registrations
method: POST
status_code: 201
body:
  api_id: "$API_ID"
  status: "approved"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{create-application-registration | indent: 3}}
   
   {:.warning}
   > **DCR applications:**
   > If the application will be using a DCR provider with the given auth strategy, the request must specify `dcr_client_id`.
