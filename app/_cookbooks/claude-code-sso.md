---
title: Claude Code SSO
description: Authenticate Claude Code requests through Okta SSO, with consumer-group-based model routing and per-tier token limits.
url: "/cookbooks/claude-code-sso/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - access-control
  - llm
featured: false
popular: false
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The two `-e` settings raise the data plane's request body buffer and limit to 16 MB, so the large request bodies that Claude Code sends (conversation history, tool definitions, file contents) stay in memory instead of being buffered to disk:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=16m \
               -e KONG_NGINX_HTTP_CLIENT_MAX_BODY_SIZE=16m
           ```

           This provisions an {{site.ai_gateway}} named `claude-code-sso-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl and jq
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration, and [jq](https://jqlang.org/) to edit the Claude Code settings file during cleanup.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Install **jq** from [jqlang.org](https://jqlang.org/).
        1. Verify that both are installed:

           ```bash
           kongctl version
           jq --version
           ```
    - title: Okta
      icon_url: /assets/icons/okta.svg
      content: |
        This tutorial uses an Okta organization with admin access. You create a Native OIDC application for Claude Code, add a `groups` claim to the access token, and assign one test user to one group.

        **Create the Native application**

        The Native application is a public client that represents Claude Code. It uses Authorization Code with PKCE and no client secret ([Okta: Create OIDC app integrations](https://help.okta.com/en-us/content/topics/apps/apps_app_integration_wizard_oidc.htm)).

        1. In the Okta Admin Console, go to **Applications and Resources > Applications**, click **Create App Integration**, and select **Classic experience**.
        1. Select **OIDC - OpenID Connect** and **Native Application**, then click **Next**.
        1. Name the application `Claude Code`.
        1. Under **Grant type**, select **Authorization Code** and **Refresh Token**. Without the Refresh Token grant, Okta doesn't issue refresh tokens and developers go through the browser sign-in each time a token expires.
        1. Set the sign-in redirect URI to `http://localhost:9876/callback`. The helper script that you install in [Connect Claude Code to Kong](#connect-claude-code-to-kong) listens on this address.
        1. Click **Save**.
        1. In **Client Credentials**, confirm that client authentication is **None** and that **Proof Key for Code Exchange (PKCE)** is required.
        1. Copy the **Client ID**.

        **Check the authorization server scopes**

        The helper script requests `openid`, `profile`, `email`, and `offline_access`. Okta's `default` authorization server includes these scopes. Without `offline_access`, Okta doesn't issue refresh tokens.

        1. Go to **Security > API** and select the `default` authorization server, or your custom server.
        1. Click the **Scopes** tab and confirm that the four scopes are listed. If `offline_access` is missing, add it.

        **Add the groups claim**

        The OpenID Connect AI Auth Strategy reads the `groups` claim from the access token and maps each value to the AI Consumer Group with the same name ([Okta: Customize tokens with a groups claim](https://developer.okta.com/docs/guides/customize-tokens-groups-claim/main/)).

        1. On the same authorization server, click the **Claims** tab, then click **Add Claim**.
        1. Set **Name** to `groups`, keep **Include in token type** as **Access Token**, and set **Value type** to **Groups**.
        1. Set **Filter** to **Matches regex** with the value `.*`, or restrict it to a prefix such as `claude-`.
        1. Click **Create**.

        **Create a group and a test user**

        The Kong configuration has two AI Consumer Groups, `claude-standard-users` and `claude-power-users`. Start with one Okta group and one user. [Swap to the power tier](#swap-to-the-power-tier) moves the user to the other tier.

        1. Go to **Directory > Groups** and create `claude-standard-users`.
        1. Go to **Directory > People** and add a user, for example `claude-test-user@example.com`, or pick an existing user who can sign in.
        1. Open the user, click the **Groups** tab, and add the user to `claude-standard-users`.
        1. Open the `Claude Code` application, click the **Assignments** tab, and assign the same user. Without this assignment, Okta blocks the sign-in.

        **Export the Okta values**

        Export the authorization server's issuer URL and audience. The audience is set on the authorization server, in its **Settings** tab. The `default` server uses `api://default`. `OIDC_CACHE_TOKENS_SALT` is a stable string that the OpenID Connect AI Auth Strategy uses to build its token cache keys. It isn't a credential:

        ```bash
        export OKTA_ISSUER='https://your-org.okta.com/oauth2/default'
        export OKTA_AUDIENCE='api://default'
        export OIDC_CACHE_TOKENS_SALT='claude-code-sso-dev-salt'
        ```

        If you use a custom authorization server, set `OKTA_ISSUER` to its issuer URL and `OKTA_AUDIENCE` to its audience.
    - title: Claude Code
      content: |
        This tutorial uses [Claude Code](https://code.claude.com/docs/en/setup).

        1. Install Claude Code from the [setup guide](https://code.claude.com/docs/en/setup).
        1. Verify that it's installed:

           ```bash
           claude --version
           ```

        1. Unset `ANTHROPIC_API_KEY` and `ANTHROPIC_AUTH_TOKEN` in your shell. Claude Code uses either variable before it runs `apiKeyHelper` ([authentication precedence](https://code.claude.com/docs/en/authentication#authentication-precedence)), so the recipe's helper script would never run:

           ```bash
           unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN
           ```
    - title: AI Credentials
      content: |
        Pick the provider you want to route to and export its credentials. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

        {% navtabs "Providers" %}
        {% navtab "Anthropic" %}
        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export the API key and the [Messages API version](https://docs.claude.com/en/api/versioning) that Kong sends upstream on each request:

           ```bash
           export ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export ANTHROPIC_VERSION='2023-06-01'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        1. Get an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Export your AWS credentials and region:

           ```bash
           export AWS_ACCESS_KEY_ID='your-access-key'
           export AWS_SECRET_ACCESS_KEY='your-secret-key'
           export AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure AI Foundry" %}
        [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/) hosts Claude at `https://<resource>.services.ai.azure.com/anthropic/v1/messages`.

        1. Create a Foundry project with Claude Sonnet 4.5 and Claude Opus 4.5 deployments. The deployment names become `AZURE_FOUNDRY_DEPLOYMENT_ID_1` and `AZURE_FOUNDRY_DEPLOYMENT_ID_2`.
        1. Export the Foundry values. `AZURE_FOUNDRY_UPSTREAM_URL` is the full endpoint URL that Kong calls. `AZURE_FOUNDRY_TOKEN` is a Foundry API key or an [Entra ID](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry) bearer token. The AI Model Provider sends it unchanged, so add the `Bearer ` prefix yourself if your token needs it:

           ```bash
           export AZURE_FOUNDRY_INSTANCE='your-foundry-resource'
           export AZURE_FOUNDRY_UPSTREAM_URL="https://${AZURE_FOUNDRY_INSTANCE}.services.ai.azure.com/anthropic/v1/messages"
           export AZURE_FOUNDRY_DEPLOYMENT_ID_1='your-sonnet-deployment'
           export AZURE_FOUNDRY_DEPLOYMENT_ID_2='your-opus-deployment'
           export AZURE_FOUNDRY_TOKEN='your-foundry-token'
           ```
        {% endnavtab %}
        {% navtab "Google Vertex AI" %}
        [Google Vertex AI Model Garden](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-claude) hosts Claude on Google Cloud.

        1. Enable the Vertex AI API in your project, get access to Claude Sonnet 4.5 and Claude Opus 4.5 in Model Garden, and create a service account JSON key with the `roles/aiplatform.user` role.
        1. Export the Vertex values. `VERTEX_LOCATION_ID` accepts `global`, which works for each Claude model, or a region such as `us-east5`, `europe-west1`, or `asia-southeast1`:

           ```bash
           export VERTEX_PROJECT_ID='your-gcp-project-id'
           export VERTEX_LOCATION_ID='global'
           export VERTEX_API_ENDPOINT='aiplatform.googleapis.com'
           export VERTEX_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json)"
           ```
        {% endnavtab %}
        {% endnavtabs %}
overview: |
  Put {{site.ai_gateway_name}} between Claude Code and your Claude provider, so that Okta SSO authenticates each request and the developer's Okta group decides which models they can use and how many tokens they get. You'll set up:

  * Okta JWT validation on each Claude Code request, with no provider credentials on developer machines
  * Two model tiers, where only the power tier can use Opus
  * A token budget for each tier
  * A {{site.konnect_short_name}} dashboard for Claude Code usage

  This cookbook covers Claude Code's API authentication path, which `apiKeyHelper` uses. Claude subscription seats that sign in with `claude /login` go directly to Anthropic and aren't covered.
---

## What this cookbook solves

Most teams give Claude Code access through a shared provider API key on each developer machine, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "A shared key in shell profiles, `.env` files, or CI secrets makes every developer's usage look the same, and a leaked key means rotating it on every machine and pipeline."
    solution: "The AI Model Provider keeps the provider credentials in Kong. Developers authenticate with their own Okta token, and Kong attributes each request to an Okta user."
  - problem: "The API key has no link to the identity provider. A developer removed from an Okta group can keep calling the API, because nothing checks the key against Okta. [Claude SSO](https://support.claude.com/en/articles/13132885-set-up-single-sign-on-sso) covers the `claude /login` subscription path, not API keys."
    solution: "The OpenID Connect AI Auth Strategy validates the Okta JWT on each request. When the token expires, the next token carries the user's current groups."
  - problem: "Each developer with a valid key gets the same models and the same budget. Cost control happens afterward, through billing alerts."
    solution: "AI Consumer Groups map Okta groups to tiers. Access control lists on the AI Models decide which tier can use Opus, and the AI Rate Limiting Advanced Policy gives each tier a token budget."
{% endtable %}

## Try it out

Apply the configuration, connect Claude Code to Kong, then use Claude Code to test the tier boundary, the token budget, and a tier change.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your provider's credentials, an OpenID Connect AI Auth Strategy for Okta, two AI Consumer Groups (`claude-standard-users` and `claude-power-users`) with an [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy each, and two AI Models (a sonnet tier and an opus tier) that allow access by AI Consumer Group. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Select your provider. Each tab exports four values, then applies the configuration:

* `SONNET_ALIAS` and `OPUS_ALIAS`: the model names that Claude Code sends for the standard and power tiers.
* `CHAT_MODEL_1` and `CHAT_MODEL_2`: the upstream models that Kong sends to the provider for each tier.

The Okta values and the provider credentials come from the prerequisites.

{:.warning}
> The two alias values must match `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` in each developer's Claude Code settings, and the models must exist in your provider account. Claude Code chooses which features to send (effort levels, extended thinking, beta tool fields) from the model name. If the alias names a newer model than the upstream one, for example `claude-sonnet-4-6` for a Sonnet 4.5 upstream, the provider rejects those fields with `400`.

{% navtabs "Providers" %}
{% navtab "Anthropic" %}

Export the model values:

```bash
export SONNET_ALIAS='claude-sonnet-4-6'
export OPUS_ALIAS='claude-opus-4-7'
export CHAT_MODEL_1='claude-sonnet-4-6'
export CHAT_MODEL_2='claude-opus-4-7'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
ai_gateway_model_providers:
- ref: claude-code-sso-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-provider
  display_name: claude-code-sso
  type: anthropic
  config:
    auth:
      type: basic
      headers:
      - name: x-api-key
        value: !secret {source: !env 'ANTHROPIC_TOKEN'}
ai_gateway_auth_strategies:
- ref: claude-code-sso-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-auth
  display_name: claude-code-sso Okta OIDC
  type: openid-connect
  config:
    issuer: !env 'OKTA_ISSUER'
    auth_methods:
    - bearer
    audience_required:
    - !env 'OKTA_AUDIENCE'
    consumer_groups_claim:
    - groups
    consumer_optional: true
    consumer_groups_optional: false
    upstream_headers_claims:
    - sub
    - email
    upstream_headers_names:
    - X-Authenticated-User
    - X-User-Email
    ssl_verify: true
    hide_credentials: true
    cache_tokens_salt: !env 'OIDC_CACHE_TOKENS_SALT'
ai_gateway_policies:
- ref: claude-code-sso-standard-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-standard-ratelimit
  display_name: claude-code-sso standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
- ref: claude-code-sso-power-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-power-ratelimit
  display_name: claude-code-sso power tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_consumer_groups:
- ref: claude-standard-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-standard-users
  display_name: Claude Code standard tier
  policies:
  - claude-code-sso-standard-ratelimit
- ref: claude-power-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-power-users
  display_name: Claude Code power tier
  policies:
  - claude-code-sso-power-ratelimit
ai_gateway_models:
- ref: claude-code-sso-sonnet
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-sonnet
  display_name: claude-code-sso (sonnet tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-standard-users
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'SONNET_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: claude-code-sso-provider
    config:
      version: !env 'ANTHROPIC_VERSION'
      type: anthropic
- ref: claude-code-sso-opus
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-opus
  display_name: claude-code-sso (opus tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'OPUS_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: claude-code-sso-provider
    config:
      version: !env 'ANTHROPIC_VERSION'
      type: anthropic
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

These values use Sonnet 4.5 and Opus 4.6 on Bedrock. If your account has other versions, change the aliases and the upstream model IDs to match.

Export the model values:

```bash
export SONNET_ALIAS='claude-sonnet-4-5'
export OPUS_ALIAS='claude-opus-4-6'
export CHAT_MODEL_1='global.anthropic.claude-sonnet-4-5-20250929-v1:0'
export CHAT_MODEL_2='global.anthropic.claude-opus-4-6-20250930-v1:0'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
ai_gateway_model_providers:
- ref: claude-code-sso-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-provider
  display_name: claude-code-sso
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: claude-code-sso-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-auth
  display_name: claude-code-sso Okta OIDC
  type: openid-connect
  config:
    issuer: !env 'OKTA_ISSUER'
    auth_methods:
    - bearer
    audience_required:
    - !env 'OKTA_AUDIENCE'
    consumer_groups_claim:
    - groups
    consumer_optional: true
    consumer_groups_optional: false
    upstream_headers_claims:
    - sub
    - email
    upstream_headers_names:
    - X-Authenticated-User
    - X-User-Email
    ssl_verify: true
    hide_credentials: true
    cache_tokens_salt: !env 'OIDC_CACHE_TOKENS_SALT'
ai_gateway_policies:
- ref: claude-code-sso-standard-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-standard-ratelimit
  display_name: claude-code-sso standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
- ref: claude-code-sso-power-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-power-ratelimit
  display_name: claude-code-sso power tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_consumer_groups:
- ref: claude-standard-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-standard-users
  display_name: Claude Code standard tier
  policies:
  - claude-code-sso-standard-ratelimit
- ref: claude-power-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-power-users
  display_name: Claude Code power tier
  policies:
  - claude-code-sso-power-ratelimit
ai_gateway_models:
- ref: claude-code-sso-sonnet
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-sonnet
  display_name: claude-code-sso (sonnet tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-standard-users
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'SONNET_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: claude-code-sso-provider
    config:
      region: !env 'AWS_REGION'
      type: bedrock
- ref: claude-code-sso-opus
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-opus
  display_name: claude-code-sso (opus tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'OPUS_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: claude-code-sso-provider
    config:
      region: !env 'AWS_REGION'
      type: bedrock
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Azure AI Foundry" %}

These values use Sonnet 4.5 and Opus 4.5. The aliases are also the Foundry deployment names from the AI Credentials prerequisite, and `CHAT_MODEL_1` and `CHAT_MODEL_2` are the model names that Kong sends to Foundry.

Export the model values:

```bash
export SONNET_ALIAS='claude-sonnet-4-5'
export OPUS_ALIAS='claude-opus-4-5'
export CHAT_MODEL_1='claude-sonnet-4-5'
export CHAT_MODEL_2='claude-opus-4-5'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
ai_gateway_model_providers:
- ref: claude-code-sso-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-provider
  display_name: claude-code-sso
  type: azure
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'AZURE_FOUNDRY_TOKEN'}
    service: azure-foundry
    foundry:
      resource: !env 'AZURE_FOUNDRY_INSTANCE'
ai_gateway_auth_strategies:
- ref: claude-code-sso-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-auth
  display_name: claude-code-sso Okta OIDC
  type: openid-connect
  config:
    issuer: !env 'OKTA_ISSUER'
    auth_methods:
    - bearer
    audience_required:
    - !env 'OKTA_AUDIENCE'
    consumer_groups_claim:
    - groups
    consumer_optional: true
    consumer_groups_optional: false
    upstream_headers_claims:
    - sub
    - email
    upstream_headers_names:
    - X-Authenticated-User
    - X-User-Email
    ssl_verify: true
    hide_credentials: true
    cache_tokens_salt: !env 'OIDC_CACHE_TOKENS_SALT'
ai_gateway_policies:
- ref: claude-code-sso-standard-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-standard-ratelimit
  display_name: claude-code-sso standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
- ref: claude-code-sso-power-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-power-ratelimit
  display_name: claude-code-sso power tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_consumer_groups:
- ref: claude-standard-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-standard-users
  display_name: Claude Code standard tier
  policies:
  - claude-code-sso-standard-ratelimit
- ref: claude-power-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-power-users
  display_name: Claude Code power tier
  policies:
  - claude-code-sso-power-ratelimit
ai_gateway_models:
- ref: claude-code-sso-sonnet
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-sonnet
  display_name: claude-code-sso (sonnet tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-standard-users
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'SONNET_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: claude-code-sso-provider
    config:
      foundry_path_prefix: /anthropic/v1
      type: azure
- ref: claude-code-sso-opus
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-opus
  display_name: claude-code-sso (opus tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'OPUS_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: claude-code-sso-provider
    config:
      foundry_path_prefix: /anthropic/v1
      type: azure
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Google Vertex AI" %}

Vertex needs Claude model names with an `@<date>` suffix. Claude Code sends the bare alias, and Kong sends the dated name upstream.

Export the model values:

```bash
export SONNET_ALIAS='claude-sonnet-4-5'
export OPUS_ALIAS='claude-opus-4-5'
export CHAT_MODEL_1='claude-sonnet-4-5@20250929'
export CHAT_MODEL_2='claude-opus-4-5@20250929'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
ai_gateway_model_providers:
- ref: claude-code-sso-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-provider
  display_name: claude-code-sso
  type: gemini
  config:
    auth:
      type: gcp
      use_gcp_service_account: true
      service_account_json: !secret {source: !env 'VERTEX_SERVICE_ACCOUNT_JSON'}
ai_gateway_auth_strategies:
- ref: claude-code-sso-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-auth
  display_name: claude-code-sso Okta OIDC
  type: openid-connect
  config:
    issuer: !env 'OKTA_ISSUER'
    auth_methods:
    - bearer
    audience_required:
    - !env 'OKTA_AUDIENCE'
    consumer_groups_claim:
    - groups
    consumer_optional: true
    consumer_groups_optional: false
    upstream_headers_claims:
    - sub
    - email
    upstream_headers_names:
    - X-Authenticated-User
    - X-User-Email
    ssl_verify: true
    hide_credentials: true
    cache_tokens_salt: !env 'OIDC_CACHE_TOKENS_SALT'
ai_gateway_policies:
- ref: claude-code-sso-standard-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-standard-ratelimit
  display_name: claude-code-sso standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
- ref: claude-code-sso-power-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-power-ratelimit
  display_name: claude-code-sso power tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_consumer_groups:
- ref: claude-standard-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-standard-users
  display_name: Claude Code standard tier
  policies:
  - claude-code-sso-standard-ratelimit
- ref: claude-power-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-power-users
  display_name: Claude Code power tier
  policies:
  - claude-code-sso-power-ratelimit
ai_gateway_models:
- ref: claude-code-sso-sonnet
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-sonnet
  display_name: claude-code-sso (sonnet tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-standard-users
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'SONNET_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: claude-code-sso-provider
    config:
      gcp_environment:
        api_endpoint: !env 'VERTEX_API_ENDPOINT'
        project_id: !env 'VERTEX_PROJECT_ID'
        location_id: !env 'VERTEX_LOCATION_ID'
      type: gemini
- ref: claude-code-sso-opus
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-opus
  display_name: claude-code-sso (opus tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'OPUS_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: claude-code-sso-provider
    config:
      gcp_environment:
        api_endpoint: !env 'VERTEX_API_ENDPOINT'
        project_id: !env 'VERTEX_PROJECT_ID'
        location_id: !env 'VERTEX_LOCATION_ID'
      type: gemini
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Create the Claude Code Usage dashboard

The dashboard shows cost, token usage, request volume, model mix, usage for each developer (AI Consumer), and latency for Claude Code traffic. It's an organization-level resource, so the command reuses a dashboard with the `claude-code-sso-recipe` label if one exists.

Create the dashboard definition:

```bash
cat <<'EOF' > claude-code-usage-dashboard.json
{
  "name": "Claude Code Usage",
  "definition": {
    "tiles": [
      {
        "id": "e3f9588a-71fd-4996-818f-33c93afe6eae",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 2,
            "rows": 1
          },
          "position": {
            "col": 0,
            "row": 0
          }
        },
        "definition": {
          "chart": {
            "type": "single_value",
            "chart_title": "Total cost ($)"
          },
          "query": {
            "filters": [
              {
                "field": "ai_provider",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "cost"
            ],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "9edab295-d705-403f-a612-59847420a195",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 2,
            "rows": 1
          },
          "position": {
            "col": 2,
            "row": 0
          }
        },
        "definition": {
          "chart": {
            "type": "single_value",
            "chart_title": "Total Tokens"
          },
          "query": {
            "filters": [
              {
                "field": "ai_provider",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "total_tokens"
            ],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "e5cc504e-c505-4f0b-8633-638a0e7b5833",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 2,
            "rows": 1
          },
          "position": {
            "col": 4,
            "row": 0
          }
        },
        "definition": {
          "chart": {
            "type": "single_value",
            "chart_title": "Total Claude Code requests"
          },
          "query": {
            "filters": [
              {
                "field": "ai_provider",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "ai_request_count"
            ],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "4ab1fb73-d60b-4f77-b915-a0c88d427263",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 3,
            "rows": 2
          },
          "position": {
            "col": 0,
            "row": 1
          }
        },
        "definition": {
          "chart": {
            "type": "top_n",
            "chart_title": "Top Claude Models by Usage"
          },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": [
              "total_tokens",
              "ai_request_count"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "ai_request_model"
            ]
          }
        }
      },
      {
        "id": "e6c5fbe0-9dd2-46ac-af1c-3ba3af9ffd43",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 3,
            "rows": 2
          },
          "position": {
            "col": 3,
            "row": 1
          }
        },
        "definition": {
          "chart": {
            "type": "timeseries_line",
            "stacked": false,
            "chart_title": "Model usage trend (top 5)"
          },
          "query": {
            "limit": 5,
            "filters": [
              {
                "field": "ai_provider",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "total_tokens"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "ai_request_model",
              "time"
            ]
          }
        }
      },
      {
        "id": "fd14bf28-0cd2-409e-9a48-2cbbd7907409",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 2,
            "rows": 2
          },
          "position": {
            "col": 0,
            "row": 3
          }
        },
        "definition": {
          "chart": {
            "type": "donut",
            "chart_title": "Claude health check"
          },
          "query": {
            "filters": [
              {
                "field": "gateway_service",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "ai_request_count"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "status_code_grouped"
            ]
          }
        }
      },
      {
        "id": "f26edaa8-56d5-49f8-8f04-ade9451c76ec",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 2,
            "rows": 2
          },
          "position": {
            "col": 2,
            "row": 3
          }
        },
        "definition": {
          "chart": {
            "type": "donut",
            "chart_title": "Claude provider usage"
          },
          "query": {
            "filters": [
              {
                "field": "gateway_service",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "ai_request_count"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "ai_provider"
            ]
          }
        }
      },
      {
        "id": "d27037a3-7ace-49cc-affb-3b34a71ab9b1",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 2,
            "rows": 2
          },
          "position": {
            "col": 4,
            "row": 3
          }
        },
        "definition": {
          "chart": {
            "type": "timeseries_bar",
            "stacked": true,
            "chart_title": "LLM latency (avg)"
          },
          "query": {
            "filters": [
              {
                "field": "ai_request_model",
                "operator": "not_empty"
              },
              {
                "field": "ai_request_model",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "llm_latency_average"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "ai_request_model",
              "time"
            ]
          }
        }
      },
      {
        "id": "5f88c24b-80de-4fe1-8948-ef0bde29f948",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 3,
            "rows": 2
          },
          "position": {
            "col": 0,
            "row": 9
          }
        },
        "definition": {
          "chart": {
            "type": "horizontal_bar",
            "stacked": true,
            "chart_title": "Claude model usage (requests)"
          },
          "query": {
            "filters": [
              {
                "field": "ai_request_model",
                "operator": "not_empty"
              },
              {
                "field": "ai_request_model",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "ai_request_count"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "ai_request_model"
            ]
          }
        }
      },
      {
        "id": "702f6291-e02d-47eb-b38b-85438c643712",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 3,
            "rows": 2
          },
          "position": {
            "col": 3,
            "row": 9
          }
        },
        "definition": {
          "chart": {
            "type": "vertical_bar",
            "stacked": true,
            "chart_title": "Claude model usage count (tokens)"
          },
          "query": {
            "filters": [
              {
                "field": "ai_provider",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "total_tokens"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "ai_request_model"
            ]
          }
        }
      },
      {
        "id": "2242b427-2999-4cfe-b17e-9e4ca61be362",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 2,
            "rows": 2
          },
          "position": {
            "col": 0,
            "row": 11
          }
        },
        "definition": {
          "chart": {
            "type": "vertical_bar",
            "stacked": true,
            "chart_title": "AI security report"
          },
          "query": {
            "filters": [
              {
                "field": "status_code_grouped",
                "value": [
                  "4XX"
                ],
                "operator": "in"
              },
              {
                "field": "ai_provider",
                "operator": "not_empty"
              },
              {
                "field": "ai_provider",
                "value": [
                  "UNSPECIFIED"
                ],
                "operator": "not_in"
              }
            ],
            "metrics": [
              "ai_request_count"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "route",
              "status_code"
            ]
          }
        }
      },
      {
        "id": "df1b0486-2c04-430e-a8ff-7e26c7821bf7",
        "type": "chart",
        "layout": {
          "size": {
            "cols": 3,
            "rows": 2
          },
          "position": {
            "col": 2,
            "row": 11
          }
        },
        "definition": {
          "chart": {
            "type": "timeseries_bar",
            "stacked": true,
            "chart_title": "Monthly spend trends"
          },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": [
              "cost"
            ],
            "datasource": "llm_usage",
            "dimensions": [
              "ai_request_model",
              "time"
            ],
            "time_range": {
              "type": "relative",
              "time_range": "30d"
            },
            "granularity": "daily"
          }
        }
      }
    ],
    "template_id": "AI_GATEWAY",
    "preset_filters": [
      {
        "field": "gateway_service",
        "value": [],
        "operator": "in"
      }
    ]
  },
  "labels": {
    "recipe": "claude-code-sso-recipe"
  }
}
EOF
```
{:.collapsible}

Create the dashboard in {{site.konnect_short_name}}:

```bash
EXISTING_DASHBOARDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=claude-code-sso-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data | length')

if [ "${EXISTING_DASHBOARDS}" -gt 0 ]; then
  echo "Claude Code Usage dashboard already exists. Reusing."
else
  DASHBOARD_ID=$(kongctl api post /v2/dashboards \
    -f claude-code-usage-dashboard.json \
    --pat "${KONNECT_TOKEN}" -o json --jq '.id' -r)
  echo "Created Claude Code Usage dashboard (id: ${DASHBOARD_ID})."
fi
```
{: data-test-step="block" .collapsible }

{:.info}
> The dashboard shows Claude Code traffic for the whole organization. To show only this cookbook's {{site.ai_gateway}}, add a filter in the {{site.konnect_short_name}} dashboard editor.

### Connect Claude Code to Kong

Claude Code gets its credential from an [`apiKeyHelper`](https://code.claude.com/docs/en/settings-reference#apikeyhelper) script. Claude Code runs the script, then sends its output as both the `X-Api-Key` and `Authorization: Bearer` headers. The following script runs the OAuth Authorization Code flow with PKCE against Okta, caches the tokens in `~/.claude/okta-cache/`, and uses the refresh token to get a new access token before the cached one expires.

Save the script to `~/.claude/okta-claude-auth.sh` and make it executable:

```bash
cat <<'SCRIPT' > ~/.claude/okta-claude-auth.sh
#!/usr/bin/env bash
# okta-claude-auth.sh: apiKeyHelper for Claude Code + Okta PKCE
set -euo pipefail

OKTA_DOMAIN="${OKTA_DOMAIN:-"https://your-org.okta.com"}"
CLIENT_ID="${OKTA_CLIENT_ID:-"0oa1b2c3d4YourClientId"}"
REDIRECT_PORT="${OKTA_REDIRECT_PORT:-"9876"}"
REDIRECT_URI="http://localhost:${REDIRECT_PORT}/callback"
SCOPES="openid profile email offline_access"
AUDIENCE="${OKTA_AUDIENCE:-"api://default"}"
AUTH_SERVER="${OKTA_AUTH_SERVER:-"default"}"

CACHE_DIR="${HOME}/.claude/okta-cache"
TOKEN_CACHE="${CACHE_DIR}/tokens.json"
LOCK_FILE="${CACHE_DIR}/auth.lock"

log()  { echo "[okta-auth] $*" >&2; }
die()  { echo "[okta-auth] ERROR: $*" >&2; exit 1; }
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
random_str() { openssl rand -hex "${1:-32}"; }
json_get() { echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*: *"\([^"]*\)".*/\1/'; }
json_get_num() { echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*[0-9]*" | grep -o '[0-9]*$'; }

mkdir -p "$CACHE_DIR" && chmod 700 "$CACHE_DIR"

cache_read() { [[ -f "$TOKEN_CACHE" ]] && cat "$TOKEN_CACHE" || echo "{}"; }
cache_write() { echo "$1" > "$TOKEN_CACHE" && chmod 600 "$TOKEN_CACHE"; }

access_token_valid() {
  local cache exp now tok
  cache=$(cache_read)
  tok=$(json_get "$cache" "access_token")
  exp=$(json_get_num "$cache" "expires_at")
  now=$(date +%s)
  [[ -z "$tok" || -z "$exp" ]] && return 1
  (( now < exp - 60 )) && { echo "$tok"; return 0; }
  return 1
}

do_refresh() {
  local cache refresh_tok response new_access new_refresh expires_in expires_at now
  cache=$(cache_read)
  refresh_tok=$(json_get "$cache" "refresh_token")
  [[ -z "$refresh_tok" ]] && return 1
  log "Attempting silent refresh..."
  response=$(curl -sf -X POST "${OKTA_DOMAIN}/oauth2/${AUTH_SERVER}/v1/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=refresh_token&refresh_token=${refresh_tok}&client_id=${CLIENT_ID}&scope=${SCOPES// /%20}") || return 1
  new_access=$(json_get "$response" "access_token")
  new_refresh=$(json_get "$response" "refresh_token")
  expires_in=$(json_get_num "$response" "expires_in")
  [[ -z "$new_access" ]] && return 1
  now=$(date +%s); expires_at=$(( now + ${expires_in:-3600} ))
  cache_write "{\"access_token\":\"${new_access}\",\"refresh_token\":\"${new_refresh:-$refresh_tok}\",\"expires_at\":${expires_at}}"
  log "Token refreshed successfully."
  echo "$new_access"
}

start_callback_server() {
  local expected_state="$1"
  python3 - "$REDIRECT_PORT" "$expected_state" <<'PYEOF'
import sys, socket, urllib.parse
port, expected_state = int(sys.argv[1]), sys.argv[2]
HTML_OK = b"<html><body><h2>Authenticated! Close this tab.</h2><script>window.close();</script></body></html>"
HTML_ERR = b"<html><body><h2>Authentication failed.</h2></body></html>"
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(("127.0.0.1", port)); sock.listen(1); sock.settimeout(120)
try:
    conn, _ = sock.accept(); data = b""
    while b"\r\n\r\n" not in data:
        chunk = conn.recv(4096)
        if not chunk: break
        data += chunk
    path = data.decode(errors="replace").split(" ")[1] if b" " in data else "/"
    params = urllib.parse.parse_qs(urllib.parse.urlparse(path).query)
    code, state = params.get("code",[None])[0], params.get("state",[None])[0]
    error = params.get("error",[None])[0]
    ok = code and state == expected_state and not error
    conn.sendall(b"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n" + (HTML_OK if ok else HTML_ERR))
    conn.close()
    if not ok: sys.exit(1)
    print(code, end="")
except socket.timeout:
    sys.stderr.write("[okta-auth] Timed out waiting for callback.\n"); sys.exit(1)
finally: sock.close()
PYEOF
}

do_auth_code_flow() {
  local verifier challenge state auth_url code response access_tok refresh_tok expires_in expires_at now
  verifier=$(random_str 32)
  challenge=$(echo -n "$verifier" | openssl dgst -binary -sha256 | b64url)
  state=$(random_str 16)
  auth_url="${OKTA_DOMAIN}/oauth2/${AUTH_SERVER}/v1/authorize?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${SCOPES// /+}&audience=${AUDIENCE}&state=${state}&code_challenge=${challenge}&code_challenge_method=S256"
  log "Opening browser for Okta login..."
  log "If the browser doesn't open, visit: ${auth_url}"
  if command -v open >/dev/null 2>&1; then
    open "$auth_url" &
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$auth_url" >/dev/null 2>&1 &
  fi
  log "Waiting for callback on http://localhost:${REDIRECT_PORT}/callback ..."
  code=$(start_callback_server "$state")
  [[ -z "$code" ]] && die "No authorization code received."
  log "Authorization code received. Exchanging for tokens..."
  response=$(curl -sf -X POST "${OKTA_DOMAIN}/oauth2/${AUTH_SERVER}/v1/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=authorization_code&code=${code}&redirect_uri=${REDIRECT_URI}&client_id=${CLIENT_ID}&code_verifier=${verifier}") || die "Token exchange failed."
  access_tok=$(json_get "$response" "access_token")
  refresh_tok=$(json_get "$response" "refresh_token")
  expires_in=$(json_get_num "$response" "expires_in")
  [[ -z "$access_tok" ]] && die "No access_token in response."
  now=$(date +%s); expires_at=$(( now + ${expires_in:-3600} ))
  cache_write "{\"access_token\":\"${access_tok}\",\"refresh_token\":\"${refresh_tok}\",\"expires_at\":${expires_at}}"
  log "Authentication successful. Token cached."
  echo "$access_tok"
}

acquire_lock() {
  local waited=0
  while ! mkdir "$LOCK_FILE" 2>/dev/null; do
    sleep 0.5; (( waited++ ))
    (( waited > 30 )) && { log "Lock timeout, removing stale lock"; rm -rf "$LOCK_FILE"; }
  done
  trap 'rm -rf "$LOCK_FILE"' EXIT INT TERM
}

main() {
  acquire_lock
  tok=$(access_token_valid) && { echo "$tok"; exit 0; }
  tok=$(do_refresh 2>/dev/null) && { echo "$tok"; exit 0; }
  tok=$(do_auth_code_flow)
  echo "$tok"
}

main "$@"
SCRIPT
chmod +x ~/.claude/okta-claude-auth.sh
```
{:.collapsible}

Create or update `~/.claude/settings.json` with the tab for your provider. Replace `https://your-org.okta.com` and `0oa1b2c3d4YourClientId` with your Okta domain and the Client ID from the Okta prerequisite. Set `OKTA_AUTH_SERVER` to your server ID if you don't use the `default` server.

The Bedrock, Azure AI Foundry, and Vertex AI tabs set `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` to `1`. This removes Anthropic's pre-release `anthropic-beta` headers and beta request fields, which a non-Anthropic provider can reject with an `Extra inputs are not permitted` error ([Claude Code environment variables](https://code.claude.com/docs/en/env-vars)).

{% navtabs "Providers" %}
{% navtab "Anthropic" %}

```json
{
  "apiKeyHelper": "~/.claude/okta-claude-auth.sh",
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
    "OKTA_DOMAIN": "https://your-org.okta.com",
    "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
    "OKTA_AUDIENCE": "api://default",
    "OKTA_AUTH_SERVER": "default",
    "ANTHROPIC_MODEL": "claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7"
  }
}
```

{% endnavtab %}
{% navtab "AWS Bedrock" %}

```json
{
  "apiKeyHelper": "~/.claude/okta-claude-auth.sh",
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
    "OKTA_DOMAIN": "https://your-org.okta.com",
    "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
    "OKTA_AUDIENCE": "api://default",
    "OKTA_AUTH_SERVER": "default",
    "ANTHROPIC_MODEL": "claude-sonnet-4-5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-6",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
```

{% endnavtab %}
{% navtab "Azure AI Foundry" %}

```json
{
  "apiKeyHelper": "~/.claude/okta-claude-auth.sh",
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
    "OKTA_DOMAIN": "https://your-org.okta.com",
    "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
    "OKTA_AUDIENCE": "api://default",
    "OKTA_AUTH_SERVER": "default",
    "ANTHROPIC_MODEL": "claude-sonnet-4-5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-5",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
```

{% endnavtab %}
{% navtab "Google Vertex AI" %}

```json
{
  "apiKeyHelper": "~/.claude/okta-claude-auth.sh",
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
    "OKTA_DOMAIN": "https://your-org.okta.com",
    "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
    "OKTA_AUDIENCE": "api://default",
    "OKTA_AUTH_SERVER": "default",
    "ANTHROPIC_MODEL": "claude-sonnet-4-5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-5",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
```

{% endnavtab %}
{% endnavtabs %}

The `env` block sets these values:

* `ANTHROPIC_BASE_URL` sends Claude Code's requests to Kong.
* `OKTA_DOMAIN`, `OKTA_CLIENT_ID`, `OKTA_AUDIENCE`, and `OKTA_AUTH_SERVER` configure the helper script.
* `ANTHROPIC_MODEL` sets the model at session start, so the first request already uses a name that Kong knows.
* `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set the model names for `/model sonnet` and `/model opus`. They must match `SONNET_ALIAS` and `OPUS_ALIAS`. When you move a tier to a new model version, update the four values in the apply step and these three values together.

Claude Code caches the helper's output and runs the script again after five minutes, after a `401` or `403` response, and before a request if the cached JWT has expired ([`apiKeyHelper` reference](https://code.claude.com/docs/en/settings-reference#apikeyhelper)). If your Okta access tokens expire in less than five minutes and your Claude Code version doesn't check JWT expiry, set `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` in the `env` block to a shorter interval in milliseconds.

{:.warning}
> On Windows, Claude Code doesn't expand `~` in the `apiKeyHelper` path ([GitHub issue](https://github.com/anthropics/claude-code/issues/13013)). Use the absolute path, for example `C:\\Users\\you\\.claude\\okta-claude-auth.sh`.

### Launch Claude Code

Start Claude Code:

```bash
claude
```

The first time, or after the refresh token expires, a browser window opens for the Okta sign-in. After you sign in, the terminal continues:

```text
[okta-auth] Opening browser for Okta login...
[okta-auth] Waiting for callback on http://localhost:9876/callback ...
[okta-auth] Authorization code received. Exchanging for tokens...
[okta-auth] Authentication successful. Token cached.
```
{:.no-copy-code}

Ask Claude Code a question. Kong validates your Okta JWT, attaches the `claude-standard-users` AI Consumer Group, checks the AI Model's access control list, adds the provider credentials, and forwards the request. Later sessions reuse the cached token without opening the browser.

### Hit the tier enforcement boundary

Standard users can only use the sonnet AI Model. In Claude Code, switch to Opus and send a prompt:

```text
> /model opus
> Hello
```
{:.no-copy-code}

Claude Code sends the `OPUS_ALIAS` value as the model. Kong matches it to the opus AI Model, but that AI Model's access control list doesn't include `claude-standard-users`, so Kong rejects the request before any provider call. The expected status is `403 Forbidden`, which this cookbook hasn't confirmed against a live {{site.ai_gateway}}:

```text
API Error: 403 Forbidden
```
{:.no-copy-code}

Run `/model sonnet` and the requests succeed again.

### Hit the rate limit

The standard tier allows 20,000 tokens in a 60-second sliding window. Send three or four prompts in quick succession that each carry context, for example by asking Claude Code to summarize files in your repository. When the tier uses up its budget, Kong returns:

```text
API Error: 429 Too Many Requests
```
{:.no-copy-code}

The `X-AI-RateLimit-Retry-After` response header gives the number of seconds until the window allows requests again.

### Swap to the power tier

The `groups` claim decides the AI Consumer Group, so you change a user's tier in Okta. The `claude-power-users` AI Consumer Group, its AI Rate Limiting Advanced Policy, and the opus AI Model that allows it already exist.

1. In Okta, go to **Directory > Groups** and create `claude-power-users` if it doesn't exist.
1. Open your test user, click the **Groups** tab, remove `claude-standard-users`, and add `claude-power-users`.
1. Clear the helper script's cache, so that it doesn't reuse the old JWT with the old `groups` claim:

   ```bash
   rm -rf ~/.claude/okta-cache/
   ```

1. Start Claude Code again and sign in. The new JWT has `groups: ["claude-power-users"]`. Run `/model opus` and send a prompt. The request succeeds, and the budget is 100,000 tokens in a 60-second window.

To swap back, move the user to `claude-standard-users`, clear the cache, and sign in again.

### Check the results

The Claude Code sessions confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Okta authentication"
    evidence: "Claude Code works only after the Okta sign-in. Developers never hold a provider key."
  - behavior: "Tier enforcement"
    evidence: "A standard user gets an error for `/model opus` and succeeds with `/model sonnet`. A power user succeeds with both."
  - behavior: "Token budget for each tier"
    evidence: "A standard user gets `429 Too Many Requests` after about 20,000 tokens in a minute. A power user has 100,000."
  - behavior: "Tiers follow Okta groups"
    evidence: "Moving the user to another Okta group changes the tier after the next sign-in, with no Kong configuration change."
{% endtable %}

To review the created entities and usage by AI Consumer Group, open the `claude-code-sso-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu. The Claude Code Usage dashboard is in **{{site.observability}} > Dashboards**.

## How it works

Claude Code gets an Okta JWT from the helper script and sends it to Kong. Kong validates the JWT, maps the user's Okta groups to an AI Consumer Group, checks the access control list of the AI Model that matches the requested model, applies the tier's token budget, and forwards the request with the provider credentials.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CC as Claude Code
    participant H as apiKeyHelper script
    participant O as Okta
    participant K as Kong AI Gateway
    participant L as LLM Provider

    CC->>H: Request a credential
    activate H
    alt Cached token still valid
        H-->>CC: Cached JWT
    else Refresh or PKCE sign-in
        H->>O: Refresh token or browser sign-in
        activate O
        O-->>H: Access token (JWT) and refresh token
        deactivate O
        H-->>CC: New JWT
    end
    deactivate H

    CC->>K: POST /claude-code-sso (Authorization: Bearer JWT)
    activate K
    K->>K: OpenID Connect AI Auth Strategy validates the JWT (else 401)
    K->>K: Map Okta groups to an AI Consumer Group
    K->>K: AI Model access control list (else 403)
    K->>K: AI Rate Limiting Advanced Policy (else 429)
    K->>L: Request with the provider credentials
    activate L
    L-->>K: Response
    deactivate L
    K-->>CC: Anthropic-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

### OpenID Connect AI Auth Strategy

Authentication is an AI Auth Strategy, not an AI Policy. The OpenID Connect AI Auth Strategy validates each JWT against Okta's signing keys, rejects tokens that expired or were issued for another audience, and maps the values in the `groups` claim to AI Consumer Groups with the same names. The AI Consumer Group is the identity that the access control lists, rate limits, and analytics use.

The following settings configure the OpenID Connect AI Auth Strategy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`issuer`"
    purpose: "The Okta authorization server URL. Kong reads its OpenID Connect discovery document to find the signing keys, and caches the keys."
  - setting: "`auth_methods: [bearer]`"
    purpose: "Kong reads the JWT from the `Authorization: Bearer` header."
  - setting: "`audience_required`"
    purpose: "The JWT's `aud` claim must match `OKTA_AUDIENCE`, so tokens issued for other applications are rejected."
  - setting: "`consumer_groups_claim: [groups]`"
    purpose: "Kong maps each value in the `groups` claim to the AI Consumer Group with the same name."
  - setting: "`consumer_optional: true`"
    purpose: "Requests don't need an AI Consumer for each user. The AI Consumer Group is enough."
  - setting: "`consumer_groups_optional: false`"
    purpose: "Kong rejects an authenticated user whose groups match no AI Consumer Group, so an Okta user without a tier can't use Claude Code."
  - setting: "`upstream_headers_claims` and `upstream_headers_names`"
    purpose: "Kong sends the JWT's `sub` and `email` claims upstream as `X-Authenticated-User` and `X-User-Email`, for audit logs."
  - setting: "`ssl_verify: true`"
    purpose: "Kong verifies Okta's TLS certificate when it fetches the discovery document and the signing keys."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the JWT before it forwards the request. The provider only gets the AI Model Provider's credentials."
  - setting: "`cache_tokens_salt`"
    purpose: "A stable salt for the token cache keys, from `OIDC_CACHE_TOKENS_SALT`. In production, generate it with `openssl rand -hex 16` and store it in a secret manager."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Usage for each AI Consumer Group appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Models

The AI Model Provider holds the provider credentials. The two AI Models, `claude-code-sso-sonnet` and `claude-code-sso-opus`, share the `/claude-code-sso` path, and each one answers to one model name. Each AI Model requires the OpenID Connect AI Auth Strategy and has an access control list of AI Consumer Groups. Claude Code sends the alias, and Kong sends the target's upstream model to the provider, so developers keep the same alias when you change the upstream model.

The following settings configure the AI Model Provider and the AI Models:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The provider credentials. Kong adds them to each upstream request. The fields depend on the provider tab."
  - setting: "`formats: [{type: anthropic}]`"
    purpose: "The AI Model accepts Anthropic Messages API requests, which is the format Claude Code sends. Kong forwards the Anthropic format to each provider's Claude endpoint."
  - setting: "`access.auth_strategies`"
    purpose: "Each request must have a valid Okta JWT."
  - setting: "`access.acls.allow`"
    purpose: "The AI Consumer Groups that can use the AI Model. The sonnet AI Model allows both groups. The opus AI Model allows only `claude-power-users`. Kong rejects other groups before any provider call. The expected status is `403 Forbidden`, which this cookbook hasn't confirmed against a live {{site.ai_gateway}}."
  - setting: "`config.route.model`"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and selects the AI Model whose value matches: `SONNET_ALIAS` or `OPUS_ALIAS`. An AI Model accepts one value, so each tier needs its own AI Model."
  - setting: "`targets[].name`"
    purpose: "The upstream model, from `CHAT_MODEL_1` or `CHAT_MODEL_2`. For Anthropic it's the same name as the alias. For Bedrock it's a model ID such as `global.anthropic.claude-sonnet-4-5-20250929-v1:0`. Change it and re-apply to upgrade a tier."
  - setting: "`targets[].config`"
    purpose: "The provider `type` and provider-specific target fields, for example Bedrock's `region` or Azure AI Foundry's `foundry_path_prefix`."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default. Claude Code requests carry conversation history, tool results, and file contents."
  - setting: "`config.response_streaming: allow`"
    purpose: "Kong passes streamed responses to Claude Code, which streams its terminal output."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads for audits. The default is `false`."
{% endtable %}

{:.warning}
> Don't use `formats: [{type: openai}]` with Claude Code. Claude Code sends Anthropic tool definitions, and the translation to the OpenAI format breaks them, so the provider returns `400` errors (typically `tools: Input should be a valid list`).

### AI Rate Limiting Advanced Policy and AI Consumer Groups

Each AI Consumer Group lists its own AI Rate Limiting Advanced Policy in its `policies`. The policy counts prompt and completion tokens, the unit that drives LLM cost. The standard tier gets 20,000 tokens in a 60-second window, and the power tier gets 100,000. When a tier uses up its budget, Kong returns `429 Too Many Requests` until the window allows requests again.

The following settings configure the AI Consumer Groups and the AI Rate Limiting Advanced Policies:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`ai_gateway_consumer_groups[].policies`"
    purpose: "Attaches the policy to each request that Kong maps to the AI Consumer Group. To add a tier, add an AI Consumer Group with its own policy. This attachment hasn't been confirmed against a live {{site.ai_gateway}}."
  - setting: "`config.policies[].limits`"
    purpose: "The token limit and the window size in seconds: `20000` and `60` for the standard tier, `100000` and `60` for the power tier."
  - setting: "`window_type: sliding`"
    purpose: "A sliding window, for smoother limits than the `fixed` window."
  - setting: "`tokens_count_strategy: total_tokens`"
    purpose: "Counts prompt and completion tokens. Other values count only prompt tokens, only completion tokens, or cost."
  - setting: "`identifier: consumer-group`"
    purpose: "Counts usage for each AI Consumer Group, so the budget is shared by the tier."
  - setting: "`strategy: local`"
    purpose: "Keeps the counters in memory on each data plane node. For several nodes, use `redis` so that the nodes share the counters."
{% endtable %}

{:.info}
> The 60-second windows let a few prompts use up the budget in this cookbook. In production, most teams use daily or monthly budgets, for example {%raw%}`limits: [{limit: 5000000, window_size: 2592000}]`{%endraw%}. Store the credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) instead of environment variables.

### Response headers

Kong adds the following rate limit headers to each response:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-AI-RateLimit-Limit-minute-policy-1`"
    description: "The token limit for the 60-second window of the first entry in `config.policies`."
  - header: "`X-AI-RateLimit-Remaining-minute-policy-1`"
    description: "The tokens left in the current window."
  - header: "`X-AI-RateLimit-Reset`"
    description: "The seconds until the window resets."
  - header: "`X-AI-RateLimit-Retry-After`"
    description: "On a `429` response, the seconds until the tier can send requests again. There is no plain `Retry-After` header."
{% endtable %}

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Upgrade a tier's model"
    how: "Change `CHAT_MODEL_1` or `CHAT_MODEL_2` and re-apply. Developers keep sending the same alias. If the new model is a newer version, also update the aliases and each developer's settings, as the warning in [Apply the Kong configuration](#apply-the-kong-configuration) explains."
  - variation: "Change the token budgets"
    how: "Change `limits` in each AI Rate Limiting Advanced Policy, for example `limits: [{limit: 5000000, window_size: 2592000}]` for 5 million tokens a month. Add several `limits` entries to set a burst limit and a sustained limit in the same policy."
  - variation: "Share rate limit counters"
    how: "Set `strategy: redis` and point the policy at a shared Redis instance, so that all data plane nodes use the same counters."
  - variation: "Restrict access by IP address"
    how: "Add an [IP Restriction](/ai-gateway/policies/ip-restriction/) Policy with `allow` set to your egress ranges, for example your VPN and CI runners."
  - variation: "Add a tier"
    how: "Create an Okta group, an AI Consumer Group with the same name, an AI Rate Limiting Advanced Policy for it, and an AI Model that allows it. For example, an `intern` tier with only Haiku."
  - variation: "Use another identity provider"
    how: "Change `issuer` and the claim names on the OpenID Connect AI Auth Strategy for Microsoft Entra ID, Auth0, Keycloak, or another OpenID Connect provider. The helper script works with any provider that supports Authorization Code with PKCE. The AI Models and AI Consumer Groups don't change."
  - variation: "Distribute the helper script"
    how: "Ship `okta-claude-auth.sh` and the Claude Code settings through your internal tooling, for example a Homebrew tap, a package manager, or [Claude Code managed settings](https://code.claude.com/docs/en/settings), instead of having each developer copy the script from this page."
  - variation: "Support clients other than Claude Code"
    how: "For OpenAI-format clients and providers such as OpenAI, Gemini, or Mistral, use `formats: [{type: openai}]`, as in the [Basic LLM Routing cookbook](/cookbooks/basic-llm-routing/)."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

The Claude Code Usage dashboard is an organization-level resource that outlives the {{site.ai_gateway}}. Delete it first:

```bash
DASHBOARD_IDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=claude-code-sso-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data[].id' -r)

if [ -z "${DASHBOARD_IDS}" ]; then
  echo "No Claude Code Usage dashboard found. Skipping."
else
  for id in ${DASHBOARD_IDS}; do
    if kongctl api delete "/v2/dashboards/${id}" --pat "${KONNECT_TOKEN}"; then
      echo "Deleted Claude Code Usage dashboard ${id}."
    else
      echo "Failed to delete dashboard ${id}."
    fi
  done
fi
```
{: data-test-step="block" .collapsible }

Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the dashboard definition, the helper script, and the cached tokens:

```bash
rm -f claude-code-usage-dashboard.json
rm -f ~/.claude/okta-claude-auth.sh
rm -rf ~/.claude/okta-cache/
```

Revert `~/.claude/settings.json`. The following [jq](https://jqlang.org/) command removes only the keys this cookbook added and keeps everything else in the file:

```bash
tmp=$(mktemp) && jq '
  del(.apiKeyHelper)
  | del(
      .env.ANTHROPIC_BASE_URL,
      .env.OKTA_DOMAIN,
      .env.OKTA_CLIENT_ID,
      .env.OKTA_AUDIENCE,
      .env.OKTA_AUTH_SERVER,
      .env.ANTHROPIC_MODEL,
      .env.ANTHROPIC_DEFAULT_SONNET_MODEL,
      .env.ANTHROPIC_DEFAULT_OPUS_MODEL,
      .env.CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS
    )
  | if (.env // {}) == {} then del(.env) else . end
' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
```

If you unset `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` for this cookbook, export them again from your shell profile to return to your previous Claude Code authentication.

{:.info}
> **Subscription seat users (Pro, Max, Team, or Enterprise):** Claude Code attempts to fall back to your cached subscription credentials once `apiKeyHelper` is removed from `settings.json`. Run `claude /status` to confirm the session resumed, and run `claude /login` again if it didn't.
