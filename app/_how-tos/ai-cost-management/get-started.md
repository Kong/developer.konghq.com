---
title: Manage costs across your organization structure
permalink: /ai-cost-management/getting-started/
content_type: how_to
description: "Set up {{site.ai_cost_management}} end-to-end: attribute usage to a principal provisioned from your OIDC provider, price a model, track spend with a budget, capture custom tags, and set up custom price overrides."

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
  - get-started

breadcrumbs:
  - /ai-cost-management/

tldr:
  q: How do I manage costs across my entire organization structure?
  a: |
    {{site.ai_cost_management}} enables you to manage costs across your entire organization, or in any segment of the org that you need.
    To set up cost management for your org, you'll need to:
    1. Add your OIDC provider as a trusted IdP in Access Management with automatic user provisioning enabled.
    1. Upload an org structure CSV with `kongctl import identity org-chart`.
    1. Create a budget with a spend limit.
    1. Create an `openid-connect` AI Auth Strategy with `principals.enabled` and `principals.jit` set, and attach it to the AI Model.
    1. Install the attribution plugin so `ai-cost-` headers are captured as tags.

    The first authenticated request creates a matching principal automatically, and the usage event's subject is recorded as `principal/PRINCIPAL_UUID`.
    Requests to this model are priced from the catalog unless you set a price override.
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
  # - text: Set up OIDC sub claim attribution
  #   url: /ai-cost-management/oidc-sub-claim-attribution/
  # - text: Set up Kong Identity attribution
  #   url: /ai-cost-management/kong-identity-attribution/
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
    - title: Delete the price override
      content: |
        Delete the price override you set for `gpt-5.4-nano`:

        1. In the sidebar, click **Cost Management**.
        1. Click **Price Catalog**, then the **Provider overrides** tab.
        1. Open the menu for the `gpt-5.4-nano` row and click **View details**.
        1. Click **Delete custom rate**, then confirm.
      icon_url: /assets/icons/money.svg
---

{{site.ai_cost_management}} turns every AI request that passes through {{site.ai_gateway}} into a usage event with a cost, a user, and a timestamp.
This guide sets up a priced model, attributes usage to a principal using OIDC automatic user provisioning, tracks spend with a budget, and captures custom tags with the attribution plugin.

