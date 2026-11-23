---
title: Sign in to OpenCode with kong-harnesses
description: Install the {{ site.ai_gateway }} plugin in OpenCode, sign in through OpenCode, verify your setup, and sign out.

content_type: how_to
permalink: /kong-harnesses/sign-in/opencode/
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
  q: How do I sign in to OpenCode with kong-harnesses?
  a: |
    Activate your HTTPS identity provider profile with `kong-harnesses profile activate PROFILE_NAME --client opencode` and start `opencode` once to install the gateway plugin.
    Then run `opencode auth login PROFILE_NAME` (OpenCode 2) or `opencode auth login --provider PROFILE_NAME` (OpenCode 1) and restart OpenCode.
    Sign out with `opencode auth logout`.

related_resources:
  - text: Sign in with kong-harnesses
    url: /kong-harnesses/sign-in/
  - text: Sign-in errors in kong-harnesses
    url: /kong-harnesses/sign-in/errors/
  - text: kong-harnesses profile activate
    url: /kong-harnesses/profile/activate/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: OpenCode, kong-harnesses, and an HTTPS identity provider profile
      content: |
        Install [kong-harnesses](/kong-harnesses/) and OpenCode, and install an `https://` identity provider profile that configures `opencode`.
        OpenCode doesn't support static-key profiles or plain `http://` gateways.
        Run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to find your profile name, and replace `PROFILE_NAME` in each command with that name.
    - title: npm read access to the `@kong` scope
      content: |
        OpenCode downloads the private `@kong/opencode-plugin-kong-ai-gateway` package when it starts.
        Add an npm token with read access to the `@kong` scope to `~/.npmrc`, replacing `NPM_TOKEN` with your token:

        ```ini
        //registry.npmjs.org/:_authToken=NPM_TOKEN
        ```
    - title: Activated OpenCode profile
      content: |
        Activate the profile for OpenCode with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/) so its configuration names the gateway plugin:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client opencode
        ```

cleanup:
  inline:
    - title: Sign out of OpenCode
      content: |
        Remove your OpenCode gateway credentials using OpenCode's logout command:

        ```sh
        opencode auth logout
        ```

        Select the provider named `PROFILE_NAME` when prompted.

faqs:
  - q: How do I fix `Integration not found`, `Unknown provider`, or `redirect_uri` errors in OpenCode?
    a: |
      Run `kong-harnesses doctor --profile PROFILE_NAME --client opencode` and apply the findings in the report:

      * **Profile doesn't configure OpenCode:** Run [`kong-harnesses profile get PROFILE_NAME`](/kong-harnesses/profile/get/) to see which agent CLIs the profile configures.
        Recreate the profile with [`kong-harnesses profile create`](/kong-harnesses/profile/create/), or import an updated profile from your administrator with [`kong-harnesses profile import`](/kong-harnesses/profile/import/), then run `kong-harnesses profile activate PROFILE_NAME --client opencode`.
      * **`npm` or `plugin` check fails:** Follow the `fix:` lines in the report to restore registry access or remove a stale cached plugin.
      * **`redirect_uri` mismatch at sign-in:** Set `"redirectURI"` in the plugin options to the callback URL named by `doctor`, or remove the manual plugin entry and run `kong-harnesses profile activate PROFILE_NAME --client opencode` again.

      Start `opencode` once to install the plugin, exit it, and run the OpenCode sign-in command again.
---

OpenCode manages its own authentication through the `@kong/opencode-plugin-kong-ai-gateway` plugin and stores credentials in its own `auth.json`.
`kong-harnesses login`, `logout`, `credential`, and `token` refuse `--client opencode`, so you sign in and sign out with OpenCode's own commands.

## Install the OpenCode gateway plugin

Start OpenCode once after activating the profile so OpenCode downloads and caches the gateway plugin:

```sh
opencode
```

Exit OpenCode after it finishes starting.

## Sign in through OpenCode

Run the OpenCode login command for your OpenCode version, using your profile name as the provider ID:

{% navtabs "opencode-login" %}
{% navtab "OpenCode 2" %}

```sh
opencode auth login PROFILE_NAME
```

{% endnavtab %}
{% navtab "OpenCode 1" %}

```sh
opencode auth login --provider PROFILE_NAME
```

{% endnavtab %}
{% endnavtabs %}

Complete the sign-in in your browser, then restart OpenCode so it loads the gateway model list.

## Check your sign-in status

Check the local OpenCode setup with [`kong-harnesses status`](/kong-harnesses/status/), which doesn't contact the network:

```sh
kong-harnesses status --profile PROFILE_NAME --client opencode
```

Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Managed by the client`, and `OpenCode` shows `Configured`.

## Validate

Confirm that OpenCode's plugin, gateway connection, and model list work end to end:

1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for OpenCode:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client opencode
   ```

   Confirm that `npm`, `plugin`, `gateway`, and `client` report `ok`, and resolve any failures.
1. Start OpenCode and confirm your gateway models are listed:

   ```sh
   opencode
   ```
