{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID?force=true
status_code: 204
method: DELETE
headers:
  - 'Content-Type: application/json'
section: cleanup
{% endkonnect_api_request %}