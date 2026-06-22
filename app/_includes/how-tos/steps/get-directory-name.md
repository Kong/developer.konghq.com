
<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 200
method: GET
capture:
  - variable: DECK_DIRECTORY_NAME
    jq: ".data[0].name"
{% endkonnect_api_request %}
<!--vale on-->
