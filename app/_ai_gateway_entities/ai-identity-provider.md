---
title: AI Identity Providers
content_type: reference
entities:
  - ai-identity-provider
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-identity-provider/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: Configure inbound AI Consumer authentication for AI Models in {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayIdentityProvider
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: Key Auth policy reference
    url: /ai-gateway/policies/key-auth/
  - text: OpenID Connect policy reference
    url: /ai-gateway/policies/openid-connect/
faqs:
  - q: What is the difference between an AI Identity Provider and an AI Model Provider?
    a: |
      An AI Identity Provider manages inbound authentication: it validates credentials that AI Consumers
      present when calling an AI Model. An AI Model Provider manages outbound credentials: the secrets
      {{site.ai_gateway}} uses to authenticate to an upstream LLM service on behalf of the AI Consumer.

  - q: Can an AI Model use both key-auth and OIDC authentication at the same time?
    a: |
      Yes. An AI Model supports one `key-auth` AI Identity Provider and one `openid-connect`
      AI Identity Provider simultaneously. An AI Consumer's request is authenticated
      if it satisfies either provider.

  - q: What happens when a request carries no valid credentials?
    a: |
      {{site.ai_gateway}} treats the request as an anonymous AI Consumer. A request-termination
      policy on that anonymous AI Consumer returns `401 Unauthorized` before the request reaches
      the AI Model.

  - q: Can I reuse the same AI Identity Provider across multiple AI Models?
    a: |
      Yes. Create an AI Identity Provider once and reference it by `name` or `id` in the
      `access.identity_providers` array of any AI Model in the same gateway.

  - q: Which OIDC flows does the openid-connect type support?
    a: |
      By default, bearer token and client credentials flows are enabled. The full set includes
      `authorization_code`, `bearer`, `client_credentials`, `introspection`, `kong_oauth2`,
      `password`, `refresh_token`, `session`, and `userinfo`. Configure which flows are active
      with `config.auth_methods`.
---

## What is an AI Identity Provider?

Your AI Models often need access control: some teams should reach certain models and others should not, and you need a way to verify who is calling before a request consumes tokens or touches sensitive data. An AI Identity Provider lets you declare an inbound authentication mechanism at the gateway level and attach it to specific models.

Use AI Identity Providers to:

* Issue API keys to AI Consumers and restrict which models they can access
* Authenticate enterprise users through an existing identity provider (Okta, Azure AD, Google, or any OIDC-compliant IdP) without managing keys manually
* Apply different authentication to different models. For example, API keys for internal automation and OIDC bearer tokens for user-facing applications.

An AI Identity Provider manages inbound authentication, which is distinct from the outbound credentials managed by an [AI Model Provider](/ai-gateway/entities/ai-model-provider/). When an AI Consumer calls an AI Model, the AI Identity Provider checks who they are. The AI Model then uses the AI Model Provider's credentials to forward the request upstream.

The following diagram shows where authentication fits in the request pipeline:

{% mermaid %}
flowchart LR
    Client["AI Consumer"]
    KeyAuth["Key Auth"]
    OIDC["OpenID Connect"]
    Decision{Auth?}
    AnonErr["Anonymous AI Consumer<br/>Request Terminating w/ 401"]
    ModelSel["ai-model-selector"]
    ACLs["ACLs"]
    Model1["AI Model A"]
    Model2["AI Model B"]

    Client-->KeyAuth
    KeyAuth-->OIDC
    OIDC-->Decision
    Decision-->|no auth|AnonErr
    Decision-->|auth|ModelSel
    ModelSel-->|selects model|ACLs
    ACLs-->Model1
    ACLs-->Model2
{% endmermaid %}

Authentication runs before `ai-model-selector` so that unauthenticated requests never reach model routing or policy evaluation.

## Manage AI Identity Providers

AI Identity Providers can be created and managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/identity`

For configuration examples and step-by-step setup instructions, see [Set up an AI Identity Provider](#set-up-an-ai-identity-provider) below.

## Authentication types

{{site.ai_gateway}} supports two identity provider types. Pick based on how your AI Consumers authenticate:

{% table %}
columns:
  - title: Type
    key: type
  - title: When to use
    key: when
  - title: AI Consumer credential
    key: credential
  - title: Policy
    key: policy
rows:
  - type: "`key-auth`"
    when: "Your AI Consumers are internal tools, scripts, or teams that you control. You want to issue and rotate static API keys without involving an external identity provider."
    credential: "API key in a request header, query parameter, or request body"
    policy: "[Key Auth](/ai-gateway/policies/key-auth/)"
  - type: "`openid-connect`"
    when: "Your AI Consumers already authenticate through an enterprise IdP (Okta, Azure AD, Google, or similar). You want to accept the tokens they already have rather than issuing separate keys."
    credential: "JWT bearer token or OAuth 2.0 grant from an external IdP"
    policy: "[OpenID Connect](/ai-gateway/policies/openid-connect/)"
{% endtable %}

### API key authentication

The `key-auth` type uses the [Key Auth policy](/ai-gateway/policies/key-auth/) to validate an API key that the AI Consumer passes on every request. The gateway looks for the key in a configurable header or query parameter, checks it against the AI Consumer's registered key, and either authenticates the request or routes it to the anonymous AI Consumer (which terminates with `401`).

By default, {{site.ai_gateway}} accepts the key in an `apikey` header or `apikey` query parameter. Override the key name with `config.key_names`. For example, set `config.key_names: ["X-API-Key"]` to enforce a standard header name across your APIs.

{% table %}
columns:
  - title: Option
    key: option
  - title: Default
    key: default
  - title: Description
    key: description
rows:
  - option: "`key_in_header`"
    default: "`true`"
    description: "Accept the key in a request header."
  - option: "`key_in_query`"
    default: "`true`"
    description: "Accept the key as a query parameter."
  - option: "`key_in_body`"
    default: "`false`"
    description: "Accept the key in the request body. Supports `application/json`, `application/x-www-form-urlencoded`, and `multipart/form-data`."
  - option: "`hide_credentials`"
    default: "`true`"
    description: "Strip the key from the request before forwarding upstream."
{% endtable %}

### OIDC token authentication

The `openid-connect` type uses the [OpenID Connect policy](/ai-gateway/policies/openid-connect/) to validate a JWT or OAuth 2.0 token that the AI Consumer obtains from an external IdP. The gateway verifies the token against the IdP's published keys, maps the token to an AI Consumer, and either authenticates the request or routes it to the anonymous AI Consumer (which terminates with `401`).

Set `config.issuer` to the IdP's discovery URL (for example, `https://dev-123456.okta.com`). {{site.ai_gateway}} uses the OIDC discovery endpoint to fetch signing keys automatically.

The default `config.auth_methods` are `bearer` and `client_credentials`. If your AI Consumers use a different grant flow, add it to the list. For a full list of supported values, see the [OpenID Connect policy reference](/ai-gateway/policies/openid-connect/).

To map the token to an existing AI Consumer, set `config.consumer_claim` to the JSON path of the claim in the token that carries the AI Consumer identifier. If no mapping is needed, set `config.consumer_optional: true` to allow unauthenticated token holders through ACL checks.

{:.warning}
> All AI Models in the same {{site.ai_gateway}} that use OIDC authentication must reference the same `openid-connect` AI Identity Provider. Using different OIDC providers across models in the same {{site.ai_gateway}} is not supported.

## Assigning an AI Identity Provider to an AI Model

An AI Identity Provider takes effect only when assigned to an [AI Model](/ai-gateway/entities/ai-model/). Reference the provider by `name` or `id` in the `access.identity_providers` array on the AI Model:

```yaml
access:
  identity_providers:
    - my-key-auth-provider
  acls:
    - allowed-ai-consumer-group
```

{:.info}
> **Assignment rules**
> * Each AI Model supports one `key-auth` identity provider and one `openid-connect` identity provider.
> * You can assign both types to the same AI Model. A request is authenticated if it satisfies either provider.

If you plan to rename the AI Identity Provider later, reference it by `id` rather than name. The ID is stable across renames.

## Set up an AI Identity Provider

### API key authentication

The following example creates a `key-auth` AI Identity Provider that accepts AI Consumer API keys in the `X-API-Key` header:

{% entity_example %}
type: identity-provider
data:
  display_name: API Key Auth
  name: api-key-auth
  type: key-auth
  config:
    key_names:
      - X-API-Key
    key_in_header: true
    key_in_query: false
    hide_credentials: true
{% endentity_example %}

### OIDC bearer token authentication

The following example creates an `openid-connect` AI Identity Provider that accepts bearer tokens issued by Okta:

{% entity_example %}
type: identity-provider
data:
  display_name: Okta AI SE
  name: okta-ai-se
  type: openid-connect
  config:
    issuer: https://dev-123456.okta.com
    client_id:
      - my-client-id
    client_secret:
      - my-client-secret
    auth_methods:
      - bearer
    scopes:
      - openid
{% endentity_example %}

## Schema

{% entity_schema %}
