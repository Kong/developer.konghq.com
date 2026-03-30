For {{site.konnect_short_name}}, you can either use the [built-in {{site.metering_and_billing}}](/metering-and-billing/) event ingestion that uses events from Advanced Analytics or use the [Metering & Billing plugin](/plugins/metering-and-billing/).

{:.danger}
> **Event duplication:** 
> Do **not** use both the Metering & Billing plugin and the {{site.konnect_short_name}} built-in event ingestion in {{site.konnect_short_name}}. 
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
    builtin: Enabled with one click in the {{site.konnect_short_name}} UI
    plugin: Manual plugin configuration
  - use-case: Who do you want to bill?
    builtin: Consumer or application
    plugin: Consumer, Consumer Group, application, or any request header (for example, `x-customer-id` or `x-tenant-id`)
  - use-case: Do you want to bill based on custom dimensions, like department or priority tier?
    builtin: No
    plugin: Yes. Attach any request header or query parameter as a dimension on the event (for example, department, project, priority tier).
  - use-case: How do you want to filter traffic for events?
    builtin: At the Gateway control plane-level only (all Routes and Services in a control plane)
    plugin: Filter by Route, Service, or header
{% endtable %}
<!--vale on-->