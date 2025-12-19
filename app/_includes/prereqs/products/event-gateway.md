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

{:.info}
> This quickstart script is meant for demo purposes only, therefore it runs locally with default parameters and a small number of exposed ports.
If you want to run {{ site.base_gateway }} as a part of a production-ready platform, set up your control plane and data planes through the [{{site.konnect_short_name}} UI](/event-gateway/?tab=konnect-ui#install-event-gateway), or using [Terraform](/terraform/).

{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}