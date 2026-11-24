Access rules (ACLs) belong to your organization, not to a single directory or control plane.
Delete the access rule that you created in this guide:

<!--vale off-->
{% konnect_api_request %}
url: /v1/policies/acls/$ACL_ID
status_code: 204
method: DELETE
headers:
  - 'Content-Type: application/json'
section: cleanup
{% endkonnect_api_request %}
<!--vale on-->
