---
title: Serve Claude subscriptions and company Claude models on one {{site.ai_gateway}} base URL
content_type: how_to
permalink: /ai-gateway/use-claude-subscriptions-with-ai-gateway/
description: Configure two sets of AI Models, so that {{ site.claude_code }} developers who use their own Claude subscription and developers who use company-paid Claude models share one {{site.ai_gateway}} base URL.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.4'

automated_tests: false

entities:
  - ai-auth-strategy
  - ai-model
  - ai-model-provider
  - ai-policy

tags:
  - ai
  - anthropic
  - authentication
  - openid-connect

tldr:
  q: How can {{ site.claude_code }} developers with their own Claude subscription use the same {{site.ai_gateway}} base URL as developers on company-paid models?
  a: |
    Create two sets of AI Models on one base path. Company AI Models read the IdP token from `Authorization` and call Anthropic with your key. Subscription AI Models read the IdP token from `x-kong-id-token`, and match only requests with a claude.ai token.

prereqs:
  inline:
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: md/ai-gateway/v2/prereqs/anthropic
    - title: Okta authorization server
      include_content: prereqs/auth/oidc/okta-claude-subscriptions
      icon_url: /assets/icons/okta.svg
    - title: "{{ site.claude_code }}"
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code
    - title: Claude subscription
      content: |
        To test the subscription AI Models, you need a Claude Pro or Max subscription, and {{ site.claude_code }} signed in with it.
      icon_url: /assets/icons/third-party/claude.svg

related_resources:
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/
  - text: Claude Code SSO recipe
    url: /cookbooks/claude-code-sso/

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

Some developers sign in to [{{ site.claude_code }}](/ai-gateway/use-claude-code-with-ai-gateway-anthropic/) with their own Claude subscription.
{{ site.claude_code }} then sends a claude.ai token in `Authorization`, and the subscription pays for the request.
Other developers use the Claude models that your company pays for.
Both groups can use the same {{site.ai_gateway}} base URL with two sets of AI Models:

* Company AI Models use the Claude model IDs, for example `claude-opus-5-5`.
  They authenticate the IdP token in `Authorization`.
* Subscription AI Models use the same IDs with a `-subscription` suffix, for example `claude-opus-5-5-subscription`.
  They authenticate the IdP token in the `x-kong-id-token` header.

The following diagram shows a subscription request:

{% mermaid %}
flowchart LR
  C[{{ site.claude_code }}] -->|claude.ai token in Authorization| G
  C -->|IdP token in x-kong-id-token| G[{{site.ai_gateway}}]
  G -->|claude.ai token, unchanged| A[Anthropic]
{% endmermaid %}

{:.warning}
> This setup has the following limits:
> * {{site.ai_gateway}} can't check that the claude.ai account belongs to the developer who the IdP token identifies.
> * {{site.ai_gateway}} can report an estimated cost for a subscription request, but Anthropic bills it to the subscription of the developer.
> * Subscription developers can use only the Claude models that you create subscription AI Models for, even if their subscription includes more models.

## Create the company AI Models

The company AI Models use the following entities:

