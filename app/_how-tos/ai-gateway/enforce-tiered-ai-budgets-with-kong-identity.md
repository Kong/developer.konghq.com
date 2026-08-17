---
title: Enforce tiered AI budgets on AI Models with {{site.identity}}
permalink: /ai-gateway/enforce-tiered-ai-budgets-with-kong-identity/
content_type: how_to
description: Attach an AI Identity Provider backed by {{site.identity}}, per-model ACLs across a standard and a premium AI Model, and a multi-ceiling AI Rate Limiting Advanced Policy to enforce tiered AI budgets from a claim.

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-consumer-group
  - ai-identity-provider
  - ai-model
  - ai-model-provider
  - ai-policy

series:
  id: tiered-ai-budgets-identity-2-0
  position: 2

tags:
  - ai
  - governance
  - authentication
  - kong-identity
  - openid-connect
  - rate-limiting
  - access-control
  - metering

tldr:
  q: How do I enforce tiered AI budgets from a {{site.identity}} claim?
  a: |
    Create an AI Identity Provider backed by {{site.identity}}, then a standard and a premium AI Model that both authenticate through it but deny different AI Consumer Groups. Attach an AI Rate Limiting Advanced Policy with a ceiling per tier plus a shared org pool and an individual cap: every matching ceiling is charged, and the lowest one binds no matter which model handles the request.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
    - title: A {{site.identity}} issuer and per-persona credentials
      content: |
        Complete [Set up a {{site.identity}} auth server for tiered AI budgets](/ai-gateway/set-up-kong-identity-for-tiered-ai-budgets/) first. You need its `$ISSUER_URL` and each persona's client ID and secret.

related_resources:
  - text: AI Identity Provider entity
    url: /ai-gateway/entities/ai-identity-provider/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: AI Rate Limiting Advanced policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
  - text: Set up a {{site.identity}} auth server for tiered AI budgets
    url: /ai-gateway/set-up-kong-identity-for-tiered-ai-budgets/

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: Why do only two AI Consumer Groups exist when there are three tiers and a cap?
    a: |
      Tiers and the cap are matched from headers the AI Identity Provider projects out of the token, not from AI Consumer Group entities, so a tier change never writes anything to {{site.ai_gateway}}. Only `contractors` and `suspended` need a matching AI Consumer Group, because `access.acls` compares against real group names.
  - q: Why do budget-identity's config fields include `consumer_groups_claim` and `upstream_headers_claims`?
    a: |
      These project the `kong_groups`, `budget_tier`, `budget_org`, and `budget_cap` claims from the token onto `x-budget-*` request headers and the ACL groups {{site.ai_gateway}} checks. `kongctl` (1.12.0 and later) applies them directly as part of the AI Identity Provider's `config`, no separate step required.
  - q: What happens to a caller with no resolvable claim at all?
    a: |
      `consumer_groups_optional: true` means a missing or unrecognized group claim doesn't fail the request. The fail-safe policy, matched on nothing but the subject header, then bounds that caller at the same ceiling as the top tier instead of leaving them unlimited.
  - q: Why does the fail-safe policy matter?
    a: |
      The AI Rate Limiting Advanced Policy has no enforcement to fall back on when nothing matches. If an expression upstream ever returns null instead of a literal default, the tier header goes missing and a caller with no matching policy is not rate limited at all. The fail-safe policy matches on the subject header alone, so it always applies, and caps that caller at the top tier's ceiling instead of leaving them unbounded.

automated_tests: false

---

## Create the AI Consumer Groups, AI Identity Provider, AI Model Provider, and AI Models

Create the two [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) that `access.acls` denies, an [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/) that verifies bearer tokens against your {{site.identity}} issuer, an [AI Model Provider](/ai-gateway/entities/ai-model-provider/), and two [AI Models](/ai-gateway/entities/ai-model/) that share a route and an [AI Rate Limiting Advanced Policy](/ai-gateway/policies/ai-rate-limiting-advanced/), but differ in which groups `access.acls` denies. `tokens_count_strategy: cost` charges each request in dollars, so the same ceiling applies whether a request lands on the cheaper `gpt-4o-mini` or the pricier `gpt-4o`:

