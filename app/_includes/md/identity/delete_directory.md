<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID?force=true
status_code: 204
method: DELETE
headers:
  - 'Content-Type: application/json'
section: cleanup
{% endkonnect_api_request %}
<!--vale on-->