* An `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that reads the IdP token from `Authorization` and requires the `ai-gateway-company` scope.
* An [AI Model Provider](/ai-gateway/entities/ai-model-provider/) with your Anthropic key.
* One [AI Model](/ai-gateway/entities/ai-model/) for each Claude model.

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: company-oidc
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Company OIDC
    name: company-oidc
    type: openid-connect
    config:
      issuer: !env ISSUER_URL
      audience_required:
        - api://ai-gateway
      auth_methods:
        - bearer
      bearer_token_param_type:
        - header
      scopes_required:
        - ai-gateway-company
      scopes_claim:
        - scp
      hide_credentials: true
      upstream_access_token_header: null
      cache_tokens_salt: company-oidc-cache-salt
ai_gateway_model_providers:
  - ref: anthropic-company
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Anthropic company
    name: anthropic-company
    type: anthropic
    config:
      auth:
        type: basic
        headers:
          - name: x-api-key
            value: !secret {source: !env ANTHROPIC_API_KEY}
ai_gateway_models:
  - ref: claude-opus-5-5
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: claude-opus-5-5
    name: claude-opus-5-5
    type: model
    capabilities:
      - generate
    formats:
      - type: anthropic
    targets:
      - name: claude-opus-5-5
        provider: anthropic-company
        config:
          type: anthropic
    access:
      auth_strategies:
        - !ref company-oidc#name
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - claude-opus-5-5
{% endentity_examples %}

The company entities use the following settings:

* `scopes_required`: Only developers with the `ai-gateway-company` scope can use the company AI Models.
* `scopes_claim: [scp]`: Okta puts the scopes of an access token in the `scp` claim.
  If `scopes_claim` keeps its default, `scope`, {{site.ai_gateway}} rejects Okta access tokens that have the required scope in `scp`.
* `upstream_access_token_header: null`: {{site.ai_gateway}} doesn't send the IdP token to Anthropic.
  The company AI Models only need your Anthropic key.
* `config.route.model.values`: Give each AI Model on the base path its own model ID.
  If two AI Models use the same model ID, they share one model entry on the data plane, and the entry retains only one of their settings.

Keep [`targets[].allow_auth_override`](/ai-gateway/entities/ai-model/#schema-aigateway-target-allow-auth-override) set to `false`, so that a client credential can't replace your key.
To add more Claude models, create one company AI Model for each, with the Anthropic model ID as the model ID.

## Create the developer subscription AI Models

The individual developer's subscription AI Models use the following entities:

* An `openid-connect` AI Auth Strategy that reads the IdP token from `x-kong-id-token`.
* An Anthropic AI Model Provider without a key.
* A [Request Transformer](/ai-gateway/policies/request-transformer/) AI Policy that removes `x-api-key` from the request.
* One AI Model for each Claude model, with a `-subscription` model ID and the Anthropic model ID as the target name.
  Developers can use only the Claude models that you create subscription AI Models for.

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: subscription-oidc
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Subscription OIDC
    name: subscription-oidc
    type: openid-connect
    config:
      issuer: !env ISSUER_URL
      audience_required:
        - api://ai-gateway
      auth_methods:
        - bearer
      bearer_token_param_type:
        - header
      bearer_token_header_name: x-kong-id-token
      hide_credentials: true
      upstream_access_token_header: null
      cache_tokens_salt: subscription-oidc-cache-salt
ai_gateway_model_providers:
  - ref: anthropic-subscriptions
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Anthropic subscriptions
    name: anthropic-subscriptions
    type: anthropic
    config:
      auth:
        type: basic
ai_gateway_policies:
  - ref: drop-client-api-key
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Drop client API key
    name: drop-client-api-key
    type: request-transformer
    config:
      remove:
        headers:
          - x-api-key
ai_gateway_models:
  - ref: claude-opus-5-5-subscription
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: claude-opus-5-5-subscription
    name: claude-opus-5-5-subscription
    type: model
    capabilities:
      - generate
    formats:
      - type: anthropic
    targets:
      - name: claude-opus-5-5
        provider: anthropic-subscriptions
        config:
          type: anthropic
    access:
      auth_strategies:
        - !ref subscription-oidc#name
    policies:
      - !ref drop-client-api-key#name
    config:
      route:
        paths:
          - /
        headers:
          x-kong-id-token:
            - "~*.+"
          authorization:
            - "~*^bearer sk-ant-oat"
        model:
          body_param: model
          values:
            - claude-opus-5-5-subscription
{% endentity_examples %}

The subscription entities use the following settings:

* `bearer_token_header_name: x-kong-id-token`: The strategy reads the IdP token from `x-kong-id-token`, so `Authorization` can keep the claude.ai token.
* `hide_credentials: true`: {{site.ai_gateway}} removes `x-kong-id-token` before it sends the request to Anthropic.
* `upstream_access_token_header: null`: If `upstream_access_token_header` keeps its default, `authorization:bearer`, {{site.ai_gateway}} replaces the claude.ai token in `Authorization` with the IdP token.
* The strategy has no `scopes_required`: Any developer with a valid IdP token from your issuer for the `api://ai-gateway` audience can use the subscription AI Models, because their own subscription pays for the request.
* `config.route.headers`: The subscription route matches a request only when it has a value in `x-kong-id-token` and an `Authorization` value that starts with `Bearer sk-ant-oat`, the prefix of a claude.ai token.
  The route checks only this prefix, and Anthropic checks that the claude.ai token is valid.
