{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID
status_code: 204
method: DELETE
headers:
  - 'Content-Type: application/json'
section: cleanup
{% endkonnect_api_request %}