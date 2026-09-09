---
title: Identify AI Consumers on AI Model traffic with {{site.identity}}
permalink: /ai-gateway/identify-ai-consumers-with-kong-identity/
content_type: how_to
description: Replace a placeholder API key with a real oauth AI Consumer backed by {{site.identity}}, so AI Model traffic is authenticated and usage is tracked per consumer

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-consumer
  - ai-auth-strategy
  - ai-model
  - ai-model-provider

tags:
  - ai
  - authentication
  - openid-connect

tldr:
  q: How do I identify AI Consumers on AI Model traffic instead of using a placeholder API key?
  a: |
    Create a {{site.identity}} auth server and client, then create an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that references the auth server's issuer, and an `oauth` [AI Consumer](/ai-gateway/entities/ai-consumer/) whose `custom_id` matches the client's token claim. Attach the AI Auth Strategy to an [AI Model](/ai-gateway/entities/ai-model/)'s `access.auth_strategies`.
    Requests without a valid bearer token are rejected with a 401. Authenticated requests are proxied to the upstream model, and usage is attributed to the matched AI Consumer instead of an anonymous caller.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg

related_resources:
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Secure AI Agent traffic with an AI Auth Strategy and {{site.identity}}
    url: /ai-gateway/secure-ai-agent-with-oidc/
  - text: Enforce tiered AI budgets on AI Models with {{site.identity}}
    url: /ai-gateway/enforce-tiered-ai-budgets-with-kong-identity/
  - text: Get started with {{site.ai_gateway}}
    url: /ai-gateway/get-started/

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
    - title: Clean up {{site.identity}} resources
      include_content: md/identity/delete_auth_server

faqs:
  - q: Can I use a different identity provider with AI Consumer credentials instead of {{site.identity}}?
    a: |
      Yes. The `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) type works with any OIDC-compliant identity provider (Okta, Keycloak, Auth0, Azure AD, and others). Replace `issuer`, `client_id`, and `client_secret` with values from your provider, and set `config.consumer_claims` to wherever that provider places the identifier you use as the AI Consumer's `custom_id`.
  - q: What happens if a token's claim doesn't match any AI Consumer's `custom_id`?
    a: |
      {{site.ai_gateway}} treats the request as an anonymous AI Consumer. Attach a [Request Termination Policy](/ai-gateway/policies/request-termination/reference/) to the anonymous AI Consumer if you want unmatched tokens rejected outright rather than proxied as anonymous.
  - q: Can I combine this with `api-key` AI Consumers on the same AI Model?
    a: |
      Yes. Each AI Model supports one `key-auth` AI Auth Strategy and one `openid-connect` AI Auth Strategy at the same time. A request is authenticated if it satisfies either one, so you can keep issuing static API keys to some callers while others authenticate through {{site.identity}}.
---

[AI Model](/ai-gateway/entities/ai-model/) traffic can either use placeholder API keys or [AI Consumer](/ai-gateway/entities/ai-consumer/) credentials to authenticate traffic. 

A placeholder key satisfies a client SDK that insists on a non-empty API key value, but it doesn't identify who's calling. 
You can use placeholders for testing, but we strongly recommend using AI Consumers and consumer credentials in a production environment. 

AI Consumers with consumer credentials allow you to:
* Attribute usage per-consumer
* Apply per-caller policies
* Revoke access for one caller without revoking the shared placeholder for everyone
Additionally, in most production environments, consumers should not have access to API keys themselves for security reasons.

This how-to uses an [AI Consumer](/ai-gateway/entities/ai-consumer/) backed by a real credential (here, an OIDC bearer token) to give every request an identity that usage, rate limiting, and audit logs can use.

{% include /how-tos/steps/konnect-identity-server-scope-claim-client.md %}

## Create an AI Auth Strategy, AI Consumer, AI Model Provider, and AI Model

Create an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that uses {{site.identity}} as the issuer, an `oauth` [AI Consumer](/ai-gateway/entities/ai-consumer/) whose `custom_id` matches the client's token claim, and an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and [AI Model](/ai-gateway/entities/ai-model/) for OpenAI. 
The AI Model references the AI Auth Strategy through `access.auth_strategies`.

{:.warning}
> `custom_id` must match the value {{site.identity}} places in the token claim named in `config.consumer_claims` (`sub` in this example). Confirm the actual `sub` value for your client (for example, by decoding a generated access token) before relying on this in production.

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
        - my-scope
      consumer_claims:
        - - sub
      cache_tokens_salt: identity-oidc-cache-salt
ai_gateway_consumers:
  - ref: cli-tool-consumer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: "CLI Tool Consumer"
    name: cli-tool-consumer
    type: oauth
    custom_id: $CLIENT_ID
    policies: []
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_models:
  - ref: my-gpt-4o-mini
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: my-gpt-4o-mini
    name: my-gpt-4o-mini
    type: model
    enabled: true
    formats: [{ type: openai }]
    access:
      auth_strategies:
        - !ref identity-oidc#name
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - my-gpt-4o-mini
    capabilities: [generate]
    targets:
      - name: gpt-4o-mini
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}
<!-- vale on -->

In this example:
* `ai_gateway_auth_strategies.config.consumer_claims`: Locates the token claim that carries the AI Consumer identifier. `- - sub` maps to the top-level `sub` claim; nest further path segments to reach a claim nested deeper in the token.
* `ai_gateway_consumers.custom_id`: Set to the identifier {{site.identity}} issues for this client. {{site.ai_gateway}} matches this against the `sub` claim on every incoming token.
* `ai_gateway_model_providers.config.auth`: Stores your OpenAI API key. {{site.ai_gateway}} injects it into upstream requests automatically; the client that calls `my-gpt-4o-mini` never sees or needs it.
* `ai_gateway_models.access.auth_strategies`: Requires a valid bearer token from {{site.identity}} on every request to `my-gpt-4o-mini`.

## Validate

1. Send a chat completion request without a token:

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: my-gpt-4o-mini
  messages:
    - role: user
      content: What is the capital of France?
status_code: 401
indent: 3
{% endvalidation %}
<!--vale on-->

   The request fails with `401 Unauthorized`.

1. Generate a token for the client and export it:

<!-- vale off -->
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
  scope: my-scope
extract_body:
  - name: "access_token"
    variable: ACCESS_TOKEN
capture:
  - variable: ACCESS_TOKEN
    jq: ".access_token"
status_code: 200
indent: 3
{% endvalidation %}
<!--vale on-->

1. Send the same request with the token:

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
  - "Authorization: Bearer $ACCESS_TOKEN"
body:
  model: my-gpt-4o-mini
  messages:
    - role: user
      content: What is the capital of France?
status_code: 200
indent: 3
{% endvalidation %}
<!--vale on-->

   {{site.ai_gateway}} validates the bearer token against {{site.identity}}, matches its `sub` claim to the `cli-tool-consumer` AI Consumer, then proxies the request to OpenAI.

### Confirm usage is tracked per AI Consumer

1. In {{site.konnect_short_name}}, go to **Observability > Dashboards**.
1. From the **Create dashboard** dropdown menu, select "Create from template".
1. Click **{{site.ai_gateway}} dashboard**.
1. Click **Use template**.
1. Click **Add filter**.
1. Select "AI gateway consumer".
1. From the **Value** dropdown menu, select "CLI Tool Consumer".
1. Click **Apply**.

You will see that the request from the previous step is attributed to `cli-tool-consumer`, not to an anonymous caller.
