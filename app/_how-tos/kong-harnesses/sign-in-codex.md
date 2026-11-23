---
title: Sign in to Codex with kong-harnesses
description: Sign in to {{ site.ai_gateway }} for Codex using kong-harnesses, verify your sign-in, and start a session.

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
    Run `kong-harnesses login --profile PROFILE_NAME` before starting Codex, then verify with `kong-harnesses status --profile PROFILE_NAME --client codex` and `kong-harnesses doctor --profile PROFILE_NAME --client codex`.
    Start Codex with `codex -m MODEL_NAME` using a model name served by {{ site.ai_gateway }}.

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
    - title: Codex, kong-harnesses, and an HTTPS Responses profile
      content: |
        Install [kong-harnesses](/kong-harnesses/) and Codex, and install an `https://` profile that configures `codex`.
        Run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to find your profile name, and replace `PROFILE_NAME` in each command with that name.

        Your {{ site.ai_gateway }} must meet these requirements for Codex:

        * Expose an OpenAI-format `POST /v1/responses` route over `https://`.
          Configure an [AI Model](/ai-gateway/entities/ai-model/) with `capabilities: [agentic]`, `formats: [{ type: openai }]`, and `config.route.paths: ["/v1"]` targeting a Responses-capable provider such as OpenAI or Amazon Bedrock Mantle.
        * Avoid guardrail policies that force response buffering on the Responses model.
        * For static-key profiles, run {{ site.ai_gateway }} 2.4 or later so `key-auth` accepts `Authorization: Bearer` tokens.

        kong-harnesses skips Codex for a plain `http://` gateway or a gateway without `POST /v1/responses`.
    - title: Activated Codex profile
      content: |
        Activate the profile for Codex with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/) if you haven't already:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client codex
        ```

        Run sign-in commands in an interactive terminal on your desktop so kong-harnesses can access your operating system's secret store.

cleanup:
  inline:
    - title: Sign out of Codex
      include_content: kong-harnesses/sign-in-cleanup

faqs:
  - q: How do I replace a working Codex sign-in or diagnose a failure?
    a: |
      To switch accounts or rotate a saved static key for Codex, run `kong-harnesses login --profile PROFILE_NAME --replace` and type `PROFILE_NAME` to confirm.
      When the saved sign-in is missing or damaged, run `kong-harnesses login --profile PROFILE_NAME` without `--replace` instead (see [Sign in again](/kong-harnesses/sign-in/#sign-in-again)).
      To diagnose a failed sign-in without printing tokens or URLs, run `kong-harnesses login --profile PROFILE_NAME --diagnostics` and see [Sign-in errors in kong-harnesses](/kong-harnesses/sign-in/errors/).
  - q: What do I need to do on macOS after upgrading kong-harnesses?
    a: |
      Run `kong-harnesses login --profile PROFILE_NAME` once after each kong-harnesses upgrade on macOS.
      Each time Keychain asks whether kong-harnesses can use your sign-in, click **Always Allow**.
---

Codex reads its provider configuration from `~/.codex/config.toml` and runs [`kong-harnesses token`](/kong-harnesses/token/) to get short-lived access tokens for {{ site.ai_gateway }}.
Because `token` never opens a browser, sign in with `kong-harnesses login` before starting Codex.

## Sign in before starting Codex

{% include kong-harnesses/sign-in-login-steps.md cli_name="Codex" ci_note="true" %}

## Check your sign-in status

Check the local sign-in and Codex setup with [`kong-harnesses status`](/kong-harnesses/status/), which doesn't contact the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client codex
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Ready`, and `Codex` shows `Configured`.
For every `Login` state and what to do when it isn't `Ready`, see [Check the sign-in](/kong-harnesses/sign-in/#check-the-sign-in).

## Validate

Confirm that your sign-in, gateway connection, and Codex configuration pass all checks:

1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for Codex:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client codex
   ```

   Confirm that `login`, `client`, and `gateway` report `ok`, and resolve any failures.
1. Start Codex with a model name that {{ site.ai_gateway }} serves, replacing `MODEL_NAME` with that model name, and send a prompt to confirm you receive a reply:

   ```sh
   codex -m MODEL_NAME
   ```
