---
title: Sign in to {{ site.claude_code }} with kong-harnesses
description: Create an AI Model and a kong-harnesses profile, sign in to {{ site.ai_gateway }} for {{ site.claude_code }}, and validate your setup.

content_type: how_to
permalink: /kong-harnesses/sign-in/claude-code/
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
  - anthropic
  - authentication
  - cli

automated_tests: false

min_version:
  ai-gateway: '2.4'

tldr:
  q: How do I sign in to {{ site.claude_code }} with kong-harnesses?
  a: |
    Send {{ site.claude_code }} requests through {{site.ai_gateway}} with a short-lived Okta sign-in instead of a long-lived API key.
    Create an AI Model and a kong-harnesses profile, sign in, activate the profile, and validate the setup with `kong-harnesses doctor`.

related_resources:
  - text: Sign in with kong-harnesses
    url: /kong-harnesses/sign-in/
  - text: Sign-in errors in kong-harnesses
    url: /kong-harnesses/sign-in/errors/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/

prereqs:
  inline:
    - title: Shells on Windows
      position: before
      content: |
        On Windows, run the gateway quickstart, the `export` commands and `kongctl` in Windows Subsystem for Linux (WSL).
        Run kong-harnesses and {{ site.claude_code }} in PowerShell.
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: md/ai-gateway/v2/prereqs/anthropic
    - title: Okta
      icon_url: /assets/icons/okta.svg
      include_content: prereqs/auth/oidc/okta-kong-harnesses
    - title: "{{ site.claude_code }}"
      icon_url: /assets/icons/third-party/claude.svg
      content: |
        Install {{ site.claude_code }} 2.1.278 or later.
        On macOS and Linux:

        ```sh
        curl -fsSL https://claude.ai/install.sh | bash
        ```

        On Windows, in PowerShell:

        ```powershell
        irm https://claude.ai/install.ps1 | iex
        ```

        Run `claude --version` to check the install.

cleanup:
  inline:
    - title: Clean up kong-harnesses
      content: |
        Remove the {{ site.claude_code }} settings that kong-harnesses added, sign out, and delete the profile:

        ```sh
        kong-harnesses profile cleanup --client claude-code
        kong-harnesses logout --profile quickstart
        kong-harnesses profile delete quickstart
        ```

        `profile delete` asks you to type `quickstart` to confirm.
    - title: Clean up Okta
      include_content: kong-harnesses/cleanup-okta
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

{{ site.claude_code }} gets short-lived access tokens from [`kong-harnesses credential`](/kong-harnesses/credential/), and kong-harnesses renews them without reopening your browser.

## Create the AI Model

{% include how-tos/steps/kong-harnesses-anthropic-model.md cli_name=site.claude_code %}

## Create the kong-harnesses profile

Create a profile named `quickstart` with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
The gateway origin is `http://127.0.0.1:8000`, the address of the quickstart data plane.
If you set a proxy with `HTTPS_PROXY`, `HTTP_PROXY` or `ALL_PROXY`, add `127.0.0.1` to `NO_PROXY` first, as described in [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/#create-the-kong-harnesses-profile).

{% navtabs "profile-create" %}
{% navtab "macOS and Linux" %}

```sh
kong-harnesses profile create \
  --name quickstart \
  --issuer "$ISSUER_URL" \
  --client-id "$OKTA_CLIENT_ID" \
  --audience api://default \
  --gateway-origin http://127.0.0.1:8000 \
  --model claude-sonnet-5-5
```

{% endnavtab %}
{% navtab "Windows" %}

Replace the placeholders with the values of `ISSUER_URL` and `OKTA_CLIENT_ID` from the prerequisites:

```powershell
kong-harnesses profile create --name quickstart --issuer 'YOUR_ISSUER_URL' --client-id 'YOUR_CLIENT_ID' --audience api://default --gateway-origin http://127.0.0.1:8000 --model claude-sonnet-5-5
```

{% endnavtab %}
{% endnavtabs %}

This guide sets up only {{ site.claude_code }}, so you can ignore warnings about other agent CLIs.

## Sign in to the profile

{% include kong-harnesses/sign-in-login-steps.md cli_name=site.claude_code profile="quickstart" %}

## Activate the profile

Configure {{ site.claude_code }} to use the profile with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

```sh
kong-harnesses profile activate quickstart --client claude-code
```

## Validate

Confirm that your sign-in, gateway connection, and {{ site.claude_code }} configuration pass all checks:

{% validation custom-command %}
command: kong-harnesses doctor --profile quickstart --client claude-code
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Start {{ site.claude_code }} and send a prompt to confirm that you receive a reply:

```sh
claude
```
