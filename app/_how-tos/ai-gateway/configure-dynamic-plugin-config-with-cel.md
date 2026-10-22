---
title: Configure dynamic Policy config with CEL in {{site.ai_gateway}}
permalink: /ai-gateway/configure-dynamic-plugin-config-with-cel/
content_type: how_to

description: Learn how to set a Rate Limiting Advanced Policy's rate limit and rate limiting key per request, based on the authenticated Principal's metadata.
products:
  - ai-gateway
  - identity

works_on:
  - konnect

entities:
  - ai-auth-strategy
  - ai-model-provider
  - ai-model
  - principal

tags:
  - ai
  - traffic-control
  - authentication

tools:
  - kongctl

min_version:
  ai-gateway: '2.3'

tldr:
  q: How do I compute an AI Policy's config from a CEL expression instead of a fixed value?
  a: |
    To compute a Policy's config from a CEL expression instead of a fixed value, set a config field's parallel `expressions.FIELD` entry to a CEL expression, alongside the field's ordinary static `config.FIELD` value.
    {{site.ai_gateway}} evaluates the expression per request.
    If it succeeds, its result overrides the field for that request; if it fails, {{site.ai_gateway}} falls back to the static `config` value.

    This guide computes the Rate Limiting Advanced Policy's `limit` and `custom_key` fields from a Principal's metadata, so each authenticated caller gets their own rate limit and their own counter from a single Policy instance.

faqs:
  - q: What happens if a Principal is missing the metadata that an expression expects to find?
    a: |
      If the Principal is missing expected metadata, the expression fails to evaluate, and {{site.ai_gateway}} falls back to the field's static `config` value for that request.
      {{site.ai_gateway}} doesn't raise an error, and the Policy still runs normally.

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Kong Identity directory
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

related_resources:
  - text: Configure dynamic plugin config with CEL in {{site.base_gateway}}
    url: /gateway/configure-dynamic-plugin-config-with-cel/
  - text: Rate Limiting Advanced Policy
    url: /ai-gateway/policies/rate-limiting-advanced/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/

automated_tests: false
---

## Create a Principal

A Policy's config can be computed per request from a [CEL expression](/ai-gateway/conditions/), for example, reading an attribute of the authenticated AI Consumer or Principal, instead of always using a fixed value.
In this guide, you'll create a [Principal](/identity/principals/) so that a custom limit can be applied to authenticated Principals.
{% include /how-tos/steps/principal.md %}

Set `rate_limit` and `partner_id` metadata on the Principal so the Policy's expressions have something to read:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID
status_code: 200
method: PUT
body:
  display_name: "example-principal"
  description: "Example principal"
  metadata:
    rate_limit: 20
    partner_id: acme-rockets
{% endkonnect_api_request %}
<!--vale on-->

## Add key auth

Add an API key credential to the Principal so clients can authenticate with {{site.ai_gateway}} using key authentication.

The following example sets a system-generated key (`v1`) and stores the key secret as `$KEY_SECRET`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/api-keys
status_code: 201
method: POST
body:
  type: v1
capture:
  - variable: KEY_SECRET
    jq: ".secret"
{% endkonnect_api_request %}
<!--vale on-->

## Get the directory name

{% include /how-tos/steps/get-directory-name.md %}

## Create an AI Auth Strategy, AI Model Provider, Policy, and AI Model

Create a `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) with [Kong Identity Principal mapping](/ai-gateway/entities/ai-auth-strategy/#principal-mapping) enabled, so clients authenticate with the API key but {{site.ai_gateway}} resolves them to the Principal created earlier. 
Also create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) for OpenAI and a [Rate Limiting Advanced Policy](/ai-gateway/policies/rate-limiting-advanced/) with CEL expressions.
Then create an [AI Model](/ai-gateway/entities/ai-model/) that references both the AI Auth Strategy and the Policy.

`limit` and `custom_key` are expressible config fields on the Rate Limiting Advanced Policy. They both have parallel entries under `expressions`, alongside their static `config` values:

* `identifier: principal`, so the Policy keys and limits by the authenticated Principal.
* A static `config.limit` and `config.custom_key`, used as the fallback whenever a request's expressions can't be evaluated.
* `expressions.limit` and `expressions.custom_key`, reading the authenticated Principal's `rate_limit` and `partner_id` metadata.

<!-- vale off -->
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: identity-principal
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: "Identity Principal"
    name: identity-principal
    type: key-auth
    config:
      principals:
        enabled: true
        directory: $DIRECTORY_NAME
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
ai_gateway_policies:
  - ref: rate-limit-by-principal
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: rate-limit-by-principal
    display_name: "Rate Limiting Advanced - Principal Metadata"
    type: rate-limiting-advanced
    config:
      identifier: principal
      custom_key: unknown-partner
      limit:
        - 10
      window_size:
        - 60
      strategy: local
      expressions:
        custom_key: principal.metadata.partner_id
        limit:
          - principal.metadata.rate_limit
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
        - !ref identity-principal#name
    policies:
      - !ref rate-limit-by-principal#name
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
formats:
  - kongctl
{% endentity_examples %}
<!-- vale on -->

## Validate

Send a request with the API key stored in `$KEY_SECRET`:

{% validation request-check %}
url: /chat/completions
method: POST
display_headers: true
headers:
  - "apikey: $KEY_SECRET"
  - 'Content-Type: application/json'
body:
  model: my-gpt-4o-mini
  messages:
    - role: user
      content: What is the capital of France?
status_code: 200
{% endvalidation %}

Check the `RateLimit-Limit` response header:

```
RateLimit-Limit: 20
```
{:.no-copy-code}

The limit is now `20` from `expressions.limit` instead of the static fallback value of `10` from `principal.metadata.rate_limit`.

To see the static fallback take over, remove the Principal's `rate_limit` metadata:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID
status_code: 200
method: PUT
body:
  display_name: "example-principal"
  description: "Example principal"
  metadata:
    partner_id: acme-rockets
{% endkonnect_api_request %}
<!--vale on-->

{:.warning}
> {{site.ai_gateway}} caches a successfully authenticated Principal for the directory's configured `ttl_secs` (5 minutes at minimum, 10 minutes by default). Wait at least 5 minutes after the previous request before continuing, or the next request will still show the cached Principal's old metadata.

After the `ttl` has elapsed (5-10 minutes), send another request:

{% validation request-check %}
url: /chat/completions
method: POST
display_headers: true
headers:
  - "apikey: $KEY_SECRET"
  - 'Content-Type: application/json'
body:
  model: my-gpt-4o-mini
  messages:
    - role: user
      content: What is the capital of France?
status_code: 200
{% endvalidation %}

With `rate_limit` no longer present on the Principal, `expressions.limit` fails to evaluate, and {{site.ai_gateway}} falls back to the static `config.limit` value of `10`:

```
RateLimit-Limit: 10
```
{:.no-copy-code}
