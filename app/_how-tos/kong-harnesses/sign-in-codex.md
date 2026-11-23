---
title: Sign in to Codex with kong-harnesses
description: Sign in to {{ site.ai_gateway }} for Codex with kong-harnesses, check status, replace or revoke credentials, and validate the connection.

content_type: how_to
permalink: /kong-harnesses/sign-in/codex/
breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/sign-in/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - ai
  - authentication
  - cli

automated_tests: false

tldr:
  q: How do I sign in to Codex with kong-harnesses?
  a: |
    Run `kong-harnesses login --profile PROFILE_NAME` before starting Codex, because `kong-harnesses token` doesn't open a browser.
    Check the sign-in with `kong-harnesses status --profile PROFILE_NAME --client codex`, validate with `kong-harnesses doctor --profile PROFILE_NAME --client codex`, and start `codex`.

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
  skip_product: true
  skip_tool: true
  inline:
    - title: Codex, kong-harnesses, and an HTTPS profile
      content: |
        Install [kong-harnesses](/kong-harnesses/) and Codex, and install an `https://` profile that configures `codex`.
        Codex requires an `https://` gateway that serves an OpenAI-format `POST /v1/responses` route.
        Configure an [AI Model](/ai-gateway/entities/ai-model/) with `capabilities: [agentic]`, `formats: [{ type: openai }]`, and `config.route.paths: ["/v1"]` targeting a Responses-capable provider such as OpenAI, Azure OpenAI, xAI, or Amazon Bedrock Mantle.
        kong-harnesses doesn't configure Codex for a plain `http://` gateway or a gateway without `POST /v1/responses`.
        Run `kong-harnesses profile list` to find your profile name, and replace `PROFILE_NAME` in each command with that name.
    - title: Activated Codex profile
      content: |
        Activate the profile for Codex if you haven't already:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client codex
        ```

        Run sign-in commands in an interactive terminal on your desktop so kong-harnesses can access your operating system's secret store.

cleanup:
  inline:
    - title: Sign out of Codex
      include_content: kong-harnesses/sign-in-cleanup
---

Codex reads its provider configuration from `~/.codex/config.toml` and runs [`kong-harnesses token`](/kong-harnesses/token/) to get short-lived access tokens for {{ site.ai_gateway }}.
Because `token` never opens a browser, you must sign in with `kong-harnesses login` before starting Codex.

## Sign in before starting Codex

{% include kong-harnesses/sign-in-token-cli-login.md cli_name="Codex" %}

## Check your sign-in status

Inspect the local sign-in and Codex setup without using the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client codex
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Ready`, and `Codex` shows `Configured`.
For every `Login` state and what to do when it isn't `Ready`, see [Check the sign-in](/kong-harnesses/sign-in/#check-the-sign-in).

### Replace a sign-in or diagnose a failure

{% include kong-harnesses/sign-in-replace-diagnose.md cli_name="Codex" %}

## Validate

Confirm that your sign-in, gateway route, and Codex configuration pass all checks:

1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for Codex:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client codex
   ```

   Confirm that `login`, `client`, `gateway`, and `route` report `ok`, and resolve any failures.
1. Start Codex and send a prompt to confirm you receive a reply:

   ```sh
   codex
   ```
