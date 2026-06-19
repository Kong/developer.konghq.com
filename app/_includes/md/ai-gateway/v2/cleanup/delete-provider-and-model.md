Delete the Model entity first. Replace `$MODEL_ID` with the ID returned when you created the model:

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/models/$MODEL_ID
status_code: 204
method: DELETE
headers:
  - 'Accept: application/problem+json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}

Then delete the Provider entity. Replace `$PROVIDER_ID` with the ID returned when you created the provider:

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers/$PROVIDER_ID
status_code: 204
method: DELETE
headers:
  - 'Accept: application/problem+json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}
