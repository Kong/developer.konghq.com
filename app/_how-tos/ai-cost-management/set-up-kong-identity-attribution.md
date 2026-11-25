---
title: Set up {{site.identity}} attribution for {{site.ai_cost_management}}
permalink: /ai-cost-management/kong-identity-attribution/
content_type: how_to
description: "Attribute AI usage events to {{site.identity}} principals that are created automatically on first login, so each caller appears by name in cost reports and budgets."

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
  q: How do I attribute AI usage to a {{site.identity}} principal?
  a: Upload your organization's structure, then create an `openid-connect` AI Auth Strategy with `principals.enabled` set to `true` and attach it to the AI Model. The first authenticated request creates a matching principal automatically, and the usage event's subject is recorded as `principal/PRINCIPAL_UUID`.

prereqs:
  inline:
    - title: OpenAI
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: "{{site.identity}} directory"
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg
    - title: "{{site.identity}} auth server and client"
      include_content: prereqs/kong-identity-auth-server-client
      icon_url: /assets/icons/identity.svg
  konnect:
    - name: "KONG_CUSTOM_PLUGIN_STREAMING_ENABLED"
      value: "on"

faqs:
  - q: Is it possible to add users manually instead of relying on automatic user provisioning?
    a: |
      Yes.
      Create a principal in the {{site.identity}} directory, then link it to your client so {{site.ai_gateway}} can match the token's `sub` claim to it, using `POST /v2/directories/{directoryId}/principals` and `POST /v2/directories/{directoryId}/principals/{principalId}/identities`.
      See [Principals](/identity/principals/) for details.

related_resources:
  - text: Get started with {{site.ai_cost_management}}
    url: /ai-cost-management/getting-started/
  - text: Set up OIDC attribution with automatic user provisioning
    url: /ai-cost-management/oidc-attribution/
  # - text: Set up OIDC sub claim attribution
  #   url: /ai-cost-management/oidc-sub-claim-attribution/
  - text: Attribution in {{site.ai_cost_management}}
    url: /ai-cost-management/attribution/
  - text: Attribution integrations
    url: /ai-cost-management/integrations/
  - text: Analytics and debugging in {{site.ai_cost_management}}
    url: /ai-cost-management/analytics-and-debugging/
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

{{site.identity}} attribution links each AI request to a {{site.identity}} principal.

Every usage event's `subject` resolves to `principal/PRINCIPAL_UUID`.
The {{site.ai_cost_management}} [dashboard](/ai-cost-management/analytics-and-debugging/#dashboard), [explorer](/ai-cost-management/analytics-and-debugging/#explorer), and [events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) show the event by the principal's display name.

{{site.ai_cost_management}} attributes usage in two independent tracks: the subject and tags, which record context like project or team through a separate mechanism.
This guide covers subject attribution only. See [Tags and headers](/ai-cost-management/attribution/#tags-and-headers) for the other track.

{:.info}
> This guide attributes usage to a principal built from {{site.identity}}'s own auth server.
> * For a principal built from your own OIDC provider instead, see [Set up OIDC attribution](/ai-cost-management/oidc-attribution/).
<!-- > * For attribution without a principal, using only the token's `sub` claim, see [Set up OIDC sub claim attribution](/ai-cost-management/oidc-sub-claim-attribution/). -->
> * For a full walkthrough that also covers budgets, pricing, and tag attribution, see [Get started with {{site.ai_cost_management}}](/ai-cost-management/getting-started/).

## Add a trusted IdP

A trusted IdP is the OIDC issuer {{site.konnect_short_name}} verifies tokens against, and the place you turn on automatic user provisioning for that issuer.
{{site.identity}}'s own auth server is a valid issuer, so add it as a trusted IdP:

1. In the {{site.konnect_short_name}} sidebar, click **Access Management**.
1. Click **Identity Providers**.
1. Click **Add trusted IdP**.
1. In the **Name** field, enter a label for this IdP, for example `Kong Identity`.
1. In the **Issuer URL** field, enter your issuer URL (run `echo $ISSUER_URL` to print the value you exported earlier).
1. Enable **Automatic user provisioning**.
1. Click **Add IdP**.

{:.info}
> A client credentials token includes only a `sub` claim, so this guide skips claim mapping.
> For an interactive sign-in flow, your provider's token can include richer claims.

## Upload an org structure (Optional)

{% include /ai-cost-management/upload-org-structure.md %}

## Set a budget

{% include /ai-cost-management/set-a-budget.md %}

## Create an AI Model Provider, AI Auth Strategy, and AI Model

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) to connect {{site.ai_gateway}} to OpenAI, an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that verifies bearer tokens against your {{site.identity}} issuer and enables principal lookup, and an [AI Model](/ai-gateway/entities/ai-model/) that references both.

When a request arrives, {{site.ai_gateway}} verifies the bearer token and looks up the principal whose identity matches the token's `sub` claim, then records it as the event's subject.
If no principal matches yet, {{site.identity}} creates one from the token, using the trusted IdP and automatic user provisioning you just set up.

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
  - ref: kong-identity-oidc
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: kong-identity-oidc
    display_name: "Kong Identity OIDC"
    type: openid-connect
    config:
      issuer: $ISSUER_URL
      auth_methods:
        - bearer
      principals:
        enabled: true
      scopes:
        - ai-cost-management-access
      cache_tokens_salt: kong-identity-attribution-cache-salt
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
        - !ref kong-identity-oidc#name
    policies: []
{% endentity_examples %}
<!--vale on-->

The target doesn't set `input_cost` or `output_cost`, so {{site.ai_cost_management}} falls back to the model's list price from the [price catalog](/ai-cost-management/price-catalog/).

## Send a request

Get an access token from your {{site.identity}} issuer, then send a chat completion to generate a usage event.
The auth strategy verifies the token and resolves it to a principal, creating one automatically from the token if none matches yet.

Request an access token using the client credentials grant:

<!--vale off-->
{% validation request-check %}
konnect_url: $ISSUER_URL
url: /oauth/token
method: POST
headers:
  - 'Content-Type: application/x-www-form-urlencoded'
form_url_encoded_data:
  grant_type: client_credentials
  client_id: $CLIENT_ID
  client_secret: $CLIENT_SECRET
  scope: ai-cost-management-access
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

The event should look like this:
```json
{
  "time": "2026-11-12T19:02:02.695Z",
  "subject": "principal/01a1c15c-310d-79a6-acde-85f746946396",
  "context": {
    "provider": "openai",
    "model": "gpt-5.4-nano-2026-03-17",
    "model_id": "5382d282-c9d3-4c96-910e-76af70e3c883",
    "request_mode": "oneshot"
  },
  "cost": {
    "value": "0.000016",
    "currency": "USD"
  }
}
```
{:.no-copy-code}

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
