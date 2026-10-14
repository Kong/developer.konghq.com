Stop the MCP server by deleting its control plane mapping, then delete the MCP server and its source:

Delete the control plane mapping:

{% konnect_api_request %}
url: /v1/context-interfaces/$MCP_SERVER_ID/control-plane-mappings/$CP_MAPPING_ID
method: DELETE
status_code: 204
section: cleanup
{% endkonnect_api_request %}

Delete the MCP server:

{% konnect_api_request %}
url: /v1/context-interfaces/$MCP_SERVER_ID
method: DELETE
status_code: 204
section: cleanup
{% endkonnect_api_request %}

Delete the MCP source:

{% konnect_api_request %}
url: /v1/context-sources/$SOURCE_ID
method: DELETE
status_code: 204
section: cleanup
{% endkonnect_api_request %}
