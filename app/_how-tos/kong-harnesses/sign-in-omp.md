---
title: Sign in to omp with kong-harnesses
description: Sign in to {{ site.ai_gateway }} for omp with kong-harnesses, check status, replace or revoke credentials, and validate the connection.

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
    Run `kong-harnesses login --profile PROFILE_NAME` before starting omp, because `kong-harnesses token` doesn't open a browser.
    Check the sign-in with `kong-harnesses status --profile PROFILE_NAME --client omp`, validate with `kong-harnesses doctor --profile PROFILE_NAME --client omp`, and start `omp`.

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
        Run `kong-harnesses profile list` to find your profile name, and replace `PROFILE_NAME` in each command with that name.
        If your profile uses a loopback `http://` gateway and your shell sets a proxy, add the gateway host to `NO_PROXY` and `no_proxy` in the shell that starts omp.
    - title: Activated omp profile
      content: |
        Activate the profile for omp if you haven't already:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client omp
        ```

        Run sign-in commands in an interactive terminal on your desktop so kong-harnesses can access your operating system's secret store.

cleanup:
  inline:
    - title: Sign out of omp
      include_content: kong-harnesses/sign-in-cleanup
---

omp reads its provider configuration from `~/.omp/agent/models.yml` and runs [`kong-harnesses token`](/kong-harnesses/token/) to get short-lived access tokens for {{ site.ai_gateway }}.
Because `token` never opens a browser, you must sign in with `kong-harnesses login` before starting omp.

## Sign in before starting omp

{% include kong-harnesses/sign-in-token-cli-login.md cli_name="omp" %}

## Check your sign-in status

Inspect the local sign-in and omp setup without using the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client omp
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Ready`, and `omp` shows `Configured`.
For every `Login` state and what to do when it isn't `Ready`, see [Check the sign-in](/kong-harnesses/sign-in/#check-the-sign-in).

### Replace a sign-in or diagnose a failure

{% include kong-harnesses/sign-in-replace-diagnose.md cli_name="omp" %}

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
