{% assign summary='{{site.event_gateway}} running' %}
{% capture details_content %}
{% event_gateway_quickstart %}
section: prereq
{% endevent_gateway_quickstart %}
{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}