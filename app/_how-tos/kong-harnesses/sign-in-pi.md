---
title: Sign in to pi with kong-harnesses
description: Create an AI Model and a kong-harnesses profile, clear any saved kong key in pi, sign in to {{ site.ai_gateway }} for pi, and validate your setup.

content_type: how_to
permalink: /kong-harnesses/sign-in/pi/
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
  q: How do I sign in to pi with kong-harnesses?
  a: |
    Send pi requests through {{site.ai_gateway}} with a short-lived Okta sign-in instead of a long-lived API key.
    Remove any saved `kong` entry from the pi `auth.json` first, because pi sends a saved key instead of a kong-harnesses token.
    Then create an AI Model and a kong-harnesses profile, sign in, activate the profile, and validate the setup with `kong-harnesses doctor`.

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
    - title: pi
      content: |
        Install [Node.js](https://nodejs.org/), then install pi:

        ```sh
        npm install -g @earendil-works/pi-coding-agent
        ```

        If your profile uses a loopback `http://` gateway and your shell sets a proxy, add the gateway host to `NO_PROXY` and `no_proxy` in the shell that starts pi.

cleanup:
  inline:
    - title: Clean up kong-harnesses
      content: |
        Remove the pi settings that kong-harnesses added, sign out, and delete the profile:

        ```sh
        kong-harnesses profile cleanup --client pi
        kong-harnesses logout --profile quickstart
        kong-harnesses profile delete quickstart
        ```

        `profile delete` asks you to type `quickstart` to confirm.
    - title: Clean up Okta
      include_content: kong-harnesses/cleanup-okta
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

pi reads its provider configuration from `~/.pi/agent/models.json` and runs [`kong-harnesses token`](/kong-harnesses/token/) on every request to get a short-lived access token for {{ site.ai_gateway }}.
Because `token` never opens a browser, you sign in with `kong-harnesses login` before you start pi.

## Create the AI Model

{% include how-tos/steps/kong-harnesses-anthropic-model.md cli_name="pi" %}

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

This guide sets up only pi, so you can ignore warnings about other agent CLIs.

## Clear any saved kong key in pi

If you previously saved a key for the `kong` provider with `/login` in pi, pi sends that key instead of calling `kong-harnesses token`.
Open `auth.json` in pi's agent directory, which is `~/.pi/agent/auth.json` by default, and remove the `kong` entry if it exists.

## Sign in to the profile

{% include kong-harnesses/sign-in-login-steps.md cli_name="pi" profile="quickstart" %}

## Activate the profile

Configure pi to use the profile with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

```sh
kong-harnesses profile activate quickstart --client pi
```

## Validate

Confirm that your sign-in, gateway connection, and client configuration pass all checks:

{% validation custom-command %}
command: kong-harnesses doctor --profile quickstart --client pi
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Start pi and send a prompt to confirm that you receive a reply:

```sh
pi
```
