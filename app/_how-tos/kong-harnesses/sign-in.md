---
title: Sign in with kong-harnesses
description: Sign in to a kong-harnesses profile, check or replace the sign-in, sign out, and diagnose sign-in failures.

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

tldr:
  q: How do I sign in to a kong-harnesses profile and manage my sign-in?
  a: |
    Run `kong-harnesses login --profile PROFILE_NAME` in an interactive terminal to sign in and `kong-harnesses status --profile PROFILE_NAME` to check your state.
    Use `kong-harnesses login --profile PROFILE_NAME --replace` to replace an active sign-in and `kong-harnesses logout --profile PROFILE_NAME` to sign out.
    For OpenCode and Hermes Agent, follow each agent CLI's own guide instead.

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
  skip_product: true
  skip_tool: true
  inline:
    - title: Installed kong-harnesses and a profile
      content: |
        Install [kong-harnesses](/kong-harnesses/) and import or create a profile with [`kong-harnesses setup`](/kong-harnesses/setup/) or [`kong-harnesses profile import`](/kong-harnesses/profile/import/).
        Run `kong-harnesses profile list` to find your profile name, and replace `PROFILE_NAME` in each command with that name.
    - title: Interactive desktop session
      content: |
        Run `login` and `logout` in an interactive terminal on your desktop so kong-harnesses can read prompts and access your operating system's secret store:

        {% table %}
        columns:
          - title: Operating system
            key: os
          - title: Secret store
            key: store
        rows:
          - os: macOS
            store: Keychain
          - os: Linux
            store: Secret Service, such as GNOME Keyring or KWallet
          - os: Windows
            store: DPAPI
        {% endtable %}
---

[kong-harnesses](/kong-harnesses/) signs you in to {{ site.ai_gateway }}, stores the sign-in in your computer's secret store, and supplies short-lived access tokens to your agent CLI.
When an identity provider token is close to expiring, kong-harnesses renews it automatically without opening your browser.

Follow the guide for your agent CLI for client-specific steps, or follow the shared kong-harnesses steps on this page:

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
    method: Uses `kong-harnesses login`, or opens your browser on first request for identity provider profiles.
    guide: "[Sign in to {{ site.claude_code }}](/kong-harnesses/sign-in/claude-code/)"
  - cli: Codex
    method: Requires `kong-harnesses login` before first use and an `https://` gateway serving `POST /v1/responses`.
    guide: "[Sign in to Codex](/kong-harnesses/sign-in/codex/)"
  - cli: OpenCode
    method: Uses the OpenCode plugin (`opencode auth login`); `kong-harnesses login` refuses `--client opencode`.
    guide: "[Sign in to OpenCode](/kong-harnesses/sign-in/opencode/)"
  - cli: Hermes Agent
    method: Uses the Hermes plugin (`hermes auth add kong-ai-gateway`); `kong-harnesses login` refuses `--client hermes`.
    guide: "[Sign in to Hermes Agent](/kong-harnesses/sign-in/hermes/)"
  - cli: omp
    method: Requires `kong-harnesses login` before first use.
    guide: "[Sign in to omp](/kong-harnesses/sign-in/omp/)"
  - cli: pi
    method: Requires `kong-harnesses login` before first use; clear any saved `kong` key in pi first.
    guide: "[Sign in to pi](/kong-harnesses/sign-in/pi/)"
{% endtable %}

## Sign in to a profile

Sign in to a kong-harnesses profile using [`kong-harnesses login`](/kong-harnesses/login/) in an interactive terminal.

1. Run `login` for your profile:

   ```sh
   kong-harnesses login --profile PROFILE_NAME
   ```

   For an identity provider profile, kong-harnesses opens your browser at the identity provider's sign-in page and prints the sign-in URL in the terminal.
   Open the URL in a browser on the same computer so the callback reaches kong-harnesses.
   To print the URL without opening a browser automatically, add `--no-browser`.

   For a static-key profile, `login` prompts for the key from your administrator and hides your input as you type.
