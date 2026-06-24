Create the Principal by sending a POST request to the `/v2/directories/{directoryId}/principals` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
body:
  display_name: "example-principal"
  description: "Example principal"
capture:
  - variable: PRINCIPAL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

This command does the following:

1. Creates a principal named `example-principal`
1. Saves the returned ID as `$PRINCIPAL_ID`
