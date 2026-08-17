---
title: Secure AI Agent traffic with OpenID Connect and {{site.identity}}
permalink: /ai-gateway/secure-ai-agent-with-oidc/
content_type: how_to
description: Reference an openid-connect AI Identity Provider backed by {{site.identity}} on an AI Agent entity to require bearer tokens on A2A traffic

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

series:
  id: a2a-identity-2-0
  position: 2

entities:
  - ai-agent
  - ai-identity-provider

tags:
  - ai
  - a2a
  - authentication
  - openid-connect

tldr:
  q: How do I secure AI Agent traffic with OpenID Connect?
  a: |
    Create an `openid-connect` [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/) that points at a {{site.identity}} auth server's issuer URL and client credentials, then reference it in an [AI Agent](/ai-gateway/entities/ai-agent/) entity's `access.identity_providers` array.
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

related_resources:
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI Identity Provider entity
    url: /ai-gateway/entities/ai-identity-provider/
  - text: Set up a {{site.identity}} auth server for AI Agent authentication
    url: /ai-gateway/set-up-kong-identity-for-a2a/
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
        {: data-test-cleanup="block" }
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: Does OpenID Connect interfere with the AI Agent entity's A2A protocol handling?
    a: |
      No. The [AI Agent](/ai-gateway/entities/ai-agent/) entity handles A2A protocol detection, agent-card rewriting, and observability. The [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/) runs independently in the access phase, before any A2A-specific processing.
  - q: Can I use a different identity provider instead of {{site.identity}}?
    a: |
      Yes. The `openid-connect` [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/) type works with any OIDC-compliant identity provider (Okta, Keycloak, Auth0, Azure AD, and others). Replace `issuer`, `client_id`, and `client_secret` with values from your provider.
  - q: Can I combine OpenID Connect with ACLs on the same AI Agent?
    a: |
      Yes. [`access.acls`](/ai-gateway/entities/ai-agent/#access-control) on the AI Agent restricts which AI Consumers or AI Consumer Groups can reach it. The AI Identity Provider authenticates the caller first, then ACLs decide whether that identity is allowed through.
  - q: Can I attach the OpenID Connect Policy directly to the AI Agent instead?
    a: |
      No. Attaching an authentication AI Policy directly to an AI Agent's `policies` field isn't supported. Authentication for AI Agents is configured exclusively through AI Identity Providers referenced in `access.identity_providers`.

automated_tests: false
---

This how-to continues from [Set up a {{site.identity}} auth server for AI Agent authentication](/ai-gateway/set-up-kong-identity-for-a2a/). Complete that how-to first, you need its `$ISSUER_URL`, `$CLIENT_ID`, and `$CLIENT_SECRET` to create the AI Identity Provider.

## Create an AI Identity Provider and AI Agent

Create an `openid-connect` [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/) that uses {{site.identity}} as the issuer, and an [AI Agent](/ai-gateway/entities/ai-agent/) that references it through `access.identity_providers`.

{% entity_examples %}
ai_gateway_identity_providers:
  - ref: identity-oidc
    ai_gateway: !lookup name:ai-quickstart
    display_name: "Identity OIDC"
    name: identity-oidc
    type: openid-connect
    config:
      issuer: $ISSUER_URL
      client_id:
        - $CLIENT_ID
      client_secret:
        - $CLIENT_SECRET
      auth_methods:
        - bearer
      scopes:
        - a2a-access
      cache_tokens_salt: identity-oidc-cache-salt
ai_gateway_agents:
  - ref: kongair-flight-booking-agent
    ai_gateway: !lookup name:ai-quickstart
    display_name: "Kong Air Flight Booking Agent"
    type: a2a
    enabled: true
    access:
      identity_providers:
        - !ref identity-oidc#name
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

All requests to the `/a2a` route now require a valid bearer token from {{site.identity}}.

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

Generate a token for the client and export it:

<!--vale off-->
```sh
export ACCESS_TOKEN=$(curl -s -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "scope=a2a-access" \
  | jq -r '.access_token')
```
<!--vale on-->

Send the A2A request with the token:

```sh
curl -X POST "http://localhost:8000/a2a" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
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

{{site.ai_gateway}} validates the bearer token against {{site.identity}}, then proxies the request to the upstream A2A agent. A successful response (status 200) contains the agent's reply.
