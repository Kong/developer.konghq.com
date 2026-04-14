{:.danger}
> **Event duplication:** 
> Do **not** use both the Metering & Billing plugin and the {{site.konnect_short_name}} built-in event ingestion in {{site.konnect_short_name}} at the same time.
> This can result in duplicate events.

The following table can help you determine which to use based on your use case:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use-case
  - title: "{{site.konnect_short_name}} built-in"
    key: builtin
  - title: Metering & Billing plugin
    key: plugin
rows:
  - use-case: How do you want to set up event ingestion?
    builtin: Enabled with one click in the {{site.konnect_short_name}} UI.
    plugin: Manual plugin configuration.
  - use-case: Who do you want to bill?
    builtin: Consumer or application.
    plugin: Consumer, Consumer Group, application, or any request header (for example, `x-customer-id` or `x-tenant-id`).
  - use-case: Do you want to bill based on custom dimensions, like department or priority tier?
    builtin: Not available.
    plugin: Yes. Attach any request header or query parameter as a dimension on the event (for example, department, project, priority tier).
  - use-case: How do you want to filter traffic for events?
    builtin: At the Gateway control plane-level only (all Routes and Services in a control plane).
    plugin: Filter by Route, Service, or header.
  - use-case: "Are you running a self-managed {{site.base_gateway}}?"
    builtin: Not available.
    plugin: You must use the plugin, the built-in service isn't available.
{% endtable %}
<!--vale on-->