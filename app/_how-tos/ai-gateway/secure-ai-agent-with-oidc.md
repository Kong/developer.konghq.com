---
title: Secure AI Agent traffic with an AI Auth Strategy and {{site.identity}}
permalink: /ai-gateway/secure-ai-agent-with-oidc/
content_type: how_to
description: Reference an openid-connect AI Auth Strategy backed by {{site.identity}} on an AI Agent entity to require bearer tokens on A2A traffic

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
  - ai-auth-strategy

tags:
  - ai
  - a2a
  - authentication
  - openid-connect

tldr:
  q: How do I secure AI Agent traffic with OpenID Connect?
  a: |
    Create an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that points at a {{site.identity}} auth server's issuer URL and client credentials, then reference it in an [AI Agent](/ai-gateway/entities/ai-agent/) entity's `access.auth_strategies` array.
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
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
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
    - title: Clean up Kong Identity resources
      include_content: md/identity/delete_auth_server

faqs:
  - q: Does OpenID Connect interfere with the AI Agent entity's A2A protocol handling?
    a: |
      No. The [AI Agent](/ai-gateway/entities/ai-agent/) entity handles A2A protocol detection, agent-card rewriting, and observability. The [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) runs independently in the access phase, before any A2A-specific processing.
  - q: Can I use a different identity provider instead of {{site.identity}}?
    a: |
      Yes. The `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) type works with any OIDC-compliant identity provider (Okta, Keycloak, Auth0, Azure AD, and others). Replace `issuer`, `client_id`, and `client_secret` with values from your provider.
  - q: Can I combine OpenID Connect with ACLs on the same AI Agent?
    a: |
      Yes. [`access.acls`](/ai-gateway/entities/ai-agent/#access-control) on the AI Agent restricts which AI Consumers or AI Consumer Groups can reach it. The AI Auth Strategy authenticates the caller first, then ACLs decide whether that identity is allowed through.
---

This how-to continues from [Set up a {{site.identity}} auth server for AI Agent authentication](/ai-gateway/set-up-kong-identity-for-a2a/). Complete that how-to first, you need its `$ISSUER_URL`, `$CLIENT_ID`, and `$CLIENT_SECRET` to create the AI Auth Strategy.

## Create an AI Auth Strategy and AI Agent

Create an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that uses {{site.identity}} as the issuer, and an [AI Agent](/ai-gateway/entities/ai-agent/) that references it through `access.auth_strategies`.

<!-- vale off -->
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: identity-oidc
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: "Identity OIDC"
    name: identity-oidc
    type: openid-connect
    config:
      issuer: $ISSUER_URL
      client_id:
        - $CLIENT_ID
      client_secret:
        - !secret {source: !env CLIENT_SECRET}
      auth_methods:
        - bearer
      scopes:
        - a2a-access
      cache_tokens_salt: identity-oidc-cache-salt
ai_gateway_agents:
  - ref: kongair-flight-booking-agent
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: "Kong Air Flight Booking Agent"
    type: a2a
    enabled: true
    access:
      auth_strategies:
        - !ref identity-oidc#name
    config:
      url: http://a2a-kongair-agent:10000
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
<!-- vale on -->

All requests to the `/a2a` route now require a valid bearer token from {{site.identity}}.

## Validate unauthenticated requests are rejected

Send an A2A request without a token:

<!--vale off-->
{% validation request-check %}
url: /a2a
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
        text: What flights are available on route KA-123?
status_code: 401
{% endvalidation %}
<!--vale on-->

The request fails with `401 Unauthorized`.

## Validate authenticated requests succeed

Generate a token for the client and export it:

<!-- vale off -->
{% validation request-check %}
konnect_url: $ISSUER_URL
url: /oauth/token
method: POST
headers:
  -  'Content-Type: application/x-www-form-urlencoded'
form_url_encoded_data:
  grant_type: client_credentials
  client_id: $CLIENT_ID
  client_secret: $CLIENT_SECRET
  scope: a2a-access
extract_body:
  - name: "access_token"
    variable: ACCESS_TOKEN
capture:
  - variable: ACCESS_TOKEN
    jq: ".access_token"
status_code: 200
{% endvalidation %}
<!--vale on-->

Send the A2A request with the token:

<!--vale off-->
{% validation request-check %}
url: /a2a
method: POST
headers:
  - 'Content-Type: application/json'
  - "Authorization: Bearer $ACCESS_TOKEN"
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
        text: What flights are available on route KA-123?
status_code: 200
{% endvalidation %}
<!--vale on-->

{{site.ai_gateway}} validates the bearer token against {{site.identity}}, then proxies the request to the upstream A2A agent. A successful response (status 200) contains the agent's reply.
