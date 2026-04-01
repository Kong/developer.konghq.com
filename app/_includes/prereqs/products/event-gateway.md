{% assign summary='{{site.event_gateway}} running' %}
{% capture details_content %}

Run the [quickstart script](https://get.konghq.com/event-gateway) to automatically provision a demo {{site.base_gateway}} control plane and data plane, and configure your environment:

```bash
curl -Ls https://get.konghq.com/event-gateway | bash -s -- -k $KONNECT_TOKEN -N kafka_event_gateway
```

This sets up an {{site.base_gateway}} control plane named `event-gateway-quickstart`, provisions a local data plane, and prints out the following environment variable export:

```bash
export EVENT_GATEWAY_ID=your-gateway-id
```
{:.no-copy-code}

Copy and paste the command with your Event Gateway ID into your terminal to configure your session.

{% include_cached /knep/quickstart-note.md %}

{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}