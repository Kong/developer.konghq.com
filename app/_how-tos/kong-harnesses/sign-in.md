---
title: Sign in with kong-harnesses
description: Sign in to a kong-harnesses profile, validate your setup, and sign out.

content_type: how_to
permalink: /kong-harnesses/sign-in/
breadcrumbs:
  - /kong-harnesses/

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
  - troubleshooting

automated_tests: false

min_version:
  ai-gateway: '2.4'

tldr:
  q: How do I sign in to a kong-harnesses profile and manage my sign-in?
  a: |
    Run `kong-harnesses login --profile PROFILE_NAME` in an interactive terminal to sign in, and validate with `kong-harnesses doctor --profile PROFILE_NAME`.
    Sign out with `kong-harnesses logout --profile PROFILE_NAME`.
    {% comment %}For OpenCode and Hermes Agent, follow each agent CLI's own guide instead.{% endcomment %}

related_resources:
  - text: Sign-in errors in kong-harnesses
    url: /kong-harnesses/sign-in/errors/
  - text: kong-harnesses login
    url: /kong-harnesses/login/
  - text: kong-harnesses logout
    url: /kong-harnesses/logout/
  - text: kong-harnesses status
    url: /kong-harnesses/status/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/

prereqs:
  inline:
    - title: A kong-harnesses profile
      content: |
        You need an installed profile that names your {{ site.ai_gateway }} and its model.
        To create one, follow [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/), or import one from your administrator with [`kong-harnesses profile import`](/kong-harnesses/profile/import/).
        Run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to find your profile name, and replace `PROFILE_NAME` in each command with that name.
    - title: Interactive desktop session
      content: |
        Run `login` and `logout` in an interactive terminal on your desktop, so kong-harnesses can read prompts and use your operating system's secret store.
        The secret store is:

        * Keychain on macOS
        * Secret Service on Linux, such as GNOME Keyring or KWallet
        * DPAPI on Windows

cleanup:
  inline:
    - title: Sign out
      include_content: kong-harnesses/sign-in-cleanup
---

[kong-harnesses](/kong-harnesses/) signs you in to {{ site.ai_gateway }}, stores the sign-in in your computer's secret store, and gives your agent CLI short-lived access tokens.
When an identity provider token is close to expiring, kong-harnesses renews it without opening your browser.

For end-to-end setup with {{ site.claude_code }}, follow [Sign in to {{ site.claude_code }}](/kong-harnesses/sign-in/claude-code/), or follow the sign-in workflow below with an existing profile.

{% comment %}
Choose your agent CLI guide for client-specific steps, or follow the shared kong-harnesses workflow:

{% table %}
columns:
  - title: Agent CLI
    key: cli
  - title: How it signs in
    key: method
  - title: Guide
    key: guide
rows:
  - cli: "{{ site.claude_code }}"
    method: Requires `kong-harnesses login` before first use.
    guide: "[Sign in to {{ site.claude_code }}](/kong-harnesses/sign-in/claude-code/)"
  - cli: Codex
    method: Requires `kong-harnesses login` before first use and an `https://` gateway serving `POST /v1/responses`.
    guide: "[Sign in to Codex](/kong-harnesses/sign-in/codex/)"
  - cli: OpenCode
    method: >-
      Uses the OpenCode plugin (`opencode auth login`).
      `kong-harnesses login` refuses `--client opencode`.
    guide: "[Sign in to OpenCode](/kong-harnesses/sign-in/opencode/)"
  - cli: Hermes Agent
    method: >-
      Uses the Hermes plugin (`hermes auth add kong-ai-gateway`).
      `kong-harnesses login` refuses `--client hermes`.
    guide: "[Sign in to Hermes Agent](/kong-harnesses/sign-in/hermes/)"
  - cli: omp
    method: Requires `kong-harnesses login` before first use.
    guide: "[Sign in to omp](/kong-harnesses/sign-in/omp/)"
  - cli: pi
    method: >-
      Requires `kong-harnesses login` before first use.
      Clear any saved `kong` entry from the pi `auth.json` first.
    guide: "[Sign in to pi](/kong-harnesses/sign-in/pi/)"
{% endtable %}
{% endcomment %}

## Sign in to a profile

{% include kong-harnesses/sign-in-login-steps.md cli_name="your agent CLI" %}

{:.info}
> **macOS:** Run `login` once after each kong-harnesses upgrade, because Keychain doesn't trust a new kong-harnesses build until you allow it.
> When Keychain asks whether kong-harnesses can use your sign-in, click **Always Allow**.

{:.info}
> **CI jobs:** A CI profile reads its key from `KONG_HARNESSES_STATIC_KEY` on each request, so `login` refuses it.
> Set `KONG_HARNESSES_STATIC_KEY` in the environment where your agent CLI starts instead.

## Validate

Confirm that your sign-in, gateway connection, and agent CLI configuration pass all checks using [`kong-harnesses doctor`](/kong-harnesses/doctor/):

{% validation custom-command %}
command: kong-harnesses doctor --profile PROFILE_NAME
expected:
  return_code: 0
render_output: false
{% endvalidation %}

If a check fails, see [Sign-in errors in kong-harnesses](/kong-harnesses/sign-in/errors/).
To check the saved sign-in without contacting the network, run [`kong-harnesses status`](/kong-harnesses/status/).
To replace a sign-in, run `login` with `--replace`, as described in [kong-harnesses login](/kong-harnesses/login/).
