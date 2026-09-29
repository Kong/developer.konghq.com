To use the copy, paste, and run the instructions in this how-to, you need the ID of your control plane.

Look it up using `DECK_KONNECT_CONTROL_PLANE_NAME`, exported in a previous prerequisite, or substitute the name of your own control plane:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bname%5D%5Beq%5D=$DECK_KONNECT_CONTROL_PLANE_NAME
status_code: 200
method: GET
capture:
  - variable: CONTROL_PLANE_ID
    jq: ".data[0].id"
{% endkonnect_api_request %}
<!--vale on-->

