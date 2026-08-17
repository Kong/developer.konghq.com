---
title: Limit A2A request body size
permalink: /ai-gateway/limit-a2a-body-size/
content_type: how_to
description: Attach a Request Size Limiting AI Policy to an AI Agent entity to reject oversized A2A requests

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-agent
  - ai-policy

tags:
  - ai
  - a2a
  - traffic-control

tldr:
  q: How do I limit the request body size for A2A traffic in {{site.ai_gateway}}?
  a: |
    Attach a [Request Size Limiting Policy](/ai-gateway/policies/request-size-limiting/) to an [AI Agent](/ai-gateway/entities/ai-agent/).
    Requests with a body larger than the configured limit are rejected with a 413.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      content: |
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export your key:
           ```bash
           export OPENAI_API_KEY='YOUR_OPENAI_API_KEY'
           ```
      icon_url: /assets/icons/openai.svg
    - title: A2A agent
      include_content: md/ai-gateway/v2/prereqs/a2a-agent
      icon_url: /assets/icons/ai.svg

related_resources:
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: Request Size Limiting Policy reference
    url: /ai-gateway/policies/request-size-limiting/
  - text: Get started with AI Agent
    url: /ai-gateway/get-started-with-ai-agent/
  - text: Secure AI Agent traffic with OpenID Connect and Okta
    url: /ai-gateway/secure-ai-agent-with-oidc/

cleanup:
  inline:
    - title: Stop the A2A agent
      content: |
        ```sh
        docker compose down
        docker rm -f a2a-kongair-agent
        ```
        {: data-test-cleanup="block" }
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: Why limit request body size for A2A traffic?
    a: |
      A2A messages can carry `FilePart` and `DataPart` content alongside text. Without a size limit, a client could send arbitrarily large payloads to the upstream agent, consuming memory and bandwidth. The Request Size Limiting Policy rejects oversized requests before they reach the upstream.
  - q: Does this affect streaming responses?
    a: |
      No. The Request Size Limiting Policy checks the request body size, not the response. Streaming SSE responses from the upstream agent aren't affected.
  - q: Can I scope this Policy to more than one AI Agent?
    a: |
      Yes. Set `global: true` on the Policy to apply it to every resource on your {{site.ai_gateway}} instead of listing it in each Agent's `policies` field.
---

## Create an AI Agent and Request Size Limiting Policy

Create a [Request Size Limiting Policy](/ai-gateway/policies/request-size-limiting/) scoped to this Agent (`global: false`), and an [AI Agent](/ai-gateway/entities/ai-agent/) that attaches it via `policies:`. The 1 MB limit here is intentionally low to make it easy to trigger in this guide.

{% entity_examples %}
ai_gateway_policies:
  - ref: a2a-size-limit
    name: a2a-size-limit
    ai_gateway: !lookup name:ai-quickstart
    type: request-size-limiting
    enabled: true
    global: false
    config:
      allowed_payload_size: 1
      size_unit: megabytes
      require_content_length: false
ai_gateway_agents:
  - ref: kongair-flight-booking-agent
    ai_gateway: !lookup name:ai-quickstart
    display_name: "Kong Air Flight Booking Agent"
    type: a2a
    enabled: true
    policies: [ !ref a2a-size-limit#name ]
    config:
      url: http://host.docker.internal:10000
      route:
        paths:
          - /a2a
        methods:
          - GET
          - POST
        protocols:
          - http
          - https
        strip_path: true
      logging:
        payloads: false
        statistics: true
      max_request_body_size: 8388608
{% endentity_examples %}

`require_content_length: false` means the Policy inspects the actual body size rather than relying on the `Content-Length` header. Set `allowed_payload_size` to a value appropriate for your production workload.

## Validate requests within the size limit

Send a standard A2A request that falls within the 1 MB limit:

{% validation request-check %}
url: /a2a/
method: POST
headers:
  - 'Content-Type: application/json'
body:
  jsonrpc: '2.0'
  id: '1'
  method: message/send
  params:
    message:
      kind: message
      messageId: msg-001
      role: user
      parts:
      - kind: text
        text: Show me routes from SFO to JFK
status_code: 200
{% endvalidation %}


{{site.ai_gateway}} proxies the request to the upstream A2A agent and returns a JSON-RPC response.

## Validate oversized requests are rejected

Generate a payload that exceeds 1 MB.

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
" > ./large_payload.json
```
{:data-test-step="block"}

Now send it as an A2A request:

{% validation request-check %}
url: /a2a
display_headers: true
method: POST
headers:
  - 'Content-Type: application/json'
body_file: '@large_payload.json'
status_code: 413
{% endvalidation %}

{{site.ai_gateway}} rejects the request with `413 Request Entity Too Large`:

```
HTTP/2 413
...
{
  "message": "Request size limit exceeded"
}
```
{:.no-copy-code}
