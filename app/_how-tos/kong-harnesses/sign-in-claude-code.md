---
title: Sign in to {{ site.claude_code }} with kong-harnesses
description: Sign in to {{ site.ai_gateway }} for {{ site.claude_code }} using kong-harnesses, verify your sign-in, and start a session.

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
        Run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to find your profile name, and replace `PROFILE_NAME` in each command with that name.
    - title: Activated {{ site.claude_code }} profile
      content: |
        Activate {{ site.claude_code }} for the profile with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/) if your organization doesn't deploy managed settings:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client claude-code
        ```

        Run sign-in commands in an interactive terminal on your desktop so kong-harnesses can access your operating system's secret store.

cleanup:
  inline:
    - title: Sign out of {{ site.claude_code }}
      include_content: kong-harnesses/sign-in-cleanup

faqs:
  - q: How do I replace a working {{ site.claude_code }} sign-in or diagnose a failure?
    a: |
      To switch accounts or rotate a saved static key for {{ site.claude_code }}, run `kong-harnesses login --profile PROFILE_NAME --replace` and type `PROFILE_NAME` to confirm.
      When the saved sign-in is missing or damaged, run `kong-harnesses login --profile PROFILE_NAME` without `--replace` instead (see [Sign in again](/kong-harnesses/sign-in/#sign-in-again)).
      To diagnose a failed sign-in without printing tokens or URLs, run `kong-harnesses login --profile PROFILE_NAME --diagnostics` and see [Sign-in errors in kong-harnesses](/kong-harnesses/sign-in/errors/).
  - q: What do I need to do on macOS after upgrading kong-harnesses?
    a: |
      Run `kong-harnesses login --profile PROFILE_NAME` once after each kong-harnesses upgrade on macOS.
      Each time Keychain asks whether kong-harnesses can use your sign-in or a gateway MCP server key, click **Always Allow**.
---

{{ site.claude_code }} gets short-lived access tokens from [`kong-harnesses credential`](/kong-harnesses/credential/), and kong-harnesses renews them automatically without reopening your browser.
You must run `login` first for static-key profiles, Claude subscription profiles, and profiles with key-authenticated gateway MCP servers.

## Sign in to your profile

{% include kong-harnesses/sign-in-login-steps.md cli_name=site.claude_code ci_note="true" %}

{:.info}
> **Claude subscription profiles:** After `kong-harnesses login --profile PROFILE_NAME` signs you in for your gateway identity, start `claude` and run `/login` inside {{ site.claude_code }} to sign in to your Claude subscription.

## Check your sign-in status

Check the local sign-in and {{ site.claude_code }} setup with [`kong-harnesses status`](/kong-harnesses/status/), which doesn't contact the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client claude-code
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Ready`, and `Claude` shows `Configured`.
For every `Login` state and what to do when it isn't `Ready`, see [Check the sign-in](/kong-harnesses/sign-in/#check-the-sign-in).

## Validate

Confirm that your sign-in, gateway route, and {{ site.claude_code }} settings pass all checks:

1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for {{ site.claude_code }}:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client claude-code
   ```

   Confirm that `login`, `client`, and `gateway` report `ok`, and resolve any failures.
1. Start {{ site.claude_code }} and send a prompt to confirm you receive a reply:

   ```sh
   claude
   ```

{:.info}
> To test a live model request from `doctor` before starting `claude`, run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code --inference`.
> That probe sends `"Reply with OK."` with at most 16 output tokens and can incur model usage cost.
