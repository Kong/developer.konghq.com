---
title: Set up OIDC attribution for {{site.ai_cost_management}}
permalink: /ai-cost-management/oidc-attribution/
content_type: how_to
description: "Attribute AI usage events to principals auto-provisioned from your own OIDC provider's tokens, without setting up Kong Identity's own auth server or directory."

products:
  - ai-cost-management
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.3'

tools:
  - kongctl
  - konnect-api

entities:
  - ai-model-provider
  - ai-model
  - ai-auth-strategy

tags:
  - ai
  - governance
  - cost-management
  - authentication

breadcrumbs:
  - /ai-cost-management/

tldr:
  q: How do I attribute AI usage to a principal created automatically from my OIDC provider's tokens?
  a: |
    Add your OpenID Connect (OIDC) identity provider as a trusted IdP in [Access Management](/ai-access-management/) with automatic user provisioning enabled, then create an `openid-connect` AI Auth Strategy with `principals.enabled` and `principals.jit` set, and attach it to the AI Model.
    
    The first authenticated request creates a matching principal automatically, and {{site.konnect_short_name}} records the usage event's subject as `principal/PRINCIPAL_UUID`.

prereqs:
  inline:
    - title: OpenAI
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: ngrok
      include_content: prereqs/ai-cost-management/ngrok-tunnel
      icon_url: /assets/icons/ngrok.png
    - title: OIDC provider
      include_content: prereqs/auth/oidc/keycloak-client-credentials-ai-gateway-org-chart
      icon_url: /assets/icons/keycloak.svg
  konnect:
    - name: "KONG_CUSTOM_PLUGIN_STREAMING_ENABLED"
      value: "on"


related_resources:
  - text: Get started with {{site.ai_cost_management}}
    url: /ai-cost-management/getting-started/
  - text: Set up OIDC sub claim attribution
    url: /ai-cost-management/oidc-sub-claim-attribution/
  - text: Set up Kong Identity attribution
    url: /ai-cost-management/kong-identity-attribution/
  - text: Token Vault
    url: /identity/token-vault/
  - text: Attribution in {{site.ai_cost_management}}
    url: /ai-cost-management/attribution/
  - text: Attribution integrations
    url: /ai-cost-management/integrations/
  - text: Budgets in {{site.ai_cost_management}}
    url: /ai-cost-management/budgets/

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: /assets/icons/ai.svg
    - title: Delete the trusted IdP
      include_content: cleanup/ai-cost-management/delete-trusted-idp
      icon_url: /assets/icons/key.svg
    - title: Delete the budget
      include_content: cleanup/ai-cost-management/delete-budget
      icon_url: /assets/icons/money.svg
---

Automatic user provisioning creates a {{site.identity}} principal from any OIDC provider's token the first time its caller authenticates, without needing to set up a {{site.identity}} directory, auth server, or client manually.
Every usage event's `subject` resolves to `principal/PRINCIPAL_UUID`.

{{site.ai_cost_management}} attributes usage in two independent tracks: the subject and tags, which record context like project or team through a separate mechanism.
This guide covers subject attribution only. See [Tags and headers](/ai-cost-management/attribution/#tags-and-headers) for the other track.

{:.info}
> This guide attributes usage to a principal built from your own OIDC provider.
> * For a principal built from Kong Identity's own auth server instead, see [Set up Kong Identity attribution](/ai-cost-management/kong-identity-attribution/).
> * For attribution without a principal, using only the token's `sub` claim, see [Set up OIDC sub claim attribution](/ai-cost-management/oidc-sub-claim-attribution/).
> * For a full walkthrough that also covers budgets, pricing, and tag attribution, see [Get started with {{site.ai_cost_management}}](/ai-cost-management/getting-started/).

## Add a trusted IdP

{% include /ai-cost-management/add-trusted-idp.md %}

## Upload an org structure (Optional)

{% include /ai-cost-management/upload-org-structure.md %}

## Set a budget

{% include /ai-cost-management/set-a-budget.md %}

## Create an AI Model Provider, AI Auth Strategy, and AI Model

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) to connect {{site.ai_gateway}} to OpenAI, an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that verifies bearer tokens against your trusted IdP and forwards claims for provisioning, and an [AI Model](/ai-gateway/entities/ai-model/) that references both:

