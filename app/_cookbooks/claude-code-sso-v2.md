---
title: Claude Code SSO
description: Authenticate Claude Code requests via Okta SSO with consumer-group-based model routing and per-tier rate limiting.
url: "/cookbooks/claude-code-sso-v2/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
  ai-gateway: '2.0'
categories:
  - access-control
  - llm
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - openid-connect
  - ai-model
  - ai-model-provider
  - ai-rate-limiting-advanced
requires_embeddings: false
providers:
  - anthropic
  - bedrock
  - azure-foundry
  - vertex
extra_services:
  - name: Okta
    env_vars: [OKTA_ISSUER, OKTA_AUDIENCE]
    hint: "Create a Native Application in Okta with PKCE flow and configure an API Authorization Server with a groups claim. See the Okta section in Prerequisites."

hint: "Requires an Okta organization with admin access and LLM provider credentials."

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

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The `-e` flags raise the data plane's nginx body buffer so Claude Code's large request payloads (full conversation context, tool definitions, file contents) stay in memory instead of spilling to disk:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=16m \
               -e KONG_NGINX_HTTP_CLIENT_MAX_BODY_SIZE=16m
           ```

           The script provisions an {{site.ai_gateway}} named `claude-code-sso-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl + jq
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration, plus [jq](https://jqlang.org/) for JSON processing in the dashboard and cleanup steps.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Install **jq** from [jqlang.org](https://jqlang.org/).

        Verify that both are installed:

        ```bash
        kongctl version
        jq --version
        ```
    - title: Okta
      icon_url: /assets/icons/okta.svg
      content: |
        This recipe requires an Okta organization with admin access. The following steps create one Native OIDC Application for Claude Code, enable refresh tokens, configure a `groups` claim on Okta's authorization server, and assign one test user to one group.

        **Create the Native Application**

        The Native Application is a public client representing Claude Code. Public clients use Authorization Code + PKCE without a client secret.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **OIDC - OpenID Connect** and **Native Application**, then click **Next**.
        1. Name the application `Claude Code`.
        1. Set the sign-in redirect URI to `http://localhost:9876/callback`. The helper script in [Connect Claude Code to Kong](#connect-claude-code-to-kong) listens on this local callback.
        1. On the application's **General** tab under **Client Credentials**, confirm that **Proof Key for Code Exchange (PKCE)** is checked. Okta enables it by default for Native app types.
        1. Under **General Settings → Grant type**, check **Refresh Token** (alongside the **Authorization Code** entry that's already enabled). Without the **Refresh Token** grant, Okta doesn't issue refresh tokens even when the helper script requests `offline_access`, and developers hit the browser PKCE flow on every token expiry.
        1. Copy the **Client ID**. You add it to the Claude Code settings in [Connect Claude Code to Kong](#connect-claude-code-to-kong).

        **Confirm the authorization server scopes**

        The helper script requests `openid`, `profile`, `email`, and `offline_access`. Okta's `default` authorization server enables these out of the box, so you usually don't need to change anything.

        1. Go to **Security → API → Authorization Servers** and select the `default` server (or your custom server).
        1. Click the **Scopes** tab and confirm that `openid`, `profile`, `email`, and `offline_access` are listed and enabled. If `offline_access` is missing, add it. Without `offline_access`, Okta never issues refresh tokens.

        **Configure the groups claim**

        The OpenID Connect AI Auth Strategy reads the `groups` claim out of the access token and maps each value to an AI Consumer Group with the same name. Configure the authorization server to include the claim:

        1. On the same authorization server, click the **Claims** tab and add a new claim:
           - **Name:** `groups`
           - **Include in token type:** Access Token
           - **Value type:** Groups
           - **Filter:** Matches regex `.*` (or restrict to a prefix like `claude-`)

        **Set up an Okta group and a test user**

        Create one group and assign one user to start. The Kong configuration includes both `claude-standard-users` and `claude-power-users` AI Consumer Groups, but you only need to test one tier at a time and can swap the user between groups later to exercise the other tier:

        1. Go to **Directory → Groups** and create `claude-standard-users`.
        1. Go to **Directory → People** and either add a new person (for example, `claude-test-user@example.com`) or pick an existing user. Make sure the user has a password set and can sign in.
        1. Open the user, click the **Groups** tab, and assign them to `claude-standard-users`.
        1. Open the `Claude Code` application, click the **Assignments** tab, and assign the same user. Without this, Okta blocks the OAuth flow at sign-in.

        To exercise the power tier later, also create a `claude-power-users` group. The [Swap to the power tier](#swap-to-the-power-tier) section walks through swapping the user between groups to switch tiers.

        **Export Okta endpoints and audience**

        You configure the audience on the authorization server itself, not per request. View or edit it at **Security → API → Authorization Servers → [server] → Settings tab → Audience**. The built-in `default` server uses `api://default`.

        Export the issuer, the audience, and a salt for the OpenID Connect AI Auth Strategy's token cache. The salt isn't a credential, but it must stay the same across applies:

        ```bash
        export OKTA_ISSUER='https://your-org.okta.com/oauth2/default'
        export OKTA_AUDIENCE='api://default'
        export OIDC_CACHE_TOKENS_SALT='claude-code-sso-dev-salt'
        ```

        If you use a custom authorization server, set `OKTA_ISSUER` to that server's issuer URL and `OKTA_AUDIENCE` to its configured audience value.
    - title: Claude Code
      content: |
        This cookbook connects Claude Code to Kong in [Connect Claude Code to Kong](#connect-claude-code-to-kong). Install it first:

        1. Install Claude Code from [docs.claude.com/en/docs/claude-code/setup](https://docs.claude.com/en/docs/claude-code/setup).
        1. Verify installation:

           ```bash
           claude --version
           ```

        {:.warning}
        > **Claude Code bypasses `apiKeyHelper` if `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` is set in your environment.** Both env vars take precedence over the helper per Claude Code's [credential precedence rules](https://code.claude.com/docs/en/iam). If either is set in your shell profile, unset it before running Claude Code with this recipe: `unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN`.
    - title: AI Credentials
      content: |
        {% navtabs "Providers" %}
        {% navtab "Anthropic" %}
        This tutorial uses Anthropic:

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export environment variables for the API key and the [Messages API schema version](https://docs.claude.com/en/api/versioning) Kong should send upstream on every request:

           ```bash
           export ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export ANTHROPIC_VERSION='2023-06-01'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Export environment variables with your AWS credentials:

           ```bash
           export AWS_ACCESS_KEY_ID='your-access-key'
           export AWS_SECRET_ACCESS_KEY='your-secret-key'
           export AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure AI Foundry" %}
        This tutorial uses [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/), which hosts Claude at `https://<resource>.services.ai.azure.com/anthropic/v1/messages`.

        1. Ensure you have a Foundry project with Claude Sonnet 4.5 and Claude Opus 4.5 deployments. The deployment names you assigned in the portal become `AZURE_FOUNDRY_DEPLOYMENT_ID_1` and `_2`.
        1. Export environment variables. `AZURE_FOUNDRY_UPSTREAM_URL` is the full endpoint URL Kong calls. `AZURE_FOUNDRY_TOKEN` accepts either a Foundry API key or an [Entra ID](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry) bearer token; the AI Model Provider forwards it verbatim, so include the `Bearer ` prefix yourself if your token requires it:

           ```bash
           export AZURE_FOUNDRY_INSTANCE='your-foundry-resource'
           export AZURE_FOUNDRY_UPSTREAM_URL="https://${AZURE_FOUNDRY_INSTANCE}.services.ai.azure.com/anthropic/v1/messages"
           export AZURE_FOUNDRY_DEPLOYMENT_ID_1='your-sonnet-deployment'
           export AZURE_FOUNDRY_DEPLOYMENT_ID_2='your-opus-deployment'
           export AZURE_FOUNDRY_TOKEN='your-foundry-token'
           ```
        {% endnavtab %}
        {% navtab "Google Vertex AI" %}
        This tutorial uses [Google Vertex AI Model Garden](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-claude), which hosts Claude on Google Cloud.

        1. Ensure your GCP project has the Vertex AI API enabled, Claude Sonnet 4.5 and Claude Opus 4.5 access granted in AI Model Garden, and a service account JSON key with `roles/aiplatform.user`.
        1. Export environment variables. `VERTEX_LOCATION_ID` accepts `global` (works for every Claude variant) or a regional endpoint like `us-east5`, `europe-west1`, or `asia-southeast1`:

           ```bash
           export VERTEX_PROJECT_ID='your-gcp-project-id'
           export VERTEX_LOCATION_ID='global'
           export VERTEX_API_ENDPOINT='aiplatform.googleapis.com'
           export VERTEX_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json)"
           ```

           Service account JSON is one of the GCP IAM auth modes the AI Model Provider supports for Vertex. For production, prefer workload identity over a downloaded key.
        {% endnavtab %}
        {% endnavtabs %}
overview: |
  Route Claude Code through {{site.ai_gateway_name}} so that every request is tied to a developer's
  Okta identity. You'll set up:

  * Okta SSO for Claude Code, with no provider API key on developer machines
  * Two model tiers based on Okta groups: standard users can use Sonnet, and power users can use Sonnet and Opus
  * A token budget for each tier
  * A {{site.konnect_short_name}} dashboard for Claude Code cost and usage

  The provider can be Anthropic, AWS Bedrock, Azure AI Foundry, or Google Vertex AI.

  This cookbook covers Claude Code's API key path, which Claude Code uses with `apiKeyHelper`,
  `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or cloud provider credentials. Claude.ai subscription
  seats that sign in with `claude /login` connect directly to Anthropic and aren't covered.
---

## What this cookbook solves

Anthropic Console API keys and cloud provider credentials control Claude Code access per key, not per developer, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Teams share one Console API key or AWS access key through shell profiles, `.env` files, or CI secrets. Requests can't be traced to a developer, and a leaked key means rotating it on every machine."
    solution: "Kong holds the provider credentials in an AI Model Provider. Developers authenticate with their own Okta token, which an `apiKeyHelper` script fetches for Claude Code."
  - problem: "API keys aren't connected to Okta. A developer removed from an Okta group or disabled in Okta can keep using a cached key."
    solution: "An OpenID Connect AI Auth Strategy validates the Okta token's signature, expiry, and audience on every request. When Okta stops issuing tokens to a user, their access ends when the current token expires."
  - problem: "Every developer with a key can use every model."
    solution: "Kong maps Okta groups to AI Consumer Groups. Each tier is an AI Model with an ACL, so standard users get `403` when they request Opus, before any provider call."
  - problem: "Cost controls only happen after the fact, through billing alerts."
    solution: "An AI Rate Limiting Advanced Policy on each AI Consumer Group sets a token budget per tier. Kong returns `429` when a tier uses its budget."
{% endtable %}


## Try it out

Apply the Kong configuration, connect Claude Code to Kong, then use Claude Code to check authentication, tier enforcement, and rate limiting.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your provider's credentials, an OpenID Connect AI Auth Strategy for Okta, two AI Consumer Groups (`claude-standard-users` and `claude-power-users`) that each have an AI Rate Limiting Advanced Policy, and two AI Models for the sonnet and opus tiers. A kongctl namespace scopes every resource, so cleanup only removes this cookbook's configuration.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Select your provider. In each tab, `SONNET_ALIAS` and `OPUS_ALIAS` are the model names that Claude Code sends for the standard and power tiers, and `CHAT_MODEL_1` and `CHAT_MODEL_2` are the upstream models that Kong uses for them. The other variables, including `AI_GATEWAY_ID`, the Okta variables, and your provider credentials, come from the prerequisites.

{:.warning}
> The alias values must match `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` in each developer's `~/.claude/settings.json`, and the models must exist in your provider account. Claude Code uses the alias to decide which features to enable, such as effort levels, extended thinking, and beta tool fields. If the alias names a newer model than the upstream, for example `claude-sonnet-4-6` for an upstream Sonnet 4.5, the upstream rejects the extra fields with `400`.

{% navtabs "Providers" %}
{% navtab "Anthropic" %}

Export your environment variables:

```bash
export SONNET_ALIAS='claude-sonnet-4-6'
export OPUS_ALIAS='claude-opus-4-7'
export CHAT_MODEL_1='claude-sonnet-4-6'
export CHAT_MODEL_2='claude-opus-4-7'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export your environment variables. These values use Sonnet 4.5 and Opus 4.6, the stable versions on Bedrock. If your account has different versions enabled, update the aliases and the upstream model IDs to match:

```bash
export SONNET_ALIAS='claude-sonnet-4-5'
export OPUS_ALIAS='claude-opus-4-6'
export CHAT_MODEL_1='global.anthropic.claude-sonnet-4-5-20250929-v1:0'
export CHAT_MODEL_2='global.anthropic.claude-opus-4-6-20250930-v1:0'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Azure AI Foundry" %}

Export your environment variables. These values use Sonnet 4.5 and Opus 4.5, the stable Claude versions in the Foundry model catalog. The alias values are also the Foundry deployment names from the **AI Credentials** prerequisite, and `CHAT_MODEL_1` and `CHAT_MODEL_2` are the model names Kong sends to Foundry in the request body:

```bash
export SONNET_ALIAS='claude-sonnet-4-5'
export OPUS_ALIAS='claude-opus-4-5'
export CHAT_MODEL_1='claude-sonnet-4-5'
export CHAT_MODEL_2='claude-opus-4-5'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Google Vertex AI" %}

Export your environment variables. Vertex requires Claude model names with the `@<date>` suffix for the model variant. Claude Code sends the bare alias, and Kong replaces it with the dated upstream name:

```bash
export SONNET_ALIAS='claude-sonnet-4-5'
export OPUS_ALIAS='claude-opus-4-5'
export CHAT_MODEL_1='claude-sonnet-4-5@20250929'
export CHAT_MODEL_2='claude-opus-4-5@20250929'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Connect Claude Code to Kong

Claude Code gets its credential from an [`apiKeyHelper`](https://docs.claude.com/en/docs/claude-code/settings) script. The following script signs the developer in to Okta with Authorization Code + PKCE, caches the token, and refreshes it silently. Save it to `~/.claude/okta-claude-auth.sh` and make it executable:

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

{:.info}
> For a production rollout, distribute `okta-claude-auth.sh` through your internal tooling (a Homebrew tap, package manager, or setup script) rather than having every developer copy this script.

Create or update `~/.claude/settings.json`, using the tab for your provider:

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

Replace `https://your-org.okta.com` and `0oa1b2c3d4YourClientId` with the values from your Okta application. If you use a custom authorization server, set `OKTA_AUTH_SERVER` to its ID. The three `ANTHROPIC_*_MODEL` values must match `SONNET_ALIAS` and `OPUS_ALIAS` from [Apply the Kong configuration](#apply-the-kong-configuration). For what each setting does, see [Claude Code and the apiKeyHelper script](#claude-code-and-the-apikeyhelper-script).

{:.warning}
> On Windows, Claude Code does not expand `~` in the `apiKeyHelper` field (see the [GitHub issue on tilde expansion](https://github.com/anthropics/claude-code/issues/13013)). Substitute the absolute path, for example `C:\\Users\\you\\.claude\\okta-claude-auth.sh`. Tilde expansion works on macOS and Linux.

### Launch Claude Code

```bash
claude
```

On the first invocation (or when the cached token expires), a browser window opens to Okta for authentication. After authenticating, the terminal continues automatically:

```text
[okta-auth] Opening browser for Okta login...
[okta-auth] Waiting for callback on http://localhost:9876/callback ...
[okta-auth] Authorization code received. Exchanging for tokens...
[okta-auth] Authentication successful. Token cached.

╭─────────────────────────────────╮
│ ✻  Welcome to Claude Code!      │
╰─────────────────────────────────╯
```
{:.no-copy-code}

Ask a question. Kong validates your Okta token, attaches the matching AI Consumer Group, checks the AI Model's ACL, injects the provider credentials, and forwards the request to the upstream model.

Subsequent invocations reuse the cached token silently. The browser flow only reappears after the refresh token expires.

### Hit the tier enforcement boundary

Standard users have access only to the sonnet AI Model. Inside Claude Code, switch to Opus and send a prompt:

```text
> /model opus
> Hello
```
{:.no-copy-code}

Claude Code sends the configured Opus alias (whatever value you set as `ANTHROPIC_DEFAULT_OPUS_MODEL`) in the request body. Kong matches the alias to the opus AI Model, but that Model's access control list doesn't include `claude-standard-users`, so Kong rejects the request before any provider call:

```text
API Error: 403 Forbidden
```
{:.no-copy-code}

This is the explicit block: a standard user can't use Opus, regardless of what Claude Code's UI offers, and they see exactly why. Switch back to Sonnet (`/model sonnet`) and the request succeeds again.

### Hit the rate limit

The standard tier allows 20,000 tokens per 60-second sliding window. A few interactive prompts that include conversation history and file context exhaust the budget quickly. Send three or four prompts in rapid succession that each carry meaningful context (for example, ask Claude Code to summarize a file in your repo). When you exhaust the budget, Kong returns:

```text
API Error: 429 Too Many Requests
```
{:.no-copy-code}

The response includes a `Retry-After` header indicating how many seconds remain in the window.

### Swap to the power tier

The IdP-issued `groups` claim drives the AI Consumer Group attachment, so changing the user's Okta group is all you need to switch tiers. Kong already has the `claude-power-users` AI Consumer Group, the opus AI Model that allows it, and its own AI Rate Limiting Advanced Policy in place from the apply step.

1. In Okta, go to **Directory → Groups** and create `claude-power-users` if it doesn't already exist.
1. Open your test user, click the **Groups** tab, remove `claude-standard-users`, and add `claude-power-users`.
1. Force a fresh token by clearing the helper script's cache so it doesn't silently reuse the old JWT (which still carries the previous `groups` claim):

   ```bash
   rm -rf ~/.claude/okta-cache/
   ```

1. Re-launch Claude Code. The browser opens for a fresh PKCE flow, the new JWT carries `groups: ["claude-power-users"]`, and Kong now attaches the request to the power-tier AI Consumer Group. Run `/model opus` followed by a prompt; the request succeeds. The token budget jumps to 100,000 per 60-second window.

Swap back the same way: move the user between groups in Okta, clear the cache, and re-authenticate.

### Review usage in {{site.konnect_short_name}}

Create a Claude Code Usage dashboard at the organization level. It shows cost, token usage, request volume, model mix, per-developer usage, and latency for Claude Code traffic.

Save the dashboard definition as `claude-code-usage-dashboard.json` in your working directory:

```json
{
  "name": "Claude Code Usage",
  "definition": {
    "tiles": [
      {
        "id": "e3f9588a-71fd-4996-818f-33c93afe6eae",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 0, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total cost ($)" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["cost"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "9edab295-d705-403f-a612-59847420a195",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 2, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total Tokens" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "e5cc504e-c505-4f0b-8633-638a0e7b5833",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 4, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total Claude Code requests" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "4ab1fb73-d60b-4f77-b915-a0c88d427263",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 0, "row": 1 } },
        "definition": {
          "chart": { "type": "top_n", "chart_title": "Top Claude Models by Usage" },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": ["total_tokens", "ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model"]
          }
        }
      },
      {
        "id": "e6c5fbe0-9dd2-46ac-af1c-3ba3af9ffd43",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 3, "row": 1 } },
        "definition": {
          "chart": { "type": "timeseries_line", "stacked": false, "chart_title": "Model usage trend (top 5)" },
          "query": {
            "limit": 5,
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"]
          }
        }
      },
      {
        "id": "fd14bf28-0cd2-409e-9a48-2cbbd7907409",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 0, "row": 3 } },
        "definition": {
          "chart": { "type": "donut", "chart_title": "Claude health check" },
          "query": {
            "filters": [
              { "field": "gateway_service", "operator": "not_empty" },
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["status_code_grouped"]
          }
        }
      },
      {
        "id": "f26edaa8-56d5-49f8-8f04-ade9451c76ec",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 2, "row": 3 } },
        "definition": {
          "chart": { "type": "donut", "chart_title": "Claude provider usage" },
          "query": {
            "filters": [
              { "field": "gateway_service", "operator": "not_empty" },
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_provider"]
          }
        }
      },
      {
        "id": "d27037a3-7ace-49cc-affb-3b34a71ab9b1",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 4, "row": 3 } },
        "definition": {
          "chart": { "type": "timeseries_bar", "stacked": true, "chart_title": "LLM latency (avg)" },
          "query": {
            "filters": [
              { "field": "ai_request_model", "operator": "not_empty" },
              { "field": "ai_request_model", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["llm_latency_average"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"]
          }
        }
      },
      {
        "id": "5f88c24b-80de-4fe1-8948-ef0bde29f948",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 0, "row": 9 } },
        "definition": {
          "chart": { "type": "horizontal_bar", "stacked": true, "chart_title": "Claude model usage (requests)" },
          "query": {
            "filters": [
              { "field": "ai_request_model", "operator": "not_empty" },
              { "field": "ai_request_model", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model"]
          }
        }
      },
      {
        "id": "702f6291-e02d-47eb-b38b-85438c643712",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 3, "row": 9 } },
        "definition": {
          "chart": { "type": "vertical_bar", "stacked": true, "chart_title": "Claude model usage count (tokens)" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model"]
          }
        }
      },
      {
        "id": "2242b427-2999-4cfe-b17e-9e4ca61be362",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 0, "row": 11 } },
        "definition": {
          "chart": { "type": "vertical_bar", "stacked": true, "chart_title": "AI security report" },
          "query": {
            "filters": [
              { "field": "status_code_grouped", "value": ["4XX"], "operator": "in" },
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["route", "status_code"]
          }
        }
      },
      {
        "id": "df1b0486-2c04-430e-a8ff-7e26c7821bf7",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 2, "row": 11 } },
        "definition": {
          "chart": { "type": "timeseries_bar", "stacked": true, "chart_title": "Monthly spend trends" },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": ["cost"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"],
            "time_range": { "type": "relative", "time_range": "30d" },
            "granularity": "daily"
          }
        }
      }
    ],
    "template_id": "AI_GATEWAY"
  },
  "labels": {
    "recipe": "claude-code-sso-recipe"
  }
}
```
{:.collapsible}

Create the dashboard. If a dashboard with this cookbook's label already exists, the command reuses it:

```bash
EXISTING_DASHBOARDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=claude-code-sso-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data | length')

if [ "${EXISTING_DASHBOARDS}" -gt 0 ]; then
  echo "Claude Code Usage dashboard already exists. Reusing."
else
  DASHBOARD_ID=$(kongctl api post /v2/dashboards \
    -f claude-code-usage-dashboard.json \
    --pat "${KONNECT_TOKEN}" -o json --jq '.id' -r)
  echo "Created Claude Code Usage dashboard (id: ${DASHBOARD_ID}). Open it in Konnect at Observability → Custom dashboards → 'Claude Code Usage'."
fi
```
{: data-test-step="block" .collapsible }

In {{site.konnect_short_name}}, go to **Observability → Custom dashboards → Claude Code Usage**. The dashboard shows cost, total tokens, request count, model mix and trend, health and provider breakdowns, average latency, and a security report of `4XX` responses.

{:.info}
> This dashboard shows account-wide Claude Code traffic by default. To scope it to just this recipe's {{site.ai_gateway}}, add a filter in the {{site.konnect_short_name}} dashboard editor after you apply the recipe configuration.

To review the entities this cookbook created, open the `claude-code-sso-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/).


## How it works

Claude Code gets an Okta token from the `apiKeyHelper` script and sends it to Kong. Kong validates the token, maps the developer's Okta groups to an AI Consumer Group, checks the requested AI Model's ACL, applies the tier's token budget, and forwards the request with the provider's credentials:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CC as Claude Code
    participant H as apiKeyHelper script
    participant O as Okta
    participant K as Kong Gateway
    participant L as LLM Provider

    CC->>H: Request bearer token
    activate H
    alt Cached token still valid
        H-->>CC: Cached JWT
    else Refresh or PKCE flow
        H->>O: PKCE flow (browser)
        activate O
        O-->>H: JWT (id_token + refresh_token)
        deactivate O
        H-->>CC: Fresh JWT
    end
    deactivate H

    CC->>K: POST /claude-code-sso (Authorization: Bearer JWT)
    activate K
    K->>K: OpenID Connect Auth Strategy (JWKS validate, Okta group to Kong Consumer Group)
    K->>K: AI Model (alias match, Consumer Group ACL check)
    K->>K: AI Model Provider (inject provider key)
    K->>K: AI Rate Limiting Advanced (per-tier token budget, via Consumer Group)
    K->>L: Forwarded request
    activate L
    L-->>K: Provider response
    deactivate L
    K-->>CC: Anthropic-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Claude Code and the apiKeyHelper script

Claude Code runs `okta-claude-auth.sh` every 5 minutes by default and immediately after any `401`, then sends the script's output as `Authorization: Bearer <token>`. The script returns the cached access token while it's valid, uses the refresh token when the access token is within 60 seconds of expiry, and only opens the browser when it has no usable refresh token. It stores tokens in `~/.claude/okta-cache/tokens.json`. With Okta's default 1-hour access token lifetime, developers only see the browser when they first sign in.

Claude Code runs `apiKeyHelper` without your shell profile, so the `env` block in `~/.claude/settings.json` must list every variable the script reads:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`apiKeyHelper`"
    purpose: "The path to the script that Claude Code runs to get a credential."
  - setting: "`ANTHROPIC_BASE_URL`"
    purpose: "Sends Claude Code requests to Kong at `/claude-code-sso` instead of to Anthropic."
  - setting: "`OKTA_DOMAIN`, `OKTA_CLIENT_ID`, `OKTA_AUDIENCE`, `OKTA_AUTH_SERVER`"
    purpose: "The Okta values the script uses to sign in. `OKTA_AUTH_SERVER` defaults to `default`."
  - setting: "`ANTHROPIC_MODEL`"
    purpose: "The model Claude Code uses from the start of the session. Without it, Claude Code sends the placeholder `<default>`, which matches no AI Model in Kong."
  - setting: "`ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`"
    purpose: "The model names Claude Code sends after `/model sonnet` or `/model opus`. They must match the AI Model aliases in Kong."
  - setting: "`CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` (Bedrock, Azure AI Foundry, Vertex AI)"
    purpose: "Removes Anthropic beta headers and beta tool fields, such as `context_management` and `output_config.effort`, from requests. Some non-Anthropic providers reject these fields with errors like `400 Extra inputs are not permitted`. Keep it unless you've confirmed that your provider accepts them."
  - setting: "`CLAUDE_CODE_API_KEY_HELPER_TTL_MS` (optional)"
    purpose: "How long Claude Code reuses the script's output. If Okta issues short-lived access tokens, for example 2 minutes, set it lower, such as `\"60000\"`, so Claude Code runs the script before each token expires. It doesn't change how quickly Kong detects revoked access."
{% endtable %}

### OpenID Connect AI Auth Strategy

The OpenID Connect AI Auth Strategy validates every Okta token and maps the developer's Okta groups to AI Consumer Groups. That mapping decides which AI Models the request can use and which token budget applies.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`issuer`"
    purpose: "The Okta authorization server URL. Kong discovers the JWKS endpoint and signing keys from `/.well-known/openid-configuration` and caches the keys."
  - setting: "`auth_methods: [bearer]`"
    purpose: "Reads the token from the `Authorization` header as a bearer token, which is how Claude Code sends the `apiKeyHelper` output."
  - setting: "`audience_required`"
    purpose: "Rejects tokens whose `aud` claim doesn't match, such as tokens issued for other Okta applications."
  - setting: "`consumer_groups_claim: [groups]`"
    purpose: "Maps each value in the token's `groups` claim to the AI Consumer Group with the same name."
  - setting: "`consumer_optional: true`"
    purpose: "Allows requests without a per-user AI Consumer. This cookbook only uses AI Consumer Groups."
  - setting: "`consumer_groups_optional: false`"
    purpose: "Rejects users whose groups match no AI Consumer Group, so an Okta user without a tier can't use the gateway."
  - setting: "`upstream_headers_claims`, `upstream_headers_names`"
    purpose: "Send the `sub` and `email` claims upstream as `X-Authenticated-User` and `X-User-Email`, for audit logging."
  - setting: "`ssl_verify: true`, `hide_credentials: true`"
    purpose: "Verify Okta's TLS certificate, and remove the Okta token before forwarding the request. Both default to `true` in {{site.base_gateway}} 3.14 and later. The cookbook sets them explicitly."
  - setting: "`cache_tokens_salt`"
    purpose: "A required salt for the token cache key. It must stay the same so that cached entries survive `kongctl apply`. It isn't a credential, but for production, generate one with `openssl rand -hex 16` and store it in a vault."
{% endtable %}

### AI Models and AI Model Provider

Each tier is an AI Model on the `/claude-code-sso` path. Kong selects the AI Model whose alias matches the request's `model` field. Both AI Models use one AI Model Provider, which holds the provider credentials. On each AI Model, `access.auth_strategies` requires a valid Okta token, and `access.acls` limits which AI Consumer Groups can use it.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`formats: [{type: anthropic}]`"
    purpose: "Accepts the Anthropic Messages format that Claude Code sends. Kong forwards the same format to each provider's Claude endpoint."
  - setting: "`access.auth_strategies`"
    purpose: "References the OpenID Connect AI Auth Strategy, so every request needs a valid Okta token."
  - setting: "`access.acls.allow`"
    purpose: "The AI Consumer Groups that can use the AI Model. The sonnet AI Model allows both tiers, and the opus AI Model only allows `claude-power-users`. Kong rejects other groups with `403 Forbidden` before calling the provider."
  - setting: "`config.route.model`"
    purpose: "The alias the AI Model answers to. An AI Model accepts one alias, so each tier needs its own AI Model."
  - setting: "`targets[].name`"
    purpose: "The upstream model ID, for example `claude-sonnet-4-6` for Anthropic or a full Bedrock model ID. To upgrade a model without changes on developer machines, change `CHAT_MODEL_1` or `CHAT_MODEL_2` and re-apply."
  - setting: "`targets[].config`"
    purpose: "Provider-specific settings, such as `region` for Bedrock or `foundry_path_prefix` for Azure AI Foundry."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Allows requests up to 10 MB. Claude Code requests often include 100 KB or more of conversation history, tool results, and file contents, which the default limit rejects."
  - setting: "`config.response_streaming: allow`"
    purpose: "Returns streamed responses (Server-Sent Events) to Claude Code for interactive output."
  - setting: "`config.logging.payloads: true`"
    purpose: "Logs request and response bodies for auditing. {{site.konnect_short_name}} tracks token usage and cost without this setting."
{% endtable %}

{:.warning}
> Don't use `formats: [{type: openai}]` with Claude Code. Claude Code sends Anthropic-native tool definitions, and the OpenAI format translation breaks them. The provider then returns `400` errors, typically `tools: Input should be a valid list`.

### AI Consumer Groups and AI Rate Limiting Advanced

Each AI Consumer Group lists its own AI Rate Limiting Advanced Policy in `policies`. The policy counts tokens instead of requests, because tokens are what LLM usage costs. The standard tier gets 20,000 tokens per 60-second window, and the power tier gets 100,000.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`ai_gateway_consumer_groups[].policies`"
    purpose: "Applies the policy to every request mapped to the AI Consumer Group. The group references the policy, so adding a tier means adding a group with its own `policies` list."
  - setting: "`config.policies[].limits`"
    purpose: "Pairs of token limit and window size in seconds. An optional `match` array can target specific providers or models, but each tier has its own policy here, so the cookbook doesn't use it."
  - setting: "`window_type: sliding`"
    purpose: "Counts tokens over a sliding window for smoother limiting. The `fixed` and `calendar` types reset all counters at each window boundary."
  - setting: "`tokens_count_strategy: total_tokens`"
    purpose: "Counts prompt and completion tokens. The alternatives are `prompt_tokens`, `completion_tokens`, and `cost`."
  - setting: "`identifier: consumer-group`"
    purpose: "Tracks usage per AI Consumer Group, so each tier shares one budget. A user can belong to several groups, so the policy needs to know which counter to use."
  - setting: "`strategy: local`"
    purpose: "Keeps counters in memory on each data plane node, which suits a single node."
{% endtable %}

When a tier uses its budget, Kong returns `429 Too Many Requests` with a `Retry-After` header. Kong adds the following headers to every response:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-AI-RateLimit-Limit-{window}-{provider}`"
    description: "Maximum tokens allowed in the window."
  - header: "`X-AI-RateLimit-Remaining-{window}-{provider}`"
    description: "Tokens remaining in the current window."
  - header: "`RateLimit-Reset`"
    description: "Seconds until the window resets."
{% endtable %}

The 60-second windows are short so that you can reach the limit in a few prompts. For production budgets, see [Variations and next steps](#variations-and-next-steps).


## Variations and next steps

* **Switch the underlying model:** Change `CHAT_MODEL_1` or `CHAT_MODEL_2` and re-apply. Developers don't need to change anything, because the aliases they send stay the same. If you also change `SONNET_ALIAS` or `OPUS_ALIAS`, developers must update the three `ANTHROPIC_*_MODEL` values in `~/.claude/settings.json`.
* **Add more tiers:** Create an Okta group, an AI Consumer Group with the same name and its own AI Rate Limiting Advanced Policy, and an AI Model whose ACL allows the new group. For example, an `intern` tier with only Haiku, or an `ml-team` tier with a specialized model.
* **Set production token budgets:** Most teams use daily or monthly windows, for example `limits: [{limit: 5000000, window_size: 2592000}]` for 5 million tokens per month. Add several `limits` entries to enforce both burst and sustained budgets.
* **Share rate limit counters with Redis:** For clusters with several data plane nodes, set `strategy: redis` and point it at a shared Redis instance so that all nodes use the same counters.
* **Store credentials in AI Vaults:** Reference the provider credentials and the cache salt from a secret manager with [AI Vaults](/ai-gateway/entities/ai-vault/) instead of environment variables.
* **Restrict access by IP:** Add an [IP Restriction](/ai-gateway/policies/ip-restriction/) Policy that only allows your egress ranges, such as the corporate VPN and CI runners. It runs before token validation.
* **Use a different IdP:** The OpenID Connect AI Auth Strategy works with any OIDC-compliant identity provider, such as Microsoft Entra ID, Auth0, Keycloak, or PingIdentity. Update `issuer` and the claim names to match your IdP's tokens. The helper script works with any provider that supports Authorization Code + PKCE.
* **Cover non-Claude clients:** This cookbook uses `formats: [{type: anthropic}]` because Claude Code sends Anthropic-format requests. For OpenAI, Google Gemini, Mistral, and other providers, see [Basic LLM Routing](/cookbooks/basic-llm-routing/), which uses `formats: [{type: openai}]`.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

Delete the **Claude Code Usage** custom dashboard. The dashboard is an org-level resource and outlives the {{site.ai_gateway}}, so remove it before tearing down Kong:

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

Remove the helper script and cached tokens:

```bash
rm -f ~/.claude/okta-claude-auth.sh
rm -rf ~/.claude/okta-cache/
```

Revert `~/.claude/settings.json`. The following [jq](https://jqlang.github.io/jq/) command removes only the keys this recipe added and preserves anything else you have in the file:

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

If you previously ran `unset ANTHROPIC_API_KEY` or `unset ANTHROPIC_AUTH_TOKEN` to use this recipe, re-export those values from your shell profile to return to your prior Claude Code authentication setup.

{:.info}
> **Subscription seat users (Pro, Max, Team, or Enterprise):** Claude Code attempts to fall back to your cached subscription credentials once `apiKeyHelper` is removed from `settings.json`. Run `claude /status` to confirm the session resumed, and run `claude /login` again if it didn't.
