---
title: Secure A2A endpoints with OpenID Connect and Okta
permalink: /how-to/secure-a2a-endpoints-with-oidc/
content_type: how_to
description: Add OpenID Connect authentication to A2A routes proxied through {{site.ai_gateway}} using Okta

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
  - openid-connect

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - a2a
  - authentication
  - openid-connect
  - okta

tldr:
  q: How do I secure A2A endpoints with OpenID Connect?
  a: |
    Enable the OpenID Connect plugin on the same Route as the AI A2A Proxy plugin.
    Configure it with your Okta issuer URL and client credentials. Requests without
    a valid bearer token are rejected with 401. Authenticated requests are proxied
    to the upstream A2A agent.

tools:
  - deck

related_resources:
  - text: AI A2A Proxy plugin reference
    url: /plugins/ai-a2a-proxy/
  - text: OpenID Connect plugin reference
    url: /plugins/openid-connect/
  - text: "Proxy A2A agents through {{site.ai_gateway}}"
    url: /how-to/proxy-a2a-agents/
  - text: Secure A2A endpoints with key authentication
    url: /how-to/secure-a2a-endpoints/

prereqs:
  entities:
    services:
      - a2a-currency-agent
    routes:
      - a2a-route
  inline:
    - title: OpenAI API key
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: A2A agent
      include_content: prereqs/a2a-agent
      icon_url: /assets/icons/ai.svg
    - title: Okta
      include_content: prereqs/auth/oidc/okta-client-credentials
      icon_url: /assets/icons/okta.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: Does OpenID Connect interfere with the AI A2A Proxy plugin?
    a: |
      No. The [AI A2A Proxy plugin](/plugins/ai-a2a-proxy/) handles A2A protocol detection, metadata extraction, and observability. The [OpenID Connect plugin](/plugins/openid-connect/) runs independently in the access phase. Both plugins can be applied to the same Route without conflict.
  - q: Can I use a different identity provider instead of Okta?
    a: |
      Yes. The [OpenID Connect plugin](/plugins/openid-connect/) works with any OIDC-compliant identity provider (Keycloak, Auth0, Azure AD, etc.). Replace the `issuer`, `client_id`, and `client_secret` with values from your provider.

automated_tests: false
---

## Enable the AI A2A Proxy plugin

The [AI A2A Proxy plugin](/plugins/ai-a2a-proxy/) parses A2A JSON-RPC requests and proxies them to the upstream agent.

{% entity_examples %}
entities:
  plugins:
    - name: ai-a2a-proxy
      config:
        logging:
          log_statistics: true
          log_payloads: true
{% endentity_examples %}

## Enable the OpenID Connect plugin

Configure the [OpenID Connect plugin](/plugins/openid-connect/) on the A2A Route. The plugin validates bearer tokens issued by Okta using JWKS auto-discovery from the issuer URL.

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      route: a2a-route
      config:
        issuer: ${okta_issuer}
        client_id:
          - ${okta_client_id}
        client_secret:
          - ${okta_client_secret}
        auth_methods:
          - bearer
variables:
  okta_issuer:
    value: $OKTA_ISSUER
  okta_client_id:
    value: $OKTA_CLIENT_ID
  okta_client_secret:
    value: $OKTA_CLIENT_SECRET
{% endentity_examples %}

All requests to the A2A Route now require a valid bearer token from Okta.

## Validate unauthenticated requests are rejected

Send an A2A request without a token:

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
          text: "How much is 100 USD in EUR?"
message: 401 Unauthorized
{% endvalidation %}
<!-- vale on -->

## Validate authenticated requests succeed

Obtain a token from Okta using client credentials:

```sh
export TOKEN=$(curl -s -X POST \
  $DECK_OKTA_ISSUER/v1/token \
  -d "grant_type=client_credentials" \
  -d "client_id=$DECK_OKTA_CLIENT_ID" \
  -d "client_secret=$DECK_OKTA_CLIENT_SECRET" \
  -d "scope=api:access" | jq -r '.access_token')
```

Send the A2A request with the token:

<!-- vale off -->
{% validation request-check %}
url: /a2a
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $TOKEN'
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
          text: "How much is 100 USD in EUR?"
{% endvalidation %}
<!-- vale on -->

{{site.base_gateway}} validates the bearer token via Okta's JWKS endpoint, then proxies the request to the upstream A2A agent. A successful response contains a completed task with the currency conversion result.
