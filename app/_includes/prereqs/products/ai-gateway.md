{% assign summary='{{site.base_gateway}} running' %}
{% capture details_content %}
Placeholder prereq
```bash
curl -Ls https://get.konghq.com/quickstart/ai | bash -s -- -d
```
{% endcapture %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/ai-gateway.svg' %}
