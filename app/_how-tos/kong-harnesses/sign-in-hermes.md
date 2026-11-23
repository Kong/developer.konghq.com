---
title: Sign in to Hermes Agent with kong-harnesses
description: Sign in to {{ site.ai_gateway }} for Hermes Agent through its gateway plugin, verify saved credentials, and sign out.

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
  - kong-harnesses

tags:
  - ai
  - authentication
  - cli

automated_tests: false

tldr:
  q: How do I sign in to Hermes Agent with kong-harnesses?
  a: |
    Activate your HTTPS identity provider profile with `kong-harnesses profile activate PROFILE_NAME --client hermes`, sign in with `hermes auth add kong-ai-gateway`, and restart Hermes Agent.
    Sign out with `hermes auth logout kong-ai-gateway` or remove one pool entry by ID with `hermes auth remove kong-ai-gateway ENTRY_ID`.

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
    - title: Hermes Agent, plugin, and kong-harnesses
      content: |
        Install [kong-harnesses](/kong-harnesses/), Hermes Agent, and the {{ site.ai_gateway_name }} model-provider plugin (version 1.1.0 or later).
        Install an `https://` identity provider profile that configures `hermes`.
        Your administrator configures the profile with `audience_parameter: audience` and the `openid`, `profile`, `email`, and `offline_access` scopes.
        Hermes Agent doesn't support static-key profiles or plain `http://` gateways.
        Run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to find your profile name, and replace `PROFILE_NAME` in each command with that name.
    - title: Activated Hermes Agent profile
      content: |
        Activate the profile for Hermes Agent with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/) so kong-harnesses writes the gateway and OIDC settings to `~/.hermes/config.yaml`:

        ```sh
        kong-harnesses profile activate PROFILE_NAME --client hermes
        ```

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

faqs:
  - q: What happens if I activate a Hermes Agent profile with a different gateway or issuer?
    a: |
      Each Hermes Agent sign-in applies only to the gateway and issuer configured when you sign in.
      If you activate a profile with a different gateway or issuer, run `hermes auth add kong-ai-gateway` again and restart Hermes Agent.
---

Hermes Agent manages its own authentication through the {{ site.ai_gateway_name }} model-provider plugin, stores credentials in its credential pool in `auth.json`, and refreshes access tokens on each request.
`kong-harnesses login`, `logout`, `credential`, and `token` refuse `--client hermes`, so you sign in and sign out with Hermes Agent's own commands.

## Sign in through Hermes Agent

Sign in to the `kong-ai-gateway` provider so the plugin saves your gateway credentials:

1. Start the plugin sign-in:

   ```sh
   hermes auth add kong-ai-gateway
   ```

   The plugin reads the gateway and OIDC settings that `profile activate` wrote to `~/.hermes/config.yaml`, so the command doesn't require extra flags.
1. Complete the sign-in in your browser, then restart Hermes Agent.

## Check your Hermes Agent credentials

Verify both the Hermes credential pool and the kong-harnesses setup:

1. List saved credentials for the `kong-ai-gateway` provider:

   ```sh
   hermes auth list kong-ai-gateway
   ```

   Confirm that the list shows at least one `kong-ai-gateway` entry.
1. Check the local Hermes Agent setup with [`kong-harnesses status`](/kong-harnesses/status/), which doesn't contact the network:

   ```sh
   kong-harnesses status --profile PROFILE_NAME --client hermes
   ```

   Confirm that `Profile` shows `PROFILE_NAME`, `Login` shows `Managed by the client`, and `Hermes` shows `Configured`.

## Validate

Confirm that kong-harnesses sees Hermes Agent configured and that Hermes Agent can reach {{ site.ai_gateway }}:

1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) for Hermes Agent:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client hermes
   ```

   Confirm that `client` and `gateway` report `ok`, and resolve any failures.
1. Start Hermes Agent and send a prompt to confirm you receive a reply:

   ```sh
   hermes
   ```
