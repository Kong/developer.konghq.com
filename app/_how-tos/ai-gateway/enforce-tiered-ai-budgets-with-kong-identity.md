---
title: Enforce tiered AI budgets on an AI Model with {{site.identity}}
permalink: /ai-gateway/enforce-tiered-ai-budgets-with-kong-identity/
content_type: how_to
description: Attach an AI Identity Provider backed by {{site.identity}}, per-model ACLs, and a multi-ceiling AI Rate Limiting Advanced Policy to enforce tiered AI budgets from a claim.

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
    Create an openid-connect AI Identity Provider, an AI Model that references it through access.identity_providers and denies suspended or contractor classes through access.acls, and an ai-rate-limiting-advanced AI Policy with one ceiling per tier plus a shared org pool and an individual cap. Every matching ceiling is charged, and the lowest remaining one binds.

tools:
  - kongctl
  - konnect-api

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
  - q: Why does the identity provider need a follow-up API call after kongctl apply?
    a: |
      `consumer_groups_claim`, `consumer_groups_optional`, `upstream_headers_claims`, and `upstream_headers_names` are real fields on the AI Identity Provider, but kongctl's current schema for the resource doesn't recognize them and rejects the apply outright if they're included inline. Set them with a direct API request instead, and verify the response, since a plain `kongctl apply` without this step leaves the gateway authenticating but not enforcing.
  - q: What happens to a caller with no resolvable claim at all?
    a: |
      `consumer_groups_optional: true` means a missing or unrecognized group claim doesn't fail the request. The fail-safe policy, matched on nothing but the subject header, then bounds that caller at the same ceiling as the top tier instead of leaving them unlimited.
  - q: Why does the fail-safe policy matter?
    a: |
      `ai-rate-limiting-advanced` has no enforcement to fall back on when nothing matches. If an expression upstream ever returns null instead of a literal default, the tier header goes missing and a caller with no matching policy is not rate limited at all. The fail-safe policy matches on the subject header alone, so it always applies, and caps that caller at the top tier's ceiling instead of leaving them unbounded.

automated_tests: false

---

## Create the AI Consumer Groups, AI Identity Provider, AI Model Provider, and AI Model

Create the two [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) that `access.acls` denies, an [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/) that verifies bearer tokens against your {{site.identity}} issuer, an [AI Model Provider](/ai-gateway/entities/ai-model-provider/), and an [AI Model](/ai-gateway/entities/ai-model/) that ties them together with an [AI Rate Limiting Advanced Policy](/ai-gateway/policies/ai-rate-limiting-advanced/):

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
          limits: [{ limit: 6000, window_size: 60, tokens_count_strategy: total_tokens }]
        - match:
            - { type: header, key: x-budget-tier, values: ["2x"] }
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 12000, window_size: 60, tokens_count_strategy: total_tokens }]
        - match:
            - { type: header, key: x-budget-tier, values: ["4x"] }
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 24000, window_size: 60, tokens_count_strategy: total_tokens }]
        - match:
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 24000, window_size: 60, tokens_count_strategy: total_tokens }]
        - match:
            - { type: header, key: x-budget-org, values: [live-balance], partition_by: false }
          window_type: sliding
          limits: [{ limit: 40000, window_size: 60, tokens_count_strategy: total_tokens }]
        - match:
            - { type: header, key: x-budget-cap, values: [strict] }
            - { type: header, key: x-budget-sub, partition_by: true }
          window_type: sliding
          limits: [{ limit: 4000, window_size: 60, tokens_count_strategy: total_tokens }]
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
          - contractors
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
{% endentity_examples %}

The fourth policy matches on the subject header alone, with no tier value, so it always applies. Every matching ceiling is charged and the lowest remaining one wins, so a tier change can't raise `cap-strict`, and a caller whose tier claim came back missing is bounded at the top tier's ceiling instead of left unlimited.

## Complete the identity provider

`consumer_groups_claim`, `consumer_groups_optional`, `upstream_headers_claims`, and `upstream_headers_names` are real fields on the AI Identity Provider, but kongctl's schema for this resource doesn't recognize them yet and rejects the apply if they're set inline. Look up the gateway's ID, then `PUT` the complete configuration directly:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways
status_code: 200
method: GET
capture:
  - variable: AI_GATEWAY_ID
    jq: '.data[] | select(.name=="ai-quickstart") | .id'
{% endkonnect_api_request %}
<!--vale on-->

Build the complete configuration:

```sh
cat > budget-identity.json <<EOF
{
  "name": "budget-identity",
  "display_name": "Budget identity",
  "type": "openid-connect",
  "config": {
    "issuer": "$ISSUER_URL",
    "auth_methods": ["bearer"],
    "consumer_optional": true,
    "consumer_groups_claim": ["kong_groups"],
    "consumer_groups_optional": true,
    "upstream_headers_claims": ["sub", "budget_tier", "budget_org", "budget_cap"],
    "upstream_headers_names": ["x-budget-sub", "x-budget-tier", "x-budget-org", "x-budget-cap"],
    "cache_tokens_salt": "budgets-cache-salt"
  }
}
EOF
```

Then `PUT` it:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/identity/budget-identity
status_code: 200
method: PUT
headers:
  - 'Content-Type: application/json'
body_cmd: $(cat budget-identity.json)
{% endkonnect_api_request %}
<!--vale on-->

Verify the fields took effect before relying on them:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/identity
status_code: 200
method: GET
capture:
  - variable: BUDGET_IDENTITY_CLAIM_COUNTS
    jq: '.data[] | select(.name=="budget-identity") | "\(.config.consumer_groups_claim|length):\(.config.upstream_headers_names|length)"'
{% endkonnect_api_request %}
<!--vale on-->

```sh
echo "$BUDGET_IDENTITY_CLAIM_COUNTS"
```

You should see the following output:

```text
1:4
```
{:.no-copy-code}

{:.warning}
> Re-running `kongctl apply` on the block previously reconciles the identity provider back to kongctl's own schema and silently clears these four fields, disabling both header projection and the ACL deny list while reporting success. Repeat this `PUT` after every `kongctl apply` that touches `budget-identity`, and re-run the verification above.

## Validate

Obtain a bearer token for each persona using the client credentials grant shown in [Set up a {{site.identity}} auth server for tiered AI budgets](/ai-gateway/set-up-kong-identity-for-tiered-ai-budgets/), then send requests through the model.

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
