{% if include.section == "question" %}
Can I collect {{site.konnect_short_name}} audit logs without configuring a webhook?
{% elsif include.section == "answer" %}
Yes. You can use an audit log pull to retrieve organization audit logs on demand, by sending a `GET` request to the `/audit-logs` endpoint instead of configuring a webhook. This is useful if you don't want to expose an inbound endpoint, or you just need to fetch a range of past logs.

The following example shows how you can pull audit logs:

<!--vale off-->
{% konnect_api_request %}
url: /v3/audit-logs
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{{site.konnect_short_name}} only retains audit logs for seven days, so you can only pull logs from that window. For filtering and pagination parameters and the full response format, see [Audit log pull](/konnect-platform/audit-logs/#audit-log-pull-using-the-konnect-api).
{% endif %}