{% entity_examples %}
ai_gateway_consumer_groups:
  - ref: contractors
    ai_gateway: !lookup name:ai-quickstart
    display_name: contractors
    name: contractors
  - ref: suspended
    ai_gateway: !lookup name:ai-quickstart
    display_name: suspended
    name: suspended
ai_gateway_identity_providers:
  - ref: budget-identity
    ai_gateway: !lookup name:ai-quickstart
    display_name: "Budget identity"
    name: budget-identity
    type: openid-connect
    config:
      issuer: !env ISSUER_URL
      auth_methods: [bearer]
      consumer_optional: true
      consumer_groups_claim: [kong_groups]
      consumer_groups_optional: true
      upstream_headers_claims: [sub, budget_tier, budget_org, budget_cap]
      upstream_headers_names: [x-budget-sub, x-budget-tier, x-budget-org, x-budget-cap]
      cache_tokens_salt: budgets-cache-salt
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup name:ai-quickstart
    name: generic-openai
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env OPENAI_AUTH_HEADER
ai_gateway_policies:
  - ref: budget-limits
    ai_gateway: !lookup name:ai-quickstart
    name: budget-limits
    display_name: "Budget limits"
    type: ai-rate-limiting-advanced
    enabled: true
    global: false
    config:
      strategy: local
      policies:
        - match:
            - { type: header, key: x-budget-tier, values: [baseline] }
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 0.05, window_size: 60, tokens_count_strategy: cost }]
        - match:
            - { type: header, key: x-budget-tier, values: ["2x"] }
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 0.10, window_size: 60, tokens_count_strategy: cost }]
        - match:
            - { type: header, key: x-budget-tier, values: ["4x"] }
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 0.20, window_size: 60, tokens_count_strategy: cost }]
        - match:
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 0.20, window_size: 60, tokens_count_strategy: cost }]
        - match:
            - { type: header, key: x-budget-org, values: [live-balance], partition_by: false }
          window_type: sliding
          limits: [{ limit: 0.35, window_size: 60, tokens_count_strategy: cost }]
        - match:
            - { type: header, key: x-budget-cap, values: [strict] }
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 0.02, window_size: 60, tokens_count_strategy: cost }]
ai_gateway_models:
  - ref: budget-chat
    ai_gateway: !lookup name:ai-quickstart
    display_name: "Budget chat"
    name: budget-chat
    type: model
    enabled: true
    formats: [{ type: openai }]
    capabilities: [generate]
    access:
      identity_providers:
        - !ref budget-identity#name
      acls:
        deny:
          - suspended
    policies:
      - !ref budget-limits#name
    config:
      route:
        paths: [/v1]
        model:
          body_param: model
          values: [budget-chat]
    targets:
      - name: gpt-4o-mini
        provider: generic-openai
        config:
          type: openai
          input_cost: 0.15
          output_cost: 0.60
  - ref: budget-chat-premium
    ai_gateway: !lookup name:ai-quickstart
    display_name: "Budget chat premium"
    name: budget-chat-premium
    type: model
    enabled: true
    formats: [{ type: openai }]
    capabilities: [generate]
    access:
      identity_providers:
        - !ref budget-identity#name
      acls:
        deny:
          - contractors
          - suspended
    policies:
      - !ref budget-limits#name
    config:
      route:
        paths: [/v1]
        model:
          body_param: model
          values: [budget-chat-premium]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
          input_cost: 2.50
          output_cost: 10.00
{% endentity_examples %}

{:.collapsible}

The caller picks a model with the request body's `model` field. The fourth policy in `budget-limits` matches on the subject header alone, so it always applies, and the lowest matching ceiling binds.

## Validate

Obtain a bearer token for each persona using the client credentials grant shown in [Set up a {{site.identity}} auth server for tiered AI budgets](/ai-gateway/set-up-kong-identity-for-tiered-ai-budgets/), then send requests through either model.

An unauthenticated request is rejected:

```sh
curl -X POST "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  --json '{
    "model": "budget-chat",
    "messages": [{ "role": "user", "content": "What is DNS?" }]
  }'
```

