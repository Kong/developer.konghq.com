Run the [quickstart script](https://get.konghq.com/event-gateway) to automatically provision a demo {{site.base_gateway}} control plane and data plane, and configure your environment:

```bash
curl -Ls https://get.konghq.com/event-gateway | bash -s -- -k $KONNECT_TOKEN -N kafka_event_gateway{% if config.env != empty %} \{% endif %}{% for pair in config.env %}
  -e "{{ pair[0] }}={{ pair[1] }}"{% unless forloop.last %} \{% endunless %}{% endfor %}
```

This sets up an {{site.base_gateway}} control plane named `event-gateway-quickstart`, provisions a local data plane, and prints out the following environment variable export:

```bash
export EVENT_GATEWAY_ID=your-gateway-id
```
{:.no-copy-code}

Copy and paste the command with your Event Gateway ID into your terminal to configure your session.

{% include_cached /knep/quickstart-note.md %}
