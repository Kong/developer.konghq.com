A directory is a regional collection of principals. 
Create a directory for this tutorial:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "kong-identity-directory"
  description: "Directory for this tutorial"
  allow_all_control_planes: true
capture:
  - variable: DIRECTORY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->
