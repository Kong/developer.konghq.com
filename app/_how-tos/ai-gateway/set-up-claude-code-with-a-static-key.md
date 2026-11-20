---
title: Set up {{ site.claude_code }} with a static key and kong-harnesses
content_type: how_to
permalink: /ai-gateway/set-up-claude-code-with-a-static-key/
breadcrumbs:
  - /ai-gateway/

description: Protect an AI Model with an API key, create a kong-harnesses profile that signs in with that key, and start a {{ site.claude_code }} session that sends every model request through {{site.ai_gateway}}.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl
  - kong-harnesses

automated_tests: false

min_version:
  ai-gateway: '2.4'

entities:
  - ai-consumer
  - ai-auth-strategy
  - ai-model-provider
  - ai-model

tags:
  - ai
  - anthropic
  - key-auth

related_resources:
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: kong-harnesses login
    url: /kong-harnesses/login/

prereqs:
  inline:
    - title: Shells on Windows
      position: before
      content: |
        On Windows, run the gateway quickstart, the `export` commands and `kongctl` in Windows Subsystem for Linux (WSL).
        Run kong-harnesses and {{ site.claude_code }} in PowerShell.
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: md/ai-gateway/v2/prereqs/anthropic
    - title: "{{ site.claude_code }}"
      icon_url: /assets/icons/third-party/claude.svg
      content: |
        Install {{ site.claude_code }} 2.1.278 or later.
        On macOS and Linux:

        ```sh
        curl -fsSL https://claude.ai/install.sh | bash
        ```

        On Windows, in PowerShell:

        ```powershell
        irm https://claude.ai/install.ps1 | iex
        ```

        Run `claude --version` to check the install.
        If the terminal can't find `claude`, do the `PATH` step that the installer prints.
        On macOS and Linux, if you open a new terminal for it, export the variables from the other prerequisites again.

tldr:
  q: How do I connect {{ site.claude_code }} to {{site.ai_gateway}} with a key and no identity provider?
  a: |
    Create an AI Consumer with an API key, and protect an AI Model with a `key-auth` AI Auth Strategy.
    Create a kong-harnesses profile with `kong-harnesses profile create --sign-in static-key`.
    Run `kong-harnesses login --profile <profile>` to save the key, and `kong-harnesses profile activate <profile> --client claude-code` to configure {{ site.claude_code }}.

cleanup:
  inline:
    - title: Clean up kong-harnesses
      content: |
        Remove the {{ site.claude_code }} settings that kong-harnesses added, remove the key from this computer, and delete the profile:

        ```sh
        kong-harnesses profile cleanup --client claude-code
        kong-harnesses logout --profile quickstart
        kong-harnesses profile delete quickstart
        ```

        `profile delete` asks you to type `quickstart` to confirm.
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

Use a static key when your organization has no identity provider, or when you run a gateway of your own. An administrator creates the key in {{site.ai_gateway}}. [kong-harnesses](/kong-harnesses/) keeps the key in the computer's own secret store: the macOS Keychain, Windows DPAPI, or Secret Service on Linux. It gives the key to {{ site.claude_code }} when {{ site.claude_code }} needs it, so the key isn't in the {{ site.claude_code }} settings.

The key doesn't expire. It works until an administrator revokes it in {{site.ai_gateway}}.

In this guide, you configure {{site.ai_gateway}} and create the kong-harnesses profile as an administrator does. Then you set up {{ site.claude_code }} as a developer does.

## Create an AI Consumer and its key

An [AI Consumer](/ai-gateway/entities/ai-consumer/) identifies the developer at the gateway. Give each developer an AI Consumer and a key of their own.

1. Create the AI Consumer:

   {% capture developer_consumer %}
   {% entity_examples %}
   ai_gateway_consumers:
     - ref: developer
       ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
       display_name: Developer
       name: developer
       type: api-key
       policies: []
   {% endentity_examples %}
   {% endcapture %}
   {{ developer_consumer | indent }}

1. Get the ID of the `developer` AI Consumer:

   ```sh
   export CONSUMER_ID="$(kongctl get ai-gateway consumers \
     --gateway-id "$AI_GATEWAY_ID" developer \
     --output json --jq '.id' --jq-raw-output \
     --pat "$KONNECT_TOKEN")"
   ```
   {: data-test-step="block"}

1. Create an API key for the AI Consumer:

   {% capture developer_credential %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CONSUMER_ID/credentials
   status_code: 201
   method: POST
   headers:
     - 'Content-Type: application/json'
     - 'Accept: application/json, application/problem+json'
   body:
     display_name: Developer key
     name: developer-key
     type: api-key
   extract_body:
     - name: 'api_key'
       variable: CONSUMER_API_KEY
   capture:
     - variable: CONSUMER_API_KEY
       jq: ".api_key"
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ developer_credential | indent }}

   {:.info}
   > The server generates the `api_key` value and shows it only in this response. `CONSUMER_API_KEY` keeps it for the sign-in step of this guide.

## Create the AI Model

Create the following entities:

