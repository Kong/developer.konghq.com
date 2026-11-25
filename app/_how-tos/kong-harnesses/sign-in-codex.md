---
title: Sign in to Codex with kong-harnesses
description: Create an AI Model and a kong-harnesses profile, sign in to {{ site.ai_gateway }} for Codex, and validate your setup.

content_type: how_to
published: false
permalink: /kong-harnesses/sign-in/codex/
breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/sign-in/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl
  - kong-harnesses

tags:
  - ai
  - authentication
  - cli

automated_tests: false

min_version:
  ai-gateway: '2.4'

tldr:
  q: How do I sign in to Codex with kong-harnesses?
  a: |
    Send Codex requests through {{site.ai_gateway}} to an OpenAI Responses model with a short-lived Okta sign-in instead of a long-lived API key.
    Create the AI Model and a kong-harnesses profile for an HTTPS gateway, sign in, activate the profile, and validate the setup with `kong-harnesses doctor`.

related_resources:
  - text: Sign in with kong-harnesses
    url: /kong-harnesses/sign-in/
  - text: Sign-in errors in kong-harnesses
    url: /kong-harnesses/sign-in/errors/
  - text: kong-harnesses token
    url: /kong-harnesses/token/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/

prereqs:
  konnect:
    - name: KONG_SSL_CERT
    - name: KONG_SSL_CERT_KEY
  inline:
    - title: OpenAI
      icon_url: /assets/icons/openai.svg
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
    - title: Okta
      icon_url: /assets/icons/okta.svg
      include_content: prereqs/auth/oidc/okta-kong-harnesses
    - title: A trusted certificate for the gateway
      position: before
      include_content: kong-harnesses/trusted-gateway-cert
    - title: Codex
      icon_url: /assets/icons/openai.svg
      content: |
        Install Node.js 18 or later, then install Codex:

        ```sh
        npm install -g @openai/codex
        ```

cleanup:
  inline:
    - title: Clean up kong-harnesses
      content: |
        Remove the Codex settings that kong-harnesses added, sign out, and delete the profile:

        ```sh
        kong-harnesses profile cleanup --client codex
        kong-harnesses logout --profile codex
        kong-harnesses profile delete codex
        ```

        `profile delete` asks you to type `codex` to confirm.
    - title: Clean up Okta
      include_content: kong-harnesses/cleanup-okta
    - title: Clean up the local certificate
      include_content: kong-harnesses/trusted-gateway-cert-cleanup
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

Codex reads its provider configuration from `~/.codex/config.toml` and runs [`kong-harnesses token`](/kong-harnesses/token/) to get short-lived access tokens for {{ site.ai_gateway }}.
Because `token` never opens a browser, you sign in with `kong-harnesses login` before you start Codex.

## Create the AI Model

Create the following entities:

* An `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that checks the Okta access token in the `Authorization` header.
* An [AI Model Provider](/ai-gateway/entities/ai-model-provider/) with your OpenAI key.
* An [AI Model](/ai-gateway/entities/ai-model/) that serves the OpenAI Responses API, which Codex uses.

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: okta-oidc
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Okta OIDC
    name: okta-oidc
    type: openid-connect
    config:
      issuer: !env ISSUER_URL
      audience_required:
        - api://default
      auth_methods:
        - bearer
      bearer_token_param_type:
        - header
      hide_credentials: true
      upstream_access_token_header: null
      cache_tokens_salt: okta-oidc-cache-salt
ai_gateway_model_providers:
  - ref: openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: OpenAI
    name: openai
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_models:
  - ref: gpt-5-4
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: gpt-5.4
    name: gpt-5.4
    type: model
    capabilities:
      - agentic
    formats:
      - type: openai
    targets:
      - name: gpt-5.4
        provider: openai
        config:
          type: openai
          upstream_url: https://api.openai.com/v1/responses
    access:
      auth_strategies:
        - !ref okta-oidc#name
    config:
      route:
        paths:
          - /v1
        model:
          body_param: model
          values:
            - gpt-5.4
{% endentity_examples %}

In this example:

* `capabilities: [agentic]` and `formats: [{ type: openai }]` serve the OpenAI-format `POST /v1/responses` route that Codex needs.
* `config.route.paths: [/v1]` puts the route at `/v1/responses`.
* When `upstream_access_token_header` is `null`, {{site.ai_gateway}} doesn't send the Okta access token to OpenAI and sends only your OpenAI key.

{:.warning}
> Do not attach guardrail policies that force response buffering to this AI Model.

## Create the kong-harnesses profile

Create a profile named `codex` with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
The gateway origin is the HTTPS port of the quickstart data plane, `https://localhost:8443`.
kong-harnesses reads the endpoints of your Okta authorization server from its discovery document, saves the profile, and installs it on this computer:

```sh
kong-harnesses profile create \
  --name codex \
  --issuer "$ISSUER_URL" \
  --client-id "$OKTA_CLIENT_ID" \
  --audience api://default \
  --gateway-origin https://localhost:8443 \
  --model gpt-5.4
```

## Sign in to the profile

{% include kong-harnesses/sign-in-login-steps.md cli_name="Codex" profile="codex" %}

## Activate the profile

Configure Codex to use the profile with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

```sh
kong-harnesses profile activate codex --client codex
```

## Validate

Confirm that your sign-in, gateway connection, and Codex configuration pass all checks:

{% validation custom-command %}
command: kong-harnesses doctor --profile codex --client codex
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Start Codex and send a prompt to confirm that you receive a reply:

```sh
codex -m gpt-5.4
```
