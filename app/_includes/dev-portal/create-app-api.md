You can automate applications and application registrations on behalf of a developer or team using the {{site.konnect_short_name}} API.

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
   
   If the application is for a team, configure `type: team`.

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
   > If the application will be using a DCR provider with the given auth strategy, your configuration depends on your use case:
   > * You want to create a new DCR application, where the IdP client will be created in the identity provider and assigned a `client_id`. This will be set as the `client_id` of the application and can't be changed moving forward. **Do not** specify `dcr_client_id` or `client_id` in this case. `client_id` will be present in the response.
   > * You want to create an application that is linked to an existing IdP client, but treated as if it was created via the DCR app creation process. This allows you to import existing IdP clients when onboarding your applications into {{site.konnect_short_name}}. In this case, you must specify `dcr_client_id` and `client_id` will be present in the response.
