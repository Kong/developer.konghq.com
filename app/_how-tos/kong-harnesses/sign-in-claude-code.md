---
title: Sign in to {{ site.claude_code }} with kong-harnesses
description: Sign in to {{ site.ai_gateway }} for {{ site.claude_code }} with kong-harnesses, check status, replace or revoke credentials, and validate the session.

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
  - kong-harnesses

tags:
  - ai
  - anthropic
  - authentication
  - cli

automated_tests: false

tldr:
  q: How do I sign in to {{ site.claude_code }} with kong-harnesses?
  a: |
    Run `kong-harnesses login --profile PROFILE_NAME` and check your state with `kong-harnesses status --profile PROFILE_NAME --client claude-code`.
    Then validate with `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` and start `claude`.
    For an identity provider profile, {{ site.claude_code }} can also open your browser automatically on its first request.

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
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{ site.claude_code }} and kong-harnesses"
      content: |
        Install [kong-harnesses](/kong-harnesses/) and {{ site.claude_code }}, and install a profile that configures `claude-code`.
        If you haven't set up {{ site.claude_code }} yet, follow [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).
        Run `kong-harnesses profile list` to find your profile name, and replace `PROFILE_NAME` in each command with that name.
    - title: Activated {{ site.claude_code }} profile
      content: |
        Activate {{ site.claude_code }} for the profile if your organization doesn't deploy managed settings:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client claude-code
        ```

        Run sign-in commands in an interactive terminal on your desktop so kong-harnesses can access your operating system's secret store.

cleanup:
  inline:
    - title: Sign out of {{ site.claude_code }}
      content: |
        Remove the saved sign-in or static key and any saved gateway MCP server keys for the profile using [`kong-harnesses logout`](/kong-harnesses/logout/):

        ```sh
        kong-harnesses logout --profile PROFILE_NAME
        ```

        Type `PROFILE_NAME` when prompted to confirm, or pass `--auto-approve` to confirm in advance.
        An already-running {{ site.claude_code }} session can keep using a cached access token until that token expires.
        For what `logout` revokes across identity provider, static-key, and CI profiles, see [Sign out](/kong-harnesses/sign-in/#sign-out).
---

{{ site.claude_code }} gets short-lived access tokens from [`kong-harnesses credential`](/kong-harnesses/credential/), and kong-harnesses renews them automatically without reopening your browser.
For an identity provider profile, {{ site.claude_code }} can start your first browser sign-in automatically when it requests its first token, or you can sign in ahead of time with `kong-harnesses login`.

## Sign in to your profile

Sign in to your profile in an interactive terminal before starting {{ site.claude_code }}.
You must run `login` first for static-key profiles, Claude subscription profiles, and profiles with key-authenticated gateway MCP servers.

1. Run [`kong-harnesses login`](/kong-harnesses/login/) for your profile:

   ```sh
   kong-harnesses login --profile PROFILE_NAME
   ```

   For an identity provider profile, kong-harnesses opens your browser at the identity provider's sign-in page and prints the sign-in URL in the terminal.
   Open that URL in a browser on the same computer so the callback reaches kong-harnesses.
   To print the URL without opening a browser automatically, add `--no-browser`.

   For a static-key profile, `login` prompts for the key from your administrator and hides your input as you type or paste it.
1. If your profile lists gateway MCP servers that take a key, enter each key when `login` prompts for it.
   When the profile already has a usable sign-in, `login` keeps it and asks only for missing gateway MCP server keys.
1. Follow the command in the `Next` field and restart {{ site.claude_code }} if it's already running.

{:.info}
> **Claude subscriptions and CI jobs:**
>
> * **Claude subscription profile:** After `kong-harnesses login --profile PROFILE_NAME` signs you in for your gateway identity, start `claude` and run `/login` inside {{ site.claude_code }} to sign in to your Claude subscription.
> * **CI job profile:** A CI profile reads its key from `KONG_HARNESSES_STATIC_KEY` on every request, so `login` refuses it.
>   Set `KONG_HARNESSES_STATIC_KEY` in the environment where {{ site.claude_code }} starts instead.

On macOS, run `kong-harnesses login --profile PROFILE_NAME` once after each upgrade of kong-harnesses.
Each time Keychain asks whether kong-harnesses can use your sign-in or a gateway MCP server key, click **Always Allow**.

## Check your sign-in status

Inspect the local sign-in and {{ site.claude_code }} setup without using the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client claude-code
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Ready`, and `Claude` shows `Configured`.
For every `Login` state and what to do when it isn't `Ready`, see [Check the sign-in](/kong-harnesses/sign-in/#check-the-sign-in).

### Replace a sign-in or diagnose a failure

{% include kong-harnesses/sign-in-replace-diagnose.md cli_name=site.claude_code %}

## Validate

Confirm that your sign-in, gateway route, and {{ site.claude_code }} settings pass all checks:

1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for {{ site.claude_code }}:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client claude-code
   ```

   Confirm that `login`, `client`, and `gateway` report `ok`, and resolve any failures.
1. Optionally test a live model request through {{ site.ai_gateway }}:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client claude-code --inference
   ```

   This check sends the prompt `"Reply with OK."` with at most 16 output tokens and can incur model usage cost.
1. Start {{ site.claude_code }} and send a prompt to confirm you receive a reply:

   ```sh
   claude
   ```