* `drop-client-api-key`: The AI Policy removes any `x-api-key` that the client sends.

The company route also matches subscription requests.
{{site.ai_gateway}} selects the subscription route, because it matches two request headers and the company route matches none.
Without the header rules, both routes match the same requests, and {{site.ai_gateway}} sends all of them to one set of AI Models.
The header rules also let the two sets use different `openid-connect` AI Auth Strategies on the same base path.

{{site.ai_gateway}} sends a subscription request to Anthropic with the claude.ai token unchanged, without `x-kong-id-token` and without `x-api-key`.
{{site.ai_gateway}} doesn't send anything to Anthropic when a request has one of these problems:

* The request doesn't have an IdP token, or the IdP token isn't valid.
  The request fails with `401`.
* The request has a model ID of the other set.
  The request fails with a `5xx` error, because its route doesn't have an AI Model for that model ID.
  {{ site.claude_code }} can retry the request for a few minutes before it shows the error.

{:.warning}
> A subscription AI Model must follow these rules:
> * Use only Anthropic targets without a key and with the default upstream URL, `https://api.anthropic.com`.
>   {{site.ai_gateway}} sends the claude.ai token to each target of a subscription AI Model.
> * Don't add `http_401` to [`failover_criteria`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-failover-criteria).
>   A credential that Anthropic rejects must fail, and {{site.ai_gateway}} must not try it on another target.
> * Don't attach an AI Policy that calls an LLM with your provider key.
>   If you do, your company pays for part of a subscription request.
> * Don't use `x-kong-id-token` as a cost tag header, because {{site.ai_gateway}} sends cost tags to analytics.
> * Don't add a second AI Auth Strategy to an AI Model of either set.
>   If an AI Model has a second strategy, a request can pass with the credential of the other strategy and skip the IdP token check.

## Configure {{ site.claude_code }} for subscription developers

To validate this setup, export the variables for subscription developers in a new terminal.
In production, developers set these values in the `env` of their `~/.claude/settings.json`.

A subscription developer signs in to {{ site.claude_code }} with their Claude subscription.
Don't set `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN` or `apiKeyHelper`, because {{ site.claude_code }} then sends that credential in place of the claude.ai token.

Set `KONNECT_PROXY_URL` to the proxy URL of your {{site.ai_gateway}}.
On the quickstart host, this is `http://localhost:8000`.
On other machines, use the HTTPS proxy URL from your {{site.ai_gateway}} admin.
To test both groups on one machine, use a separate shell for each group, because the settings of one group break the requests of the other.
Values in the `env` of your {{ site.claude_code }} settings files replace these shell values, so remove any `env` entry that conflicts with them.

### Get an Okta access token

Get an access token from the Okta app with the authorization code flow and PKCE, and request the `openid` scope:

1. Generate a PKCE code verifier and challenge:

   ```sh
   export CODE_VERIFIER=$(openssl rand -base64 48 | tr -d '=+/' | cut -c1-64)
   export CODE_CHALLENGE=$(printf '%s' "$CODE_VERIFIER" | openssl dgst -sha256 -binary | openssl base64 -A | tr '+/' '-_' | tr -d '=')
   ```

1. Print the authorization URL:

   ```sh
   echo "$ISSUER_URL/v1/authorize?response_type=code&client_id=$OKTA_CLIENT_ID&redirect_uri=http://localhost:9876/callback&scope=openid&state=test123&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256"
   ```

   For company developers, change `scope=openid` to `scope=openid%20ai-gateway-company`.

1. Open the URL in a browser, and sign in as a developer from the group that you test.
1. Okta redirects the browser to `http://localhost:9876/callback`.
   The page doesn't load, because nothing listens on that port.
   Copy the `code` value from the address bar:

   ```sh
   export AUTH_CODE='CODE_FROM_THE_ADDRESS_BAR'
   ```

