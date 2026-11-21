Revoke the key of the `developer` AI Consumer. First, get the ID of the key:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CONSUMER_ID/credentials
status_code: 200
method: GET
capture:
  - variable: CREDENTIAL_ID
    command: "jq -er '.data[] | select(.name == \"developer-key\") | .id'"
section: cleanup
{% endkonnect_api_request %}
<!--vale on-->

If `CREDENTIAL_ID` is empty after this command, the key is already deleted, so skip the next request.

Then delete the key:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CONSUMER_ID/credentials/$CREDENTIAL_ID
status_code: 204
method: DELETE
section: cleanup
{% endkonnect_api_request %}
<!--vale on-->
