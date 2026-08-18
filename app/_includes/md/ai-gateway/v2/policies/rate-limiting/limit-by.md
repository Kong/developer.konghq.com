Use [`config.limit_by`](./reference/#schema--config-limit-by) to choose what the Policy aggregates counters against:

{% table %}
columns:
  - title: Value
    key: value
  - title: Description
    key: description
rows:
  - value: "`consumer`"
    description: "The authenticated [AI Consumer](/ai-gateway/entities/ai-consumer/). This is the default."
  - value: "`consumer-group`"
    description: "The [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) the AI Consumer belongs to."
  - value: "`credential`"
    description: The credential the AI Consumer authenticated with. Use this to limit each API key separately when one AI Consumer holds several.
  - value: "`ip`"
    description: "The client IP address. See [Limit by IP address](#limit-by-ip-address)."
  - value: "`header`"
    description: "The value of the header named in [`config.header_name`](./reference/#schema--config-header-name)."
  - value: "`path`"
    description: "The request path set in [`config.path`](./reference/#schema--config-path)."
{% endtable %}

If the AI Model, AI Agent, or AI MCP Server handling the request has no authentication layer, the client IP address is used to identify clients. Otherwise, the AI Consumer is used once an [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/) has authenticated the request.

### Limit by IP address

If limiting by IP address, it's important to understand how {{site.ai_gateway}} determines the IP address of an incoming request.

The IP address is extracted from the request headers sent to {{site.ai_gateway}} by downstream clients. Typically, these headers are named `X-Real-IP` or `X-Forwarded-For`.

By default, {{site.ai_gateway}} uses the header name `X-Real-IP` to identify the client's IP address. If your environment requires a different header, you can specify this by setting the [`real_ip_header`](/ai-gateway/configuration/#real-ip-header) Nginx property. Depending on your network setup, you may also need to configure the [`trusted_ips`](/ai-gateway/configuration/#trusted-ips) Nginx property to include the load balancer IP address. This ensures that {{site.ai_gateway}} correctly interprets the client's IP address, even when the request passes through multiple network layers.