1. Exchange the code for tokens:

   ```sh
   curl -s -X POST "$ISSUER_URL/v1/token" \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d "grant_type=authorization_code&code=$AUTH_CODE&redirect_uri=http://localhost:9876/callback&client_id=$OKTA_CLIENT_ID&code_verifier=$CODE_VERIFIER"
   ```

1. Copy the `access_token` value from the response.
   This is the IdP token.

### Set the developer subscription environment variables

Set every model slot of {{ site.claude_code }} to a subscription model ID, and send the IdP token in `x-kong-id-token`:

```sh
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN
export ANTHROPIC_BASE_URL="$KONNECT_PROXY_URL"
export ANTHROPIC_MODEL=claude-opus-5-5-subscription
export ANTHROPIC_DEFAULT_MODEL=claude-opus-5-5-subscription
export ANTHROPIC_DEFAULT_FABLE_MODEL=claude-opus-5-5-subscription
export ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-5-5-subscription
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-opus-5-5-subscription
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-opus-5-5-subscription
export CLAUDE_CODE_SUBAGENT_MODEL=claude-opus-5-5-subscription
export CLAUDE_CODE_BG_CLASSIFIER_MODEL=claude-opus-5-5-subscription
export CLAUDE_CODE_AUTO_MODE_MODEL=claude-opus-5-5-subscription
export ANTHROPIC_CUSTOM_HEADERS='x-kong-id-token: YOUR_IDP_TOKEN'
```

Each subscription model ID starts with the Anthropic model ID, so {{ site.claude_code }} recognizes the model and keeps its context window.
To use other Claude models, create a subscription AI Model for each, and set the slots to their model IDs.

IdP tokens are short-lived.
Before the token expires, set a new value in `ANTHROPIC_CUSTOM_HEADERS` and restart {{ site.claude_code }}.
In production, give developers a script that gets a new token and updates this value.

## Configure {{ site.claude_code }} for company developers

A company developer sends an IdP token with the `ai-gateway-company` scope in `Authorization`.
[Get the token](#get-an-okta-access-token) from the Okta app as a subscription developer does, but request the `openid` and `ai-gateway-company` scopes.
Set `KONNECT_PROXY_URL` as for [subscription developers](#configure-claude-code-for-subscription-developers).
Set the token in `ANTHROPIC_AUTH_TOKEN`, and set every model slot to a company model ID:

```sh
unset ANTHROPIC_API_KEY ANTHROPIC_CUSTOM_HEADERS
export ANTHROPIC_BASE_URL="$KONNECT_PROXY_URL"
export ANTHROPIC_AUTH_TOKEN='YOUR_IDP_TOKEN'
export ANTHROPIC_MODEL=claude-opus-5-5
export ANTHROPIC_DEFAULT_MODEL=claude-opus-5-5
export ANTHROPIC_DEFAULT_FABLE_MODEL=claude-opus-5-5
export ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-5-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-opus-5-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-opus-5-5
export CLAUDE_CODE_SUBAGENT_MODEL=claude-opus-5-5
export CLAUDE_CODE_BG_CLASSIFIER_MODEL=claude-opus-5-5
export CLAUDE_CODE_AUTO_MODE_MODEL=claude-opus-5-5
```

{{site.ai_gateway}} sends only your Anthropic key to Anthropic, and doesn't send the IdP token.
Before the IdP token expires, set a new value in `ANTHROPIC_AUTH_TOKEN` and restart {{ site.claude_code }}.

## Validate

In the shell with the subscription settings, start {{ site.claude_code }} on the subscription AI Model:

<!-- vale off -->
{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: claude-opus-5-5-subscription
{% endvalidation %}
<!-- vale on -->

{{ site.claude_code }} answers, and Anthropic bills the request to the subscription.

In the shell with the company settings, start {{ site.claude_code }} on the company AI Model:

<!-- vale off -->
{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: claude-opus-5-5
{% endvalidation %}
<!-- vale on -->

{{ site.claude_code }} answers, and Anthropic bills the request to your Anthropic key.
