---
title: Sign in to Hermes Agent with kong-harnesses
description: Create an AI Model and a kong-harnesses profile, sign in to {{ site.ai_gateway }} for Hermes Agent through the Hermes Agent gateway plugin, and validate your setup.

content_type: how_to
permalink: /kong-harnesses/sign-in/hermes/
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
  q: How do I sign in to Hermes Agent with kong-harnesses?
  a: |
    Send Hermes Agent requests through {{site.ai_gateway}} with a short-lived Okta sign-in from the Hermes Agent gateway plugin instead of a long-lived API key.
    Create an AI Model and a kong-harnesses profile, activate the profile, sign in with `hermes auth add kong-ai-gateway`, and validate the setup with `kong-harnesses doctor`.

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
    - title: Hermes Agent and the gateway plugin
      content: |
        Install Hermes Agent 0.23.2, the version that the plugin targets.
        Then clone the {{ site.ai_gateway_name }} model-provider plugin (version 1.1.0 or later) into the Hermes Agent plugin folder for model providers:

        ```sh
        git clone git@github.com:Kong/hermes-plugin-kong-ai-gateway.git ~/.hermes/plugins/model-providers/kong-ai-gateway
        ```

        Do not use `hermes plugins install`, because Hermes Agent looks for model-provider plugins in a different folder than the one that command writes to.
        Hermes Agent doesn't support static-key profiles or plain `http://` gateways.

cleanup:
  inline:
    - title: Sign out of Hermes Agent
      content: |
        Remove all credentials for the `kong-ai-gateway` provider using Hermes Agent's logout command:

        ```sh
        hermes auth logout kong-ai-gateway
        ```

        To remove one credential from a pool instead:

        1. List the provider's entries and copy the entry ID of the credential to remove:

           ```sh
           hermes auth list kong-ai-gateway
           ```

        1. Remove that entry by ID, replacing `ENTRY_ID` with the entry ID from the list:

           ```sh
           hermes auth remove kong-ai-gateway ENTRY_ID
           ```

        {:.warning}
        > Do not pass a list index or a label to `hermes auth remove`.
        > List indices shift when you remove an earlier entry, and Hermes Agent refuses a label when more than one credential shares it.
    - title: Clean up kong-harnesses
      content: |
        Remove the Hermes Agent settings that kong-harnesses added and delete the profile:

        ```sh
        kong-harnesses profile cleanup --client hermes
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
  - q: What happens if I activate a Hermes Agent profile with a different gateway or issuer?
    a: |
      Each Hermes Agent sign-in applies only to the gateway and issuer configured when you sign in.
      If you activate a profile with a different gateway or issuer, run `hermes auth add kong-ai-gateway` again and restart Hermes Agent.
---

Hermes Agent manages its own authentication through the {{ site.ai_gateway_name }} model-provider plugin.
The plugin stores credentials in the Hermes Agent credential pool in `auth.json` and refreshes access tokens on each request.
`kong-harnesses login`, `logout`, `credential`, and `token` refuse `--client hermes`, so you sign in and sign out with Hermes Agent's own commands.

## Create the AI Model

{% include how-tos/steps/kong-harnesses-anthropic-model.md cli_name="Hermes Agent" %}

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
  --model claude-sonnet-5-5 \
  --audience-parameter audience
```

This guide sets up only Hermes Agent, so you can ignore warnings about other agent CLIs.

## Activate the profile

Configure Hermes Agent to use the profile with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/), so kong-harnesses writes the gateway and OIDC settings to `~/.hermes/config.yaml`:

```sh
kong-harnesses profile activate quickstart --client hermes
```

## Sign in through Hermes Agent

Sign in to the `kong-ai-gateway` provider so the plugin saves your gateway credentials:

1. Start the plugin sign-in:

   ```sh
   hermes auth add kong-ai-gateway
   ```

   The plugin reads the settings that `profile activate` wrote, so the command doesn't need extra flags.
1. Complete the sign-in in your browser, then restart Hermes Agent.

## Validate

Confirm that Hermes Agent has a saved credential and that the setup passes all checks.
List saved credentials for the `kong-ai-gateway` provider, and confirm that the list shows at least one entry:

```sh
hermes auth list kong-ai-gateway
```

Then run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for Hermes Agent:

{% validation custom-command %}
command: kong-harnesses doctor --profile quickstart --client hermes
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Start Hermes Agent and send a prompt to confirm that you receive a reply:

```sh
hermes
```