1. Complete the sign-in and save any missing gateway MCP server keys if prompted.
   When the profile already has a usable sign-in, `login` keeps it and prompts only for missing gateway MCP server keys.
1. Follow the step in the `Next` field and restart any running agent CLI that uses the profile.

{:.info}
> **CI jobs and plugin-managed CLIs:**
>
> * A CI profile reads its key from `KONG_HARNESSES_STATIC_KEY` on every request, so kong-harnesses doesn't save the key and `login` refuses the profile.
>   Set `KONG_HARNESSES_STATIC_KEY` in the environment where your agent CLI starts.
> * OpenCode and Hermes Agent sign in through their own plugins, so `login`, `logout`, `credential`, and `token` refuse `--client opencode` and `--client hermes`.
>   Use [Sign in to OpenCode](/kong-harnesses/sign-in/opencode/) or [Sign in to Hermes Agent](/kong-harnesses/sign-in/hermes/) instead.

## Check the sign-in

Inspect your local sign-in state without contacting the network using [`kong-harnesses status`](/kong-harnesses/status/):

```sh
kong-harnesses status --profile PROFILE_NAME
```

The `Login` field shows the state of the sign-in:

{% table %}
columns:
  - title: Login
    key: state
  - title: What it means
    key: meaning
rows:
  - state: "`Ready`"
    meaning: >-
      This computer has a saved sign-in or key, or `KONG_HARNESSES_STATIC_KEY` contains a key in the expected format.
      `status` doesn't contact the identity provider or gateway.
  - state: "`Not signed in`"
    meaning: >-
      The profile doesn't have a saved sign-in on this computer.
      Run `kong-harnesses login --profile PROFILE_NAME`.
  - state: "`Sign-in needs attention`"
    meaning: >-
      The saved sign-in can't be used.
      Run `kong-harnesses login --profile PROFILE_NAME`.
  - state: "`Usable; an interrupted refresh resumes on the next call`"
    meaning: >-
      The previous renewal stopped before it finished.
      The saved sign-in still works, and the next token request resumes the renewal.
  - state: "`KONG_HARNESSES_STATIC_KEY is unset or holds no valid key`"
    meaning: >-
      The profile reads its key from the environment, and `KONG_HARNESSES_STATIC_KEY` isn't set to a valid key.
      Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator.
  - state: "`Could not be read`"
    meaning: >-
      kong-harnesses couldn't read the saved sign-in from your operating system's secret store.
      Unlock the secret store or check [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/errors/#when-kong-harnesses-can-t-give-an-access-token).
  - state: "`Managed by the client`"
    meaning: >-
      The agent CLI manages its sign-in through its own plugin, such as OpenCode or Hermes Agent.
      Follow the command in the `Next` field.
{% endtable %}

Without `--profile` or `KONG_HARNESSES_PROFILE`, `status` lists every installed profile.
If a profile shows `Unknown`, run `kong-harnesses status --profile PROFILE_NAME` to see the cause.
If `Profile state` starts with `Unreadable`, follow the next step in the output or see [Profile errors](/kong-harnesses/errors/#profile-errors).

## Sign in again

Replace a working sign-in or static key, or repair a damaged sign-in, depending on your current state.

To replace a sign-in or saved static key that still works, run `login` with `--replace`:

```sh
kong-harnesses login --profile PROFILE_NAME --replace
```

Type `PROFILE_NAME` when prompted to confirm.
`login --replace` disables the current sign-in on this computer before starting the new one, and the identity provider can keep the old authorization active.
If the new sign-in fails, run `kong-harnesses login --profile PROFILE_NAME` to sign in again.

If the profile doesn't have a saved sign-in yet, or if the saved sign-in is damaged or doesn't match the profile, `login --replace` refuses it.
Run `kong-harnesses login --profile PROFILE_NAME` without `--replace` instead:

* For a damaged or mismatched sign-in, `login` asks you to type `PROFILE_NAME` to confirm, removes the local sign-in, and starts a new one.
* For an interrupted renewal, `login` starts a new sign-in without asking to confirm and keeps the old sign-in if the new attempt fails.
* When the secret store is locked, refuses access, or isn't running, `login` stops with the matching error from [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/errors/#when-kong-harnesses-can-t-give-an-access-token).

## Sign out

Remove the saved sign-in and any saved gateway MCP server keys for a profile using [`kong-harnesses logout`](/kong-harnesses/logout/):

```sh
kong-harnesses logout --profile PROFILE_NAME
```

When the profile has a saved sign-in or key on this computer, `logout` asks you to type `PROFILE_NAME` to confirm.
Pass `--auto-approve` to confirm in advance when running without a prompt.

What `logout` revokes depends on the profile and saved state:

* **Identity provider profile with a revocation endpoint:** Disables the local sign-in, asks the identity provider to revoke the authorization, and removes the local sign-in after confirmation.
  If `logout` reports that server sign-out is unconfirmed, revoke the authorization at the identity provider and run `logout` again.
* **Identity provider profile without a revocation endpoint, static-key profile, or damaged sign-in:** Removes the sign-in or key from this computer only.
  Static keys keep working at {{ site.ai_gateway }} until an administrator revokes them.
* **Already signed out:** Removes any leftover gateway MCP server keys without prompting and prints `Already signed out`.
* **Running agent CLI sessions:** A session that already received an access token can keep using it until that token expires.

For `logout` errors such as incomplete local cleanup, see [When the login or logout command fails](/kong-harnesses/sign-in/errors/#when-the-login-or-logout-command-fails).

For a CI profile, `logout` doesn't unset `KONG_HARNESSES_STATIC_KEY`, so remove that variable from the job environment yourself.
If a saved sign-in or key for that profile name exists in the secret store and the session can reach it, `logout` removes it after confirmation.
Otherwise, `logout` behaves according to the operating system:

{% navtabs "ci-job-logout" %}
{% navtab "macOS and Windows" %}
`logout` prints `Already signed out` when this computer doesn't have a saved sign-in or key for that profile name.
{% endnavtab %}
{% navtab "Linux" %}
Set `XDG_RUNTIME_DIR` in the job first, or `logout` fails its profile lock.
When no Secret Service runs in the session, `logout` prints `Nothing signed out; this computer has no password store to check` and leaves any earlier desktop sign-in untouched.
Run `logout` from a desktop session with a keyring to remove an earlier saved sign-in or key.
{% endnavtab %}
{% endnavtabs %}

## Diagnose a failed sign-in

When `login` fails and its error line doesn't explain why, run `login` with `--diagnostics`:

```sh
kong-harnesses login --profile PROFILE_NAME --diagnostics
```

`login --diagnostics` reports the failing component and reason, such as an unsupported token lifetime, a missing refresh token, or an unavailable secret store, without printing access tokens or sign-in URLs.
When the profile doesn't have a usable sign-in, `login --diagnostics` attempts to sign in, which can ask to remove a damaged sign-in and open your browser.
When the sign-in is already ready, `login --diagnostics` doesn't send a sign-in request, though it still prompts for any missing gateway MCP server keys.
Don't combine `--diagnostics` with `--no-browser` or `--replace`.

For every sign-in, token, `login`, and `logout` error message and its fix, see [Sign-in errors in kong-harnesses](/kong-harnesses/sign-in/errors/).

## Validate

Confirm that your sign-in state matches the action you ran.

* **If you signed in:** Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) to verify your sign-in, gateway connection, and agent CLI configuration:

  ```sh
  kong-harnesses doctor --profile PROFILE_NAME
  ```

  Confirm that the `login` check reports `ok`, and fix any reported findings before starting your agent CLI.
* **If you signed out:** Run [`kong-harnesses status`](/kong-harnesses/status/) to verify that the local sign-in is gone:

  ```sh
  kong-harnesses status --profile PROFILE_NAME
  ```

  Confirm that `Login` shows `Not signed in`.
