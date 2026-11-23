---
title: Sign in to OpenCode with kong-harnesses
description: Create an AI Model and a kong-harnesses profile, install the {{ site.ai_gateway }} plugin in OpenCode, sign in through OpenCode, and validate your setup.

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
  - kongctl
  - kong-harnesses

tags:
  - ai
  - authentication
  - cli

automated_tests: false

min_version:
  ai-gateway: '2.4'

tldr:
  q: How do I sign in to OpenCode with kong-harnesses?
  a: |
    Send OpenCode requests through {{site.ai_gateway}} with a short-lived Okta sign-in from the OpenCode gateway plugin instead of a long-lived API key.
    Create an AI Model and a kong-harnesses profile, activate the profile, sign in with `opencode auth login`, and validate the setup with `kong-harnesses doctor`.

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
  konnect:
    - name: KONG_SSL_CERT
    - name: KONG_SSL_CERT_KEY
  inline:
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: md/ai-gateway/v2/prereqs/anthropic
    - title: Okta
      icon_url: /assets/icons/okta.svg
      include_content: prereqs/auth/oidc/okta-kong-harnesses
    - title: A trusted certificate for the gateway
      position: before
      include_content: kong-harnesses/trusted-gateway-cert
    - title: OpenCode
      content: |
        Install OpenCode 2 on macOS:

        ```sh
        brew install anomalyco/tap/opencode-v2
        ```

        Or install OpenCode 1:

        ```sh
        npm install -g opencode-ai
        ```

        OpenCode doesn't support static-key profiles or plain `http://` gateways.
    - title: npm read access to the `@kong` scope
      content: |
        OpenCode downloads the private `@kong/opencode-plugin-kong-ai-gateway` package when it starts.
        Add an npm token with read access to the `@kong` scope to `~/.npmrc`, replacing `NPM_TOKEN` with your token:

        ```ini
        //registry.npmjs.org/:_authToken=NPM_TOKEN
        ```

cleanup:
  inline:
    - title: Sign out of OpenCode
      content: |
        Remove your OpenCode gateway credentials using OpenCode's logout command:

        ```sh
        opencode auth logout
        ```

        Select the provider named `quickstart` when prompted.
    - title: Clean up kong-harnesses
      content: |
        Remove the OpenCode settings that kong-harnesses added and delete the profile:

        ```sh
        kong-harnesses profile cleanup --client opencode
        kong-harnesses profile delete quickstart
        ```

        `profile delete` asks you to type `quickstart` to confirm.
    - title: Clean up Okta
      include_content: kong-harnesses/cleanup-okta
    - title: Clean up the local certificate
      include_content: kong-harnesses/trusted-gateway-cert-cleanup
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: How do I fix `Integration not found`, `Unknown provider`, or `redirect_uri` errors in OpenCode?
    a: |
      Run `kong-harnesses doctor --profile quickstart --client opencode` and apply the findings in the report:

      * **Profile doesn't configure OpenCode:** Run [`kong-harnesses profile get quickstart`](/kong-harnesses/profile/get/) to see which agent CLIs the profile configures.
        Recreate the profile with [`kong-harnesses profile create`](/kong-harnesses/profile/create/), or import an updated profile from your administrator with [`kong-harnesses profile import`](/kong-harnesses/profile/import/), then run `kong-harnesses profile activate quickstart --client opencode`.
      * **`npm` or `plugin` check fails:** Follow the `fix:` lines in the report to restore registry access or remove a stale cached plugin.
      * **`redirect_uri` mismatch at sign-in:** Set `"redirectURI"` in the plugin options to the callback URL named by `doctor`, or remove the manual plugin entry and run `kong-harnesses profile activate quickstart --client opencode` again.

      Start `opencode` once to install the plugin, exit it, and run the OpenCode sign-in command again.
---

OpenCode manages its own authentication through the `@kong/opencode-plugin-kong-ai-gateway` plugin and stores credentials in its own `auth.json`.
`kong-harnesses login`, `logout`, `credential`, and `token` refuse `--client opencode`, so you sign in and sign out with OpenCode's own commands.

## Create the AI Model

{% include how-tos/steps/kong-harnesses-anthropic-model.md cli_name="OpenCode" %}

## Create the kong-harnesses profile

Create a profile named `quickstart` with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
The gateway origin is the HTTPS port of the quickstart data plane, `https://localhost:8443`.
kong-harnesses reads the endpoints of your Okta authorization server from its discovery document, saves the profile, and installs it on this computer:

```sh
kong-harnesses profile create \
  --name quickstart \
  --issuer "$ISSUER_URL" \
  --client-id "$OKTA_CLIENT_ID" \
  --audience api://default \
  --gateway-origin https://localhost:8443 \
  --model claude-sonnet-5-5
```

This guide sets up only OpenCode, so you can ignore warnings about other agent CLIs.

## Activate the profile

Configure OpenCode to use the profile with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/), so the OpenCode configuration names the gateway plugin:

```sh
kong-harnesses profile activate quickstart --client opencode
```

Start OpenCode once to download and cache the gateway plugin, then exit:

```sh
opencode
```

{:.info}
> OpenCode 2 runs a background service on port 49374.
> If starting OpenCode reports that the managed service port is already in use, set another port with `opencode service set port PORT`, then start OpenCode again.

## Sign in through OpenCode

Run the OpenCode login command for your OpenCode version, using your profile name as the provider ID:

{% navtabs "opencode-login" %}
{% navtab "OpenCode 2" %}

```sh
opencode auth login quickstart
```

{% endnavtab %}
{% navtab "OpenCode 1" %}

```sh
opencode auth login --provider quickstart
```

{% endnavtab %}
{% endnavtabs %}

Complete the sign-in in your browser, then restart OpenCode so it loads the gateway model list.

## Validate

Confirm that OpenCode's plugin, gateway connection, and client configuration pass all checks:

{% validation custom-command %}
command: kong-harnesses doctor --profile quickstart --client opencode
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Start OpenCode and confirm that your gateway models are listed:

```sh
opencode
```
