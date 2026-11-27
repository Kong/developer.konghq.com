---
title: Authorize and rate limit AI traffic by IdP claims
permalink: /ai-gateway/authorize-and-rate-limit-by-idp-claims/
content_type: how_to
description: Use the claims in a validated OIDC token to decide who can reach an AI Model and how much they can send, without creating an AI Consumer or Principal per caller.

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.4'

entities:
  - ai-auth-strategy
  - ai-model
  - ai-model-provider
  - ai-policy

tags:
  - ai
  - authentication
  - openid-connect
  - traffic-control

tools:
  - kongctl

tldr:
  q: How do I authorize and rate limit callers by what their identity provider says about them, instead of by AI Consumer or Principal?
  a: |
    Attach an OpenID Connect [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) on an AI Model so {{site.ai_gateway}} validates each caller's token, then read that token's claims in CEL with `access_token.claims`.
    Use those claims in a [CEL-based ACL](/ai-gateway/entities/ai-model/#cel-based-acls) on the [AI Model](/ai-gateway/entities/ai-model/) to decide who may reach it.
    
    Then, add the claims in a [Rate Limiting Advanced](/ai-gateway/policies/rate-limiting-advanced/) AI Policy to give each caller their own counter and a limit that matches their entitlement.
    
    Because every decision comes from the token, {{site.ai_gateway}} doesn't need an AI Consumer or a Principal for each caller.

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Set up Keycloak
      include_content: prereqs/auth/oidc/keycloak-consumer-group

related_resources:
  - text: AI Policy conditions
    url: /ai-gateway/conditions/
  - text: OpenID Connect authentication with {{site.ai_gateway}} 2.0
    url: /ai-gateway/openid-connect/
  - text: Rate Limiting Advanced AI Policy
    url: /ai-gateway/policies/rate-limiting-advanced/
  - text: Configure dynamic Policy config with CEL in {{site.ai_gateway}}
    url: /ai-gateway/configure-dynamic-plugin-config-with-cel/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: Can I use an identity provider other than Keycloak?
    a: |
      Yes. The OpenID Connect [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) works with any OIDC-compliant provider. Replace `issuer`, `client_id`, and `client_secret` with values from your provider, and change the claim names in the expressions to the ones your provider issues.
---

## Create an AI Auth Strategy and AI Model Provider

Create an OpenID Connect [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that points at Keycloak, and an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) for OpenAI.

The AI Auth Strategy sets `consumer_optional: true`, so a validated token is enough to pass authentication. 
{{site.ai_gateway}} doesn't look for a matching AI Consumer or Principal mapping for this use case.

<!--vale off-->
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: keycloak-oidc
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: "Keycloak OIDC"
    name: keycloak-oidc
    type: openid-connect
    config:
      issuer: !env DECK_ISSUER
      client_id:
        - kong
      client_secret:
        - !secret {source: !env CLIENT_SECRET}
      auth_methods:
        - client_credentials
      consumer_optional: true
      cache_tokens_salt: keycloak-oidc-cache-salt
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: generic-openai
    display_name: generic-openai
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
{% endentity_examples %}
<!--vale on-->

{:.info}
> Your identity provider's issuer URL has to be reachable from the data plane that runs {{site.ai_gateway}}, because that's where token validation happens.

## Create a Rate Limiting Advanced AI Policy driven by claims

Create a [Rate Limiting Advanced](/ai-gateway/policies/rate-limiting-advanced/) AI Policy whose counter key and limit both come from the caller's token:

<!--vale off-->
{% entity_examples %}
ai_gateway_policies:
  - ref: claims-rate-limit
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: claims-rate-limit
    display_name: "Claims rate limit"
    type: rate-limiting-advanced
    enabled: true
    global: false
    config:
      identifier: ip
      custom_key: unknown-caller
      limit:
        - 5
      window_size:
        - 60
      strategy: local
    expressions:
      custom_key: access_token.claims.sub
      limit:
        - '(has(access_token.claims.tier) && access_token.claims.tier == "gold") ? 100 : 5'
{% endentity_examples %}
<!--vale on-->

In this example:
* `expressions.custom_key`: Keys the counter on the `sub` claim, so each caller gets their own counter without being registered anywhere.
* `expressions.limit`: Gives `gold` callers 100 requests per minute and everyone else 5.
* `config.custom_key` and `config.limit`: Static fallbacks, used for any request whose expression can't be evaluated. Keep the fallback limit low, so a caller with missing claims is restricted rather than unlimited.
* `config.window_size`: Set in `config` only, because `window_size` isn't expressible.

## Create an AI Model that only gold callers can reach

Create an [AI Model](/ai-gateway/entities/ai-model/) that references the AI Auth Strategy and the AI Policy, and restricts access with a [CEL-based ACL](/ai-gateway/entities/ai-model/#cel-based-acls).

Authentication and authorization are separate here. The AI Auth Strategy accepts any valid token from Keycloak. `allow_when` is what decides that only callers with `tier: gold` may reach this AI Model:

<!--vale off-->
{% entity_examples %}
ai_gateway_models:
  - ref: claims-chat
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: claims-chat
    display_name: claims-chat
    type: model
    enabled: true
    formats:
      - type: openai
    access:
      auth_strategies:
        - keycloak-oidc
      acls:
        allow_when:
          - 'has(access_token.claims.tier) && access_token.claims.tier == "gold"'
    policies:
      - claims-rate-limit
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - claims-chat
    capabilities:
      - generate
    targets:
      - name: gpt-4o-mini
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}
<!--vale on-->

## Validate

Send an unauthenticated request to verify that it's rejected:

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: claims-chat
  messages:
    - role: user
      content: What is the capital of France?
status_code: 401
{% endvalidation %}
<!--vale on-->

Now send the same request with the Keycloak client's credentials. 
{{site.ai_gateway}} runs the client credentials grant against Keycloak, validates the token it gets back, and makes its claims available to the ACL and the AI Policy:

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
display_headers: true
headers:
  - 'Authorization: Basic {{ "kong:$CLIENT_SECRET" | base64 }}'
  - 'Content-Type: application/json'
body:
  model: claims-chat
  messages:
    - role: user
      content: What is the capital of France?
status_code: 200
{% endvalidation %}
<!--vale on-->

The request succeeds, because the token carries `tier: gold` and the ACL allows it.

Check the `RateLimit-Limit` response header:

```
RateLimit-Limit: 100
```
{:.no-copy-code}

The limit is `100`, which `expressions.limit` derived from the `tier` claim, instead of the static fallback of `5` in `config.limit`. 
The counter behind it is keyed on the `sub` claim, so every caller gets their own.
