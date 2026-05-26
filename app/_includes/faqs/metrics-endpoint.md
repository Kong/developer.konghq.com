{% if include.section == "question" %}

How can AI agents and chatbots get analytics from {{site.konnect_short_name}}?
{% elsif include.section == "answer" %}

The [{{site.konnect_short_name}} MCP Server](/konnect-platform/konnect-mcp/) and [KAi](/konnect-platform/kai/) can natively access your {{site.konnect_short_name}} metrics.

If you're using a third-party AI provider, like Claude or ChatGPT, you can use the {{site.konnect_short_name}} MCP Server or the [metrics API endpoint](/api/konnect/metrics/). 

{% endif %}