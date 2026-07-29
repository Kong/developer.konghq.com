---
title: Secure AI Agent traffic with OpenID Connect and Okta
permalink: /ai-gateway/secure-ai-agent-with-oidc/
content_type: how_to
description: Attach an OpenID Connect AI Policy to an AI Agent entity to require Okta bearer tokens on A2A traffic

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
  - authentication
  - openid-connect
  - okta

tldr:
  q: How do I secure AI Agent traffic with OpenID Connect?
  a: |
    Attach an [OpenID Connect Policy](/ai-gateway/policies/openid-connect/) to an [AI Agent](/ai-gateway/entities/ai-agent/) entity and configure it with your Okta issuer URL and client credentials.
    Requests without a valid bearer token are rejected with a 401. Authenticated requests are proxied to the upstream A2A agent.

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
    - title: Okta
      include_content: md/ai-gateway/v2/prereqs/okta-client-credentials
      icon_url: /assets/icons/okta.svg

related_resources:
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: OpenID Connect Policy reference
    url: /ai-gateway/policies/openid-connect/
  - text: Get started with AI Agent
    url: /ai-gateway/get-started-with-ai-agent/
  - text: Monitor AI Agent traffic with OpenTelemetry
    url: /ai-gateway/monitor-ai-agent-with-opentelemetry/

cleanup:
  inline:
    - title: Stop the A2A agent
      content: |
        ```sh
        docker compose down
        docker rm -f a2a-kongair-agent
        ```
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: Does OpenID Connect interfere with the AI Agent entity's A2A protocol handling?
    a: |
      No. The [AI Agent](/ai-gateway/entities/ai-agent/) entity handles A2A protocol detection, agent-card rewriting, and observability. The [OpenID Connect Policy](/ai-gateway/policies/openid-connect/) runs independently in the access phase, before any A2A-specific processing. Both can be attached to the same AI Agent without conflict.
  - q: Can I use a different identity provider instead of Okta?
    a: |
      Yes. The [OpenID Connect Policy](/ai-gateway/policies/openid-connect/) works with any OIDC-compliant identity provider (Keycloak, Auth0, Azure AD, and others). Replace `issuer`, `client_id`, and `client_secret` with values from your provider.
  - q: Can I combine OpenID Connect with ACLs on the same AI Agent?
    a: |
      Yes. [`access.acls`](/ai-gateway/entities/ai-agent/#access-control) on the AI Agent restricts which AI Consumers or AI Consumer Groups can reach it. The OpenID Connect Policy authenticates the caller first, then ACLs decide whether that identity is allowed through.

automated_tests: false

---

## Create an AI Agent and OpenID Connect Policy

Create an [OpenID Connect Policy](/ai-gateway/policies/openid-connect/) scoped to this Agent (`global: false`) that validates Okta bearer tokens, and an [AI Agent](/ai-gateway/entities/ai-agent/) that attaches it via `policies:`.

{% entity_examples %}
ai_gateway_policies:
  - ref: okta-oidc
    name: okta-oidc
    ai_gateway: !lookup name:ai-quickstart
    type: openid-connect
    enabled: true
    global: false
    config:
      issuer: !env OKTA_ISSUER
      client_id:
        - !env OKTA_CLIENT_ID
      client_secret:
        - !env OKTA_CLIENT_SECRET
      auth_methods:
        - bearer
ai_gateway_agents:
  - ref: kongair-flight-booking-agent
    ai_gateway: !lookup name:ai-quickstart
    display_name: "Kong Air Flight Booking Agent"
    type: a2a
    enabled: true
    policies: [ !ref okta-oidc#name ]
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

All requests to the `/a2a` route now require a valid bearer token from Okta.

## Validate unauthenticated requests are rejected

Send an A2A request without a token:

```sh
curl -X POST "http://localhost:8000/a2a" \
  -H "Content-Type: application/json" \
  --json '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "message/send",
    "params": {
      "message": {
        "kind": "message",
        "messageId": "msg-001",
        "role": "user",
        "parts": [
          {
            "kind": "text",
            "text": "What flights are available on route KA-123?"
          }
        ]
      }
    }
  }'
```

The request fails with `401 Unauthorized`.

## Validate authenticated requests succeed

Obtain a token from Okta using client credentials:

```sh
export TOKEN=$(curl -s -X POST \
  "$OKTA_ISSUER/v1/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=$OKTA_CLIENT_ID" \
  -d "client_secret=$OKTA_CLIENT_SECRET" \
  | jq -r '.access_token')
```

Send the A2A request with the token:

```sh
curl -X POST "http://localhost:8000/a2a" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --json '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "message/send",
    "params": {
      "message": {
        "kind": "message",
        "messageId": "msg-001",
        "role": "user",
        "parts": [
          {
            "kind": "text",
            "text": "What flights are available on route KA-123?"
          }
        ]
      }
    }
  }'
```

{{site.ai_gateway}} validates the bearer token via Okta's JWKS endpoint, then proxies the request to the upstream A2A agent. A successful response (status 200) contains the agent's reply.
