---
title: "Secure A2A endpoints with key authentication"
content_type: how_to
description: "Add key authentication to A2A routes proxied through {{site.ai_gateway}} with the AI A2A Proxy plugin"

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
  - key-auth

entities:
  - service
  - route
  - plugin
  - consumer

permalink: /how-to/secure-a2a-endpoints/

tags:
  - ai
  - a2a
  - authentication

tldr:
  q: "How do I add authentication to A2A endpoints in {{site.ai_gateway}}?"
  a: "Enable the Key Auth plugin on the same service or route as the AI A2A Proxy plugin. Create a consumer with an API key. Requests without a valid key are rejected with 401; authenticated requests are proxied to the upstream A2A agent."
tools:
  - deck

related_resources:
  - text: AI A2A Proxy plugin reference
    url: /plugins/ai-a2a-proxy/
  - text: Key Auth plugin reference
    url: /plugins/key-auth/
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
    - title: A2A agent
      icon_url: /assets/icons/ai.svg
      content: |
        You need a running A2A-compliant agent. This guide uses a sample currency conversion agent
        from the [A2A project](https://github.com/a2aproject/a2a-samples).

        Create a `docker-compose.yaml` file with the following content:

        ```yaml
        services:
            a2a-agent:
            container_name: a2a-currency-agent
            build:
                context: .
                dockerfile_inline: |
                FROM python:3.12-slim
                WORKDIR /app
                RUN pip install uv && apt-get update && apt-get install -y git
                RUN git clone --depth 1 https://github.com/a2aproject/a2a-samples.git /tmp/a2a && \
                    cp -r /tmp/a2a/samples/python/agents/langgraph/* . && \
                    rm -rf /tmp/a2a
                ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
                RUN uv sync --frozen --no-dev
                EXPOSE 10000
                CMD ["uv", "run", "app", "--host", "0.0.0.0"]
            environment:
                - model_source=openai
                - API_KEY=${OPENAI_API_KEY}
                - TOOL_LLM_URL=https://api.openai.com/v1
                - TOOL_LLM_NAME=gpt-5.1
            ports:
                - "10000:10000"
            networks:
                - kong-net

        networks:
            kong-net:
            external: true
            name: kong-quickstart-net
        ```

        Export your OpenAI API key and start the agent:

        ```sh
        export OPENAI_API_KEY='your-openai-key'
        docker compose up --build -d
        ```

        The agent listens on port 10000 and uses the A2A JSON-RPC protocol to handle currency conversion queries.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: Does Key Auth interfere with the AI A2A Proxy plugin?
    a: |
      No. The AI A2A Proxy plugin handles A2A protocol detection, metadata extraction,
      and observability. Authentication plugins run independently in the access phase.
      The A2A proxy plugin cannot be scoped to individual consumers or consumer groups,
      but authentication plugins on the same route still identify callers and enforce
      access control.
  - q: Can I use other authentication methods instead of Key Auth?
    a: |
      Yes. Any {{site.ai_gateway}} authentication plugin works with A2A routes:
      [Basic Auth](/plugins/basic-auth/), [JWT](/plugins/jwt/),
      [OpenID Connect](/plugins/openid-connect/), [OAuth2](/plugins/oauth2/), and others. The AI A2A Proxy plugin operates independently of the authentication method.
---

## Enable the AI A2A Proxy plugin

The AI A2A Proxy plugin parses A2A JSON-RPC requests and proxies them to the upstream agent. With logging enabled, the plugin records A2A metrics and payloads as OpenTelemetry span attributes.

{% entity_examples %}
entities:
  plugins:
    - name: ai-a2a-proxy
      config:
        logging:
          log_statistics: true
          log_payloads: true
{% endentity_examples %}

## Enable the Key Auth plugin

The Key Auth plugin rejects requests that don't carry a valid API key.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
{% endentity_examples %}

All requests to the A2A route now require a valid `apikey` header (or query parameter, depending on your Key Auth configuration).

## Create a consumer and API key

Create a consumer to represent an A2A client, then issue an API key.

{% entity_examples %}
entities:
  consumers:
    - username: a2a-client-1
      keyauth_credentials:
        - key: a2a-secret-key-1
{% endentity_examples %}

## Validate unauthenticated requests are rejected

Send a request without an API key to confirm that the gateway rejects it:

<!-- vale off -->
{% validation request-check %}
url: /a2a
status_code: 401
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

The gateway responds with `401 Unauthorized`:

```
HTTP/2 401
...
{
  "message":"No API key found in request"
}
```
{:.no-copy-code}

## Validate authenticated requests succeed

Send the same request with the API key:

<!-- vale off -->
{% validation request-check %}
url: /a2a
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
  - 'apikey: a2a-secret-key-1'
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

The gateway proxies the request to the upstream A2A agent and returns a JSON-RPC response with a completed task or an `input-required` state.