<!--vale off-->
{% entity_examples %}
ai_gateway_model_providers:
  - ref: openai-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: openai-provider
    display_name: "OpenAI"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_auth_strategies:
  - ref: oidc-attribution
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: oidc-attribution
    display_name: "OIDC Attribution"
    type: openid-connect
    config:
      issuer: $OIDC_ISSUER_URL
      auth_methods:
        - bearer
      principals:
        enabled: true
        jit:
          all_claims: true
      cache_tokens_salt: oidc-attribution-cache-salt
ai_gateway_models:
  - ref: openai-chat
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: openai-chat
    display_name: "OpenAI Chat"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    config:
      route:
        paths:
          - /v1
        model:
          body_param: model
          values:
            - openai-chat
    targets:
      - name: gpt-5.4-nano
        provider: !ref openai-provider#name
        config:
          type: openai
    access:
      auth_strategies:
        - !ref oidc-attribution#name
    policies: []
{% endentity_examples %}
<!--vale on-->

In this configuration example:

* The strategy's `principals.jit.all_claims` field forwards every token claim to the provisioning lookup, including the `email` claim you mapped on the trusted IdP.
* The target has no `input_cost` or `output_cost` set, so {{site.ai_cost_management}} falls back to the model's list price from the [price catalog](/ai-cost-management/price-catalog/).

## Send a request

Get an access token from your OIDC provider, then send a chat completion to generate a usage event.
The auth strategy verifies the bearer token and resolves it to a principal, creating one automatically from the token's forwarded claims if none matches yet.

Request an access token using the client credentials grant.
`/protocol/openid-connect/token` is Keycloak's token endpoint path.
Adjust it if you're using a different provider:

<!--vale off-->
{% validation request-check %}
konnect_url: $OIDC_ISSUER_URL
url: /protocol/openid-connect/token
method: POST
headers:
  - 'Content-Type: application/x-www-form-urlencoded'
form_url_encoded_data:
  grant_type: client_credentials
  client_id: $OIDC_CLIENT_ID
  client_secret: $OIDC_CLIENT_SECRET
extract_body:
  - name: access_token
    variable: ACCESS_TOKEN
capture:
  - variable: ACCESS_TOKEN
    jq: ".access_token"
status_code: 200
{% endvalidation %}
<!--vale on-->

Use the access token to send a chat completion, which generates the usage event:

<!--vale off-->
{% validation request-check %}
url: /v1/chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $ACCESS_TOKEN'
body:
  model: openai-chat
  messages:
    - role: user
      content: What is an API gateway?
status_code: 200
{% endvalidation %}
<!--vale on-->

## Validate

The events API returns the usage events for your organization, sorted by newest first.
Find the event your request generated. If your org has other traffic, check that `time` matches when you sent the request:

<!--vale off-->
{% validation custom-command %}
command: |
  curl -s "$KONNECT_CONTROL_PLANE_URL/v1/ai-cost-management/events" \
    -H "Authorization: Bearer $KONNECT_TOKEN" \
    | jq '.data[0] | {time, subject, context: .data.context, cost: .data.reported_cost}'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Check the following in the response:
* `subject` shows your principal as `principal/PRINCIPAL_UUID`.
* `cost.value` is greater than `0`, using the model's list price from the [price catalog](/ai-cost-management/price-catalog/).

If `cost.value` is `0` or `subject` is absent, see [Troubleshoot missing or wrong data](/ai-cost-management/analytics-and-debugging/#troubleshoot-missing-or-wrong-data).

You can also check this in the {{site.konnect_short_name}} UI:
1. In the sidebar, click **Cost Management**.
1. Click **Dashboard** to see your request reflected in overall spend.
1. Click **Explorer** to see spend, requests, or tokens over time for this model.
1. Click **Events debugger** to find the individual event and open its full details.

## What's next

You can now:

- Set a [price override](/ai-cost-management/price-catalog/#overrides) to replace the model's list price with your own negotiated rate.
- Explore spend by user, model, or provider in the [analytics views](/ai-cost-management/analytics-and-debugging/).
- Add email or Slack alerts to the budget. See [Notification channels](/ai-cost-management/notification-channels/).