* A `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that reads the key from the `Authorization` header or the `x-api-key` header.
* An [AI Model Provider](/ai-gateway/entities/ai-model-provider/) with your Anthropic key.
* An [AI Model](/ai-gateway/entities/ai-model/) for `claude-sonnet-5-5`.

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: developer-key-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Developer key auth
    name: developer-key-auth
    type: key-auth
    config:
      key_names:
        - Authorization
        - x-api-key
      header_auth_schemes:
        - Bearer
      key_in_header: true
      key_in_query: false
      hide_credentials: true
ai_gateway_model_providers:
  - ref: anthropic
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Anthropic
    name: anthropic
    type: anthropic
    config:
      auth:
        type: basic
        headers:
          - name: x-api-key
            value: !secret {source: !env ANTHROPIC_API_KEY}
ai_gateway_models:
  - ref: claude-sonnet-5-5
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: claude-sonnet-5-5
    name: claude-sonnet-5-5
    type: model
    capabilities:
      - generate
    formats:
      - type: anthropic
    targets:
      - name: claude-sonnet-5-5
        provider: anthropic
        config:
          type: anthropic
    access:
      auth_strategies:
        - !ref developer-key-auth#name
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - claude-sonnet-5-5
{% endentity_examples %}

{{ site.claude_code }} sends the key in the `Authorization: Bearer` header and in the `x-api-key` header. With `header_auth_schemes` set to `Bearer`, the strategy reads the key that follows `Bearer` in the `Authorization` header. When `hide_credentials` is `true`, {{site.ai_gateway}} removes that header before it sends the request to Anthropic, and the AI Model Provider sets `x-api-key` to your Anthropic key. Anthropic doesn't get the developer's key.

## Create the kong-harnesses profile

A kong-harnesses profile names the gateway, how developers sign in, and the model that {{ site.claude_code }} starts with. It holds no secrets. A static-key profile names no identity provider, so it needs only a name, the gateway origin and the model.

The gateway origin is `http://127.0.0.1:8000`, the address of the quickstart data plane. kong-harnesses accepts a plain `http://` gateway origin only for `localhost` or a loopback address. If you set a proxy with `HTTPS_PROXY`, `HTTP_PROXY`, `ALL_PROXY` or their lowercase forms, first add `127.0.0.1` to `NO_PROXY`, as [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/#create-the-kong-harnesses-profile) shows. A proxy that carries a request to an `http://` gateway can read the key, so `profile activate` doesn't configure a client when a proxy applies to the gateway host.

Create a profile named `quickstart` that signs in with a static key:

```sh
kong-harnesses profile create --name quickstart --sign-in static-key --gateway-origin http://127.0.0.1:8000 --model claude-sonnet-5-5
```

kong-harnesses saves the profile and installs it on this computer. It also sends a test request without the key to the gateway route of each agent CLI that the profile sets up. This guide sets up only {{ site.claude_code }}, so you can ignore warnings about other agent CLIs.

{:.info}
> In production, the administrator creates the profile once. Each developer gets the HTTPS URL or JSON file of the profile, and a key of their own. A developer then runs [`kong-harnesses setup`](/kong-harnesses/setup/) with the profile:
>
> ```sh
> kong-harnesses setup <profile-url> --client claude-code
> ```
>
> `setup` installs the profile, asks for the key, and configures {{ site.claude_code }} in one run.
>
> A developer who has only the key and the gateway URL can run `kong-harnesses setup` with no profile. `setup` then asks the questions of `profile create`. At the **Sign-in** question, the developer picks **Use a key from the administrator**.

## Save the key and configure {{ site.claude_code }}

Save the key in the profile:

```sh
kong-harnesses login --profile quickstart
```

`login` asks for the key and doesn't show it as you type. Paste the key from `CONSUMER_API_KEY`. To see it, run `echo "$CONSUMER_API_KEY"` in the shell where you created the key.

Configure {{ site.claude_code }} to use the profile:

```sh
kong-harnesses profile activate quickstart --client claude-code
```

`profile activate` sends a test request with the key to the gateway, writes the {{ site.claude_code }} settings, and then runs the `doctor` checks. It shows each problem that it finds with a fix. Fix the problems and run the same command again.

Some {{ site.claude_code }} features need a claude.ai or Anthropic Console account, or send data to Anthropic, so they change behind the gateway. [Features that change behind the gateway](/ai-gateway/set-up-claude-code-with-kong-harnesses/#features-that-change-behind-the-gateway) lists them.

## Replace or revoke the key

The key doesn't expire, so a leaked key works until an administrator revokes it.

* To revoke the key, delete the API key of the AI Consumer in {{site.konnect_short_name}}.
* To save a new key on this computer, run `kong-harnesses login --profile quickstart --replace`. `login` asks you to type the profile name, removes the saved key, and asks for the new one. A {{ site.claude_code }} session that is already running keeps the old key for up to five minutes.
* `kong-harnesses logout --profile quickstart` removes the key from this computer only. The key still works at the gateway until an administrator revokes it.

## Validate

Run `kong-harnesses doctor` to check the setup:

```sh
kong-harnesses doctor --profile quickstart --client claude-code
```

`doctor` checks the saved key, the connection to the gateway, the gateway route that {{ site.claude_code }} uses, and the {{ site.claude_code }} settings. A static-key profile has no identity provider, so `doctor` skips the issuer check. It shows a fix for each problem it finds, and it doesn't change any settings.

To also send one model request, add `--inference`. The request can cost money: the prompt is "Reply with OK." and the answer is at most 16 tokens.

```sh
kong-harnesses doctor --profile quickstart --client claude-code --inference
```

Start a {{ site.claude_code }} session:

```sh
claude
```

Send a prompt to check that you get a reply. {{ site.claude_code }} now sends every model request to {{site.ai_gateway}} with the key.

On macOS, run `kong-harnesses login --profile quickstart` once after each upgrade of kong-harnesses. Each time the Keychain asks whether kong-harnesses can use the saved key, click **Always Allow**.
