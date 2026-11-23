---
title: Sign in to omp with kong-harnesses
description: Sign in to {{ site.ai_gateway }} for omp using kong-harnesses, verify your sign-in, and start a session.

content_type: how_to
permalink: /kong-harnesses/sign-in/omp/
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
  q: How do I sign in to omp with kong-harnesses?
  a: |
    Run `kong-harnesses login --profile PROFILE_NAME` before starting omp, then verify with `kong-harnesses status --profile PROFILE_NAME --client omp` and `kong-harnesses doctor --profile PROFILE_NAME --client omp`.
    Start `omp` and send a prompt to confirm the connection.

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
    - title: omp, kong-harnesses, and a profile
      content: |
        Install [kong-harnesses](/kong-harnesses/) and omp, and install a profile that configures `omp`.
        Run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to find your profile name, and replace `PROFILE_NAME` in each command with that name.
        If your profile uses a loopback `http://` gateway and your shell sets a proxy, add the gateway host to `NO_PROXY` and `no_proxy` in the shell that starts omp.
    - title: Activated omp profile
      content: |
        Activate the profile for omp with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/) if you haven't already:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client omp
        ```

        Run sign-in commands in an interactive terminal on your desktop so kong-harnesses can access your operating system's secret store.

cleanup:
  inline:
    - title: Sign out of omp
      include_content: kong-harnesses/sign-in-cleanup

faqs:
  - q: How do I replace a working omp sign-in or diagnose a failure?
    a: |
      To switch accounts or rotate a saved static key for omp, run `kong-harnesses login --profile PROFILE_NAME --replace` and type `PROFILE_NAME` to confirm.
      When the saved sign-in is missing or damaged, run `kong-harnesses login --profile PROFILE_NAME` without `--replace` instead (see [Sign in again](/kong-harnesses/sign-in/#sign-in-again)).
      To diagnose a failed sign-in without printing tokens or URLs, run `kong-harnesses login --profile PROFILE_NAME --diagnostics` and see [Sign-in errors in kong-harnesses](/kong-harnesses/sign-in/errors/).
  - q: What do I need to do on macOS after upgrading kong-harnesses?
    a: |
      Run `kong-harnesses login --profile PROFILE_NAME` once after each kong-harnesses upgrade on macOS.
      Each time Keychain asks whether kong-harnesses can use your sign-in, click **Always Allow**.
---

omp reads its provider configuration from `~/.omp/agent/models.yml` and runs [`kong-harnesses token`](/kong-harnesses/token/) to get short-lived access tokens for {{ site.ai_gateway }}.
Because `token` never opens a browser, sign in with `kong-harnesses login` before starting omp.

## Sign in before starting omp

{% include kong-harnesses/sign-in-login-steps.md cli_name="omp" ci_note="true" %}

## Check your sign-in status

Check the local sign-in and omp setup with [`kong-harnesses status`](/kong-harnesses/status/), which doesn't contact the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client omp
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Ready`, and `omp` shows `Configured`.
For every `Login` state and what to do when it isn't `Ready`, see [Check the sign-in](/kong-harnesses/sign-in/#check-the-sign-in).

## Validate

Confirm that your sign-in, gateway route, and omp configuration pass all checks:

1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for omp:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client omp
   ```

   Confirm that `login`, `client`, `gateway`, and `route` report `ok`, and resolve any failures.
1. Start omp and send a prompt to confirm you receive a reply:

   ```sh
   omp
   ```
