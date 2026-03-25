---
title: "Limit A2A request body size"
content_type: how_to
description: "Restrict the maximum request body size for A2A routes proxied through {{site.ai_gateway}}"

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-a2a-proxy
  - request-size-limiting

entities:
  - service
  - route
  - plugin

permalink: /how-to/limit-a2a-request-size/

tags:
  - ai
  - a2a
  - traffic-control

tldr:
  q: "How do I limit the request body size for A2A traffic in {{site.ai_gateway}}?"
  a: "Enable the Request Size Limiting plugin on the same service or route as the AI A2A Proxy plugin. Requests that exceed the configured body size are rejected with 413."
tools:
  - deck

related_resources:
  - text: AI A2A Proxy plugin reference
    url: /plugins/ai-a2a-proxy/
  - text: Request Size Limiting plugin reference
    url: /plugins/request-size-limiting/
  - text: "Proxy A2A agents through {{site.ai_gateway}}"
    url: /how-to/proxy-a2a-agents/
  - text: Rate limit A2A traffic
    url: /how-to/rate-limit-a2a-traffic/

prereqs:
  entities:
    services:
      - a2a-currency-agent
    routes:
      - a2a-route
  inline:
    - title: AI A2A Proxy plugin
      icon_url: /assets/icons/ai.svg
      content: |
        This guide builds on the [Proxy A2A agents through {{site.ai_gateway}}](/how-to/proxy-a2a-agents/)
        how-to. Complete that guide first to set up the A2A service, route, and AI A2A Proxy plugin.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: Why limit request body size for A2A traffic?
    a: |
      A2A messages can carry `FilePart` and `DataPart` content alongside text. Without a size limit, a client could send arbitrarily large payloads to the upstream agent, consuming memory and bandwidth. The Request Size Limiting plugin rejects oversized requests before
      they reach the upstream.
  - q: |
      How does this interact with the AI A2A Proxy plugin's `max_request_body_size` setting?
    a: |
      The two settings serve different purposes. `config.max_request_body_size` on the AI A2A Proxy plugin controls how much of the request body the plugin reads for JSON-RPC detection.
      The Request Size Limiting plugin rejects the entire request if the body exceeds the configured limit. Set both if you want to cap detection parsing and reject oversized
      requests.
  - q: Does this affect streaming responses?
    a: |
      No. The Request Size Limiting plugin checks the request body size, not the response.
      Streaming SSE responses from the upstream agent are not affected.
---

## Enable the AI A2A Proxy plugin

The AI A2A Proxy plugin parses A2A JSON-RPC requests and proxies them to the upstream agent.
With logging enabled, the plugin records A2A metrics and payloads as OpenTelemetry span
attributes.

{% entity_examples %}
entities:
  plugins:
    - name: ai-a2a-proxy
      config:
        max_request_body_size: 0
        logging:
          log_statistics: true
          log_payloads: true
{% endentity_examples %}

## Enable the Request Size Limiting plugin

The Request Size Limiting plugin rejects requests with a body larger than the configured limit. This configuration sets a 1 MB limit, which is intentionally low for testing with `FilePart` or `DataPart` payloads.

{% entity_examples %}
entities:
  plugins:
    - name: request-size-limiting
      config:
        allowed_payload_size: 1
        size_unit: megabytes
        require_content_length: false
{% endentity_examples %}

{:.info}
> `require_content_length` is set to `false` so the plugin inspects the actual body size rather than relying on the `Content-Length` header. Set `allowed_payload_size` to a value appropriate for your production workload.

## Validate requests within the size limit

Send a standard A2A request that falls within the 1 MB limit:

<!-- vale off -->
{% validation request-check %}
url: /a2a
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  jsonrpc: "2.0"
  id: "1"
  method: "message/send"
  params:
    message:
      kind: message
      messageId: msg-001
      role: user
      parts:
        - kind: text
          text: "How much is 1 USD in PLN?"
{% endvalidation %}
<!-- vale on -->

The gateway proxies the request to the upstream A2A agent and returns a JSON-RPC response.

## Validate oversized requests are rejected

Generate a payload that exceeds 1 MB and send it as an A2A request:

```sh
python3 -c "
import json
payload = {
    'jsonrpc': '2.0',
    'id': '2',
    'method': 'message/send',
    'params': {
        'message': {
            'kind': 'message',
            'messageId': 'msg-002',
            'role': 'user',
            'parts': [
                {
                    'kind': 'text',
                    'text': 'A' * 1100000
                }
            ]
        }
    }
}
print(json.dumps(payload))
" > /tmp/large_payload.json

curl -i --no-progress-meter \
  http://localhost:8000/a2a \
  -H "Content-Type: application/json" \
  -d @/tmp/large_payload.json
```

The gateway rejects the request with `413 Request Entity Too Large`:

```
HTTP/2 413
...
{
  "message": "Request size limit exceeded"
}
```
{:.no-copy-code}