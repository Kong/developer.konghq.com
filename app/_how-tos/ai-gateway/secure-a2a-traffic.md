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
      - a2a-kongair-agent
    routes:
      - a2a-kongair-route
  inline:
  - title: OpenAI API key
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
  - title: A2A agent
    include_content: prereqs/a2a-kongair-agent
    icon_url: /assets/icons/ai.svg

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
      No. The AI A2A Proxy plugin handles A2A protocol detection, metadata extraction, and observability. Authentication plugins run independently in the access phase. The A2A proxy plugin cannot be scoped to individual consumers or consumer groups, but authentication plugins on the same route still identify callers and enforce
      access control.
  - q: Can I use other authentication methods instead of Key Auth?
    a: |
      Yes. Any {{site.ai_gateway}} authentication plugin works with A2A routes: [JWT](/plugins/jwt/), [OpenID Connect](/plugins/openid-connect/), [OAuth2](/plugins/oauth2/), and others. The AI A2A Proxy plugin operates independently of the authentication method.

automated_tests: false
---

## Enable the AI A2A Proxy plugin

The AI A2A Proxy plugin parses A2A JSON-RPC requests and proxies them to the upstream agent.

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

The [Key Auth plugin](/plugins/key-auth/) rejects requests that don't carry a valid API key.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
{% endentity_examples %}

All requests to the A2A route now require a valid `apikey` header (or query parameter, depending on your Key Auth configuration).

## Create a Consumer and API key

Create a [Consumer](/gateway/entities/consumer/) to represent an A2A client, then issue an API key.

{% entity_examples %}
entities:
  consumers:
    - username: a2a-client-1
      keyauth_credentials:
        - key: a2a-secret-key-1
{% endentity_examples %}

## Validate unauthenticated requests are rejected

Send a request without an API key to confirm that the {{site.ai_gateway}} rejects it:

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
          text: "What flights are available on route KA-123?"
message: "401 Unauthorized: No API key found in request"
{% endvalidation %}
<!-- vale on -->
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
          text: "What flights are available on route KA-123?"
{% endvalidation %}
<!-- vale on -->

The gateway proxies the request to the upstream A2A agent and returns a JSON-RPC response with a completed task or an `input-required` state.