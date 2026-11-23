---
title: Sign in to pi with kong-harnesses
description: Clear any saved kong key in pi, sign in to {{ site.ai_gateway }} using kong-harnesses, verify your sign-in, and start a session.

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
  - kong-harnesses

tags:
  - ai
  - authentication
  - cli

automated_tests: false

tldr:
  q: How do I sign in to pi with kong-harnesses?
  a: |
    Remove any saved `kong` key in pi with `pi auth logout kong`, then run `kong-harnesses login --profile PROFILE_NAME` before starting pi.
    Verify with `kong-harnesses status --profile PROFILE_NAME --client pi` and `kong-harnesses doctor --profile PROFILE_NAME --client pi`, then start `pi`.

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
    - title: pi, kong-harnesses, and a profile
      content: |
        Install [kong-harnesses](/kong-harnesses/) and pi, and install a profile that configures `pi`.
        Run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to find your profile name, and replace `PROFILE_NAME` in each command with that name.
        If your profile uses a loopback `http://` gateway and your shell sets a proxy, add the gateway host to `NO_PROXY` and `no_proxy` in the shell that starts pi.
    - title: Activated pi profile
      content: |
        Activate the profile for pi with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/) if you haven't already:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client pi
        ```

        Run sign-in commands in an interactive terminal on your desktop so kong-harnesses can access your operating system's secret store.

cleanup:
  inline:
    - title: Sign out of pi
      include_content: kong-harnesses/sign-in-cleanup

faqs:
  - q: How do I replace a working pi sign-in or diagnose a failure?
    a: |
      To switch accounts or rotate a saved static key for pi, run `kong-harnesses login --profile PROFILE_NAME --replace` and type `PROFILE_NAME` to confirm.
      When the saved sign-in is missing or damaged, run `kong-harnesses login --profile PROFILE_NAME` without `--replace` instead (see [Sign in again](/kong-harnesses/sign-in/#sign-in-again)).
      To diagnose a failed sign-in without printing tokens or URLs, run `kong-harnesses login --profile PROFILE_NAME --diagnostics` and see [Sign-in errors in kong-harnesses](/kong-harnesses/sign-in/errors/).
  - q: What do I need to do on macOS after upgrading kong-harnesses?
    a: |
      Run `kong-harnesses login --profile PROFILE_NAME` once after each kong-harnesses upgrade on macOS.
      Each time Keychain asks whether kong-harnesses can use your sign-in, click **Always Allow**.
---

pi reads its provider configuration from `~/.pi/agent/models.json` and runs [`kong-harnesses token`](/kong-harnesses/token/) on every request to get a short-lived access token for {{ site.ai_gateway }}.
Because `token` never opens a browser, sign in with `kong-harnesses login` before starting pi.

## Clear any saved kong key in pi

If you previously saved a key for the `kong` provider with `pi auth login`, pi sends that key instead of calling `kong-harnesses token`.
Remove any saved `kong` key from pi's `auth.json` first:

```sh
pi auth logout kong
```

## Sign in before starting pi

{% include kong-harnesses/sign-in-login-steps.md cli_name="pi" ci_note="true" %}

## Check your sign-in status

Check the local sign-in and pi setup with [`kong-harnesses status`](/kong-harnesses/status/), which doesn't contact the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client pi
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Ready`, and `pi` shows `Configured` (not `Bypassed by a key pi saved for the kong provider`).
For every `Login` state and what to do when it isn't `Ready`, see [Check the sign-in](/kong-harnesses/sign-in/#check-the-sign-in).

## Validate

Confirm that your sign-in, gateway route, and pi configuration pass all checks:

1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for pi:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client pi
   ```

   Confirm that `login`, `client`, `gateway`, and `route` report `ok`, and resolve any failures.
1. Start pi and send a prompt to confirm you receive a reply:

   ```sh
   pi
   ```
