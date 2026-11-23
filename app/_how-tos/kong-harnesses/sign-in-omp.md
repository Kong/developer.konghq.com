---
title: Sign in to omp with kong-harnesses
description: Create an AI Model and a kong-harnesses profile, sign in to {{ site.ai_gateway }} for omp, and validate your setup.

content_type: how_to
permalink: /kong-harnesses/sign-in/omp/
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
  q: How do I sign in to omp with kong-harnesses?
  a: |
    Send omp requests through {{site.ai_gateway}} with a short-lived Okta sign-in instead of a long-lived API key.
    Create an AI Model and a kong-harnesses profile, sign in, activate the profile, and validate the setup with `kong-harnesses doctor`.

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
  inline:
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: md/ai-gateway/v2/prereqs/anthropic
    - title: Okta
      icon_url: /assets/icons/okta.svg
      include_content: prereqs/auth/oidc/okta-kong-harnesses
    - title: omp
      content: |
        Install omp.
        On macOS, run:

        ```sh
        brew install can1357/tap/omp
        ```

        For other systems, see the [omp installation instructions](https://github.com/can1357/oh-my-pi#install).
        If your profile uses a loopback `http://` gateway and your shell sets a proxy, add the gateway host to `NO_PROXY` and `no_proxy` in the shell that starts omp.

cleanup:
  inline:
    - title: Clean up kong-harnesses
      content: |
        Remove the omp settings that kong-harnesses added, sign out, and delete the profile:

        ```sh
        kong-harnesses profile cleanup --client omp
        kong-harnesses logout --profile quickstart
        kong-harnesses profile delete quickstart
        ```

        `profile delete` asks you to type `quickstart` to confirm.
    - title: Clean up Okta
      include_content: kong-harnesses/cleanup-okta
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

omp reads its provider configuration from `~/.omp/agent/models.yml` and runs [`kong-harnesses token`](/kong-harnesses/token/) to get short-lived access tokens for {{ site.ai_gateway }}.
Because `token` never opens a browser, you sign in with `kong-harnesses login` before you start omp.

## Create the AI Model

{% include how-tos/steps/kong-harnesses-anthropic-model.md cli_name="omp" %}

## Create the kong-harnesses profile

Create a profile named `quickstart` with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
The gateway origin is `http://127.0.0.1:8000`, the address of the quickstart data plane.
kong-harnesses reads the endpoints of your Okta authorization server from its discovery document, saves the profile, and installs it on this computer:

```sh
kong-harnesses profile create \
  --name quickstart \
  --issuer "$ISSUER_URL" \
  --client-id "$OKTA_CLIENT_ID" \
  --audience api://default \
  --gateway-origin http://127.0.0.1:8000 \
  --model claude-sonnet-5-5
```

This guide sets up only omp, so you can ignore warnings about other agent CLIs.

## Sign in to the profile

{% include kong-harnesses/sign-in-login-steps.md cli_name="omp" profile="quickstart" %}

## Activate the profile

Configure omp to use the profile with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

```sh
kong-harnesses profile activate quickstart --client omp
```

## Validate

Confirm that your sign-in, gateway connection, and client configuration pass all checks:

{% validation custom-command %}
command: kong-harnesses doctor --profile quickstart --client omp
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Start omp and send a prompt to confirm that you receive a reply:

```sh
omp
```
