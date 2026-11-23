---
title: Sign in to pi with kong-harnesses
description: Clear any saved kong key in pi, sign in to {{ site.ai_gateway }} with kong-harnesses, check status, replace or revoke credentials, and validate the connection.

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
    Check the sign-in with `kong-harnesses status --profile PROFILE_NAME --client pi`, validate with `kong-harnesses doctor --profile PROFILE_NAME --client pi`, and start `pi`.

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
        Run `kong-harnesses profile list` to find your profile name, and replace `PROFILE_NAME` in each command with that name.
        If your profile uses a loopback `http://` gateway and your shell sets a proxy, add the gateway host to `NO_PROXY` and `no_proxy` in the shell that starts pi.
    - title: Activated pi profile
      content: |
        Activate the profile for pi if you haven't already:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client pi
        ```

        Run sign-in commands in an interactive terminal on your desktop so kong-harnesses can access your operating system's secret store.

cleanup:
  inline:
    - title: Sign out of pi
      include_content: kong-harnesses/sign-in-cleanup
---

pi reads its provider configuration from `~/.pi/agent/models.json` and runs [`kong-harnesses token`](/kong-harnesses/token/) on every request to get a short-lived access token for {{ site.ai_gateway }}.
Because `token` never opens a browser, you must sign in with `kong-harnesses login` before starting pi.

## Clear any saved kong key in pi

If you previously saved a key for the `kong` provider with `pi auth login`, pi sends that key instead of calling `kong-harnesses token`.
Remove any saved `kong` key from pi's `auth.json` first:

```sh
pi auth logout kong
```

If pi doesn't have a saved `kong` key, continue to the next step.

## Sign in before starting pi

{% include kong-harnesses/sign-in-token-cli-login.md cli_name="pi" %}

## Check your sign-in status

Inspect the local sign-in and pi setup without using the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client pi
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Ready`, and `pi` shows `Configured` (not `Bypassed by a key pi saved for the kong provider`).
For every `Login` state and what to do when it isn't `Ready`, see [Check the sign-in](/kong-harnesses/sign-in/#check-the-sign-in).

### Replace a sign-in or diagnose a failure

{% include kong-harnesses/sign-in-replace-diagnose.md cli_name="pi" %}

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