The request fails with `401 Unauthorized`.

Carol (`tier: "4x"`) authenticates and is charged against the 4x ceiling:

<!--vale off-->
```sh
export CAROL_ACCESS_TOKEN=$(curl -s -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CAROL_CLIENT_ID" \
  -d "client_secret=$CAROL_CLIENT_SECRET" \
  -d "scope=budgets-access" \
  | jq -r '.access_token')

curl -X POST "http://localhost:8000/v1/chat/completions" \
     --no-progress-meter --fail-with-body \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $CAROL_ACCESS_TOKEN" \
     --json '{
       "model": "budget-chat",
       "messages": [{ "role": "user", "content": "What is DNS?" }]
     }'
```
<!--vale on-->

Carol isn't in `contractors` or `suspended`, so the same token also reaches the premium model:

<!--vale off-->
```sh
curl -X POST "http://localhost:8000/v1/chat/completions" \
     --no-progress-meter --fail-with-body \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $CAROL_ACCESS_TOKEN" \
     --json '{
       "model": "budget-chat-premium",
       "messages": [{ "role": "user", "content": "What is DNS?" }]
     }'
```
<!--vale on-->

`budget-limits` charges the same `4x` ceiling either way, since the policy reads headers, not which model resolved the request. Only `access.acls` differs between the two models, and none of the five personas in this guide are in `contractors`, so this guide can't demonstrate a request denied on `budget-chat-premium` but accepted on `budget-chat`. Create a client with a `groups: "contractors"` label the same way the prior guide creates the others, and it's denied on `budget-chat-premium` while still reaching `budget-chat`.

Dave (`tier: "4x"`, `cap: "strict"`) authenticates the same way, but his individual cap and his tier ceiling are charged together, and the lower one binds:

<!--vale off-->
```sh
export DAVE_ACCESS_TOKEN=$(curl -s -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$DAVE_CLIENT_ID" \
  -d "client_secret=$DAVE_CLIENT_SECRET" \
  -d "scope=budgets-access" \
  | jq -r '.access_token')

curl -X POST "http://localhost:8000/v1/chat/completions" \
     --no-progress-meter --fail-with-body \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $DAVE_ACCESS_TOKEN" \
     --json '{
       "model": "budget-chat",
       "messages": [{ "role": "user", "content": "What is DNS?" }]
     }'
```
<!--vale on-->

Dave's `tier: "4x"` block alone would allow $0.20 per minute, the same as Carol. His `cap: "strict"` block is charged in parallel and caps him at $0.02 instead, so moving him to a higher tier later would never raise his ceiling. Only removing the `cap` label does.

Grace (`tier: "4x"`, `groups: "suspended"`) never reaches a budget:

<!--vale off-->
```sh
export GRACE_ACCESS_TOKEN=$(curl -s -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$GRACE_CLIENT_ID" \
  -d "client_secret=$GRACE_CLIENT_SECRET" \
  -d "scope=budgets-access" \
  | jq -r '.access_token')

curl -X POST "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRACE_ACCESS_TOKEN" \
  --json '{
    "model": "budget-chat",
    "messages": [{ "role": "user", "content": "What is DNS?" }]
  }'
```
<!--vale on-->

The request fails with `403 Forbidden`. `access.acls` denies on the `suspended` group before the request reaches `budget-limits`, regardless of Grace's tier.

## View usage in {{site.observability}}

{{site.ai_gateway}} exports Gen AI metrics to {{site.observability}}. View them in a dashboard built from a template:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.observability}}**.
1. In the {{site.observability}} sidebar, click [**Dashboards**](https://cloud.konghq.com/us/analytics/dashboards).
1. From the **Create dashboard** dropdown menu, select "Create from template".
1. Click **{{site.ai_gateway}} Template**.
1. Click **Use template**.

In the **Gen AI model usage count** tile, you'll see 2 uses of `gpt-4o-mini` and 1 use of `gpt-4o`, reflecting Carol's and Dave's requests to `budget-chat` and Carol's request to `budget-chat-premium`. Grace's request never reaches a model, so it doesn't appear here.
