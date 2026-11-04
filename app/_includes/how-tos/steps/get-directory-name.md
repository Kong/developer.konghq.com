
<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 200
method: GET
extract_body:
  - name: 'data.0.name'
    variable: DECK_DIRECTORY_NAME
capture:
  - variable: DECK_DIRECTORY_NAME
    jq: ".data[0].name"
{% endkonnect_api_request %}
<!--vale on-->

Export the directory name so decK can read it during sync:

```bash
export DECK_DIRECTORY_NAME
```
