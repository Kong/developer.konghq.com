You can pre-create developer accounts to provision their team association and API access before they access the {{site.dev_portal}}.

1. To automatically create developers and send them an email to create a password, send a `POST` request to the [`/portals/{portalId}/developers` endpoint](/api/konnect/portal-management/v3/#/operations/create-developer):
{% capture create-dev %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/developers
method: POST
status_code: 201
body:
  full_name: "Raina Sovani"
  email: "raina.sovani@example.com"
  status: "approved"
  send_invitation_email: true
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{create-dev | indent: 3}}

1. Copy and export the developer ID:
  ```sh
  export DEVELOPER_ID='YOUR DEVELOPER ID'
  ```

1. Add the developer to an existing team that has the correct roles for the APIs they need access to by sending a `POST` request to the [`/portals/{portalId}/teams/{teamId}/developers` endpoint](/api/konnect/portal-management/v3/#/operations/add-developer-to-portal-team):
{% capture add-dev-to-team %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/teams/$TEAM_ID/developers
method: POST
status_code: 201
body:
  id: "$DEVELOPER_ID"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{add-dev-to-team | indent: 3}} 

{:.warning}
> **Logging in to {{site.dev_portal}}s:**
> * **SSO:** If a developer is created in a {{site.dev_portal}} with SSO configured, they must be able to use SSO to log in if their email address is configured in the identity provider. 
>  After they log in, they will automatically be approved.
> * **Basic auth:** If a developer is created in a {{site.dev_portal}} with basic auth configured, they must be able to set their password. This can be done one of two ways:
>   * `send_invitation_email: true`: Developers can use the link in the email to set their password.
>   * Developers can click **Forgot password** in the {{site.dev_portal}} UI to set a password, regardless of whether `send_invitation_email` is `true` or `false`.
