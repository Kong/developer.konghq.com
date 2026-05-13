{% if include.section == "question" %}
How long are metering events retained in {{site.konnect_short_name}}?
{% elsif include.section == "answer" %}
By default, metering events are retained for two years. You cannot configure this.

If you need an extended event retention period, contact [Kong Support](https://support.konghq.com) or reach out to your sales representative.
{% endif %}