Every usage event's `subject` resolves to `principal/PRINCIPAL_UUID`.
The {{site.ai_cost_management}} [dashboard](/ai-cost-management/analytics-and-debugging/#dashboard), [explorer](/ai-cost-management/analytics-and-debugging/#explorer), and [events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) show the event by the principal's display name.

A request can generate a usage event without any setup, but that event has no cost, subject, or tags to analyze.
Each of the following provides useful attribution data:
* An org structure gives the provisioned principal reporting data, so its spend rolls up to the right cost center, user, and team.
* A trusted IdP resolves the token's caller to a principal, giving the event a subject.
* A price turns the event's token usage into a dollar cost.
* The attribution plugin captures `ai-cost-` headers as tags, so you can filter and budget spend by project, team, or any other dimension you choose.

The following diagram shows how the attribution flow works:

{% mermaid %}
sequenceDiagram
    participant client as Client
    participant gateway as {{site.ai_gateway}}
    participant identity as {{site.identity}}
    participant openai as OpenAI
    participant billing as {{site.ai_cost_management}}

    client->>gateway: Bearer token, ai-cost- headers
    activate gateway
    gateway->>gateway: AI Auth Strategy - verify token
    gateway->>identity: check trusted IdP
    activate identity
    identity->>identity: provision principal
    identity-->>gateway: principal
    deactivate identity
    gateway->>gateway: attribution plugin - capture ai-cost- tags
    gateway->>openai: forward request
    activate openai
    openai-->>gateway: prompt / completion
    deactivate openai
    gateway->>billing: emit usage event (subject, cost, tags)
    activate billing
    billing->>billing: track spend against budget
    billing-->>gateway: ack
    deactivate billing
    gateway-->>client: response
    deactivate gateway
{% endmermaid %}

{:.info}
> This guide attributes usage to a principal built from your own OIDC provider.
> * For a principal built from Kong Identity's own auth server instead, see [Set up Kong Identity attribution](/ai-cost-management/kong-identity-attribution/).
> * For attribution without a principal, using only the token's `sub` claim, see [Set up OIDC sub claim attribution](/ai-cost-management/oidc-sub-claim-attribution/).

## Add a trusted IdP

{% include /ai-cost-management/add-trusted-idp.md %}

## Upload an org structure (Optional)

{% include /ai-cost-management/upload-org-structure.md %}

## Set a budget

{% include /ai-cost-management/set-a-budget.md %}

## Create an AI Model Provider, AI Auth Strategy, and AI Model

Set up your {{site.base_gateway}} with a provider, a model, and an auth strategy.
* The [AI Model Provider](/ai-gateway/entities/ai-model-provider/) connects {{site.ai_gateway}} to OpenAI.
* The [AI Model](/ai-gateway/entities/ai-model/) selects the exact model to use for AI requests.
* The `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) verifies bearer tokens against your trusted IdP and forwards claims for provisioning.

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

## Install the attribution plugin

{% include /ai-cost-management/install-attribution-plugin.md %}

## Send a request

Get an access token from your OIDC provider, then send a chat completion to generate a usage event.
The auth strategy verifies the bearer token and resolves it to a principal, creating one automatically from the token's forwarded claims if none matches yet.
The `ai-cost-project` header sets the event's `project` tag.

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
  - 'ai-cost-project: atlas'
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
Filter it to the `project` tag you set earlier:

<!--vale off-->
{% validation custom-command %}
command: |
  curl -s "$KONNECT_CONTROL_PLANE_URL/v1/ai-cost-management/events?filter%5Btags.project%5D=atlas" \
    -H "Authorization: Bearer $KONNECT_TOKEN" \
    | jq '.data[] | {time, subject, context: .data.context, cost: .data.reported_cost, tags: .data.tags}'
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
  },
  "tags": {
    "project": "atlas"
  }
}
```
{:.no-copy-code}

Check the following in the response:
* `subject` shows your principal as `principal/PRINCIPAL_UUID`.
* `cost.value` is greater than `0`, using the model's list price from the [price catalog](/ai-cost-management/price-catalog/).
* `tags.project` shows `atlas`.

If `cost.value` is `0` or `subject` is absent, see [Troubleshoot missing or wrong data](/ai-cost-management/analytics-and-debugging/#troubleshoot-missing-or-wrong-data).

You can also check this in the {{site.konnect_short_name}} UI:
1. In the sidebar, click **Cost Management**.
1. Click **Dashboard** to see your request reflected in overall spend.
1. Click **Explorer** to see spend, requests, or tokens over time for this model.
1. Click **Events debugger** to find the individual event and open its full details.

## Set a price override

A [price override](/ai-cost-management/price-catalog/#overrides) replaces the model's list price with your own custom rate.

Set up an override from the {{site.konnect_short_name}} UI:

1. In the sidebar, click **Cost Management**.
1. Click **Price Catalog**.
1. In the effective rates table, search for `gpt-5.4-nano` and note its base input price for reference.
1. Click **Add override**.
1. Select **Custom rate**.
1. Click the **Provider** dropdown and select **OpenAI**.
1. For **Model**, choose `gpt-5.4-nano`.
1. Set **Base input** and **Output** to a rate different from the list price, so the change is easy to spot.
1. Click **Add override**.

Wait a few minutes for the override to take effect, then send another chat completion.
If the `$ACCESS_TOKEN` expired, request a new one using the same client credentials grant as before:

<!--vale off-->
{% validation request-check %}
url: /v1/chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $ACCESS_TOKEN'
  - 'ai-cost-project: atlas'
body:
  model: openai-chat
  messages:
    - role: user
      content: What is an API gateway?
status_code: 200
{% endvalidation %}
<!--vale on-->

Query the events API again:

<!--vale off-->
{% validation custom-command %}
command: |
  curl -s "$KONNECT_CONTROL_PLANE_URL/v1/ai-cost-management/events?filter%5Btags.project%5D=atlas" \
    -H "Authorization: Bearer $KONNECT_TOKEN" \
    | jq '.data[] | {time, subject, context: .data.context, cost: .data.reported_cost, tags: .data.tags}'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Find the newest event and confirm that `cost.value` now matches your override's rate instead of the list price from the earlier validate step.
For example, the previous event's cost was `0.000016`.
With a raised price, the event's cost becomes `0.00022`:

```json
{
  "time": "2026-11-12T19:07:49.715Z",
  "subject": "principal/01a1c15c-310d-79a6-acde-85f746946396",
  "context": {
    "provider": "openai",
    "model": "gpt-5.4-nano-2026-03-17",
    "model_id": "5382d282-c9d3-4c96-910e-76af70e3c883",
    "request_mode": "oneshot"
  },
  "cost": {
    "value": "0.00022",
    "currency": "USD"
  },
  "tags": {
    "project": "atlas"
  }
}
```
{:.no-copy-code}

## What's next

You can now:

- Explore spend by user, model, or provider in the [analytics views](/ai-cost-management/analytics-and-debugging/).
- Add email or Slack alerts to the budget. See [Notification channels](/ai-cost-management/notification-channels/).
