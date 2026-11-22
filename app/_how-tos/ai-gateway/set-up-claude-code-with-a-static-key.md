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
  - text: Proxy AI CLI tools through {{site.ai_gateway}}
    url: /ai-gateway/ai-clis/
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
        On Windows, run the gateway quickstart, the `export` commands, the API requests and `kongctl` in Windows Subsystem for Linux (WSL).
        Run kong-harnesses and {{ site.claude_code }} in PowerShell.
    - title: jq
      icon_url: /assets/icons/code.svg
      include_content: md/ai-gateway/v2/prereqs/kong-harnesses-jq
    - title: Clipboard tool on Linux
      icon_url: /assets/icons/code.svg
      content: |
        On Linux, this guide copies the key with `wl-copy` from wl-clipboard on Wayland, or with `xclip` on X11.
        On Debian and Ubuntu, install the one for your desktop:

        ```sh
        sudo apt-get install wl-clipboard
        ```

        ```sh
        sudo apt-get install xclip
        ```
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: md/ai-gateway/v2/prereqs/anthropic
    - title: "{{ site.claude_code }}"
      icon_url: /assets/icons/third-party/claude.svg
      include_content: md/ai-gateway/v2/prereqs/kong-harnesses-claude-code

tldr:
  q: How do I connect {{ site.claude_code }} to {{site.ai_gateway}} with a key and without an identity provider?
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
    - title: Revoke the key
      include_content: md/ai-gateway/v2/delete-consumer-credential
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: How do I replace or revoke a kong-harnesses static key?
    a: |
      Replace a saved kong-harnesses static key on your computer with the command in [Sign in again](/kong-harnesses/sign-in/#sign-in-again).
      A running {{ site.claude_code }} session keeps the old key for up to five minutes.
      Signing out removes the key from your computer only, as [Sign out](/kong-harnesses/sign-in/#sign-out) describes.
      The key works at {{site.ai_gateway}} until an administrator revokes it.
      To revoke a leaked key at the gateway, [delete the API key of the AI Consumer](/api/konnect/ai-gateway/#/operations/delete-ai-gateway-consumer-credential).
---

Use a static key when your organization doesn't use an identity provider, or when you run a gateway of your own.
An administrator creates the key in {{site.ai_gateway}}.
[kong-harnesses](/kong-harnesses/) keeps the key in the secret store of the operating system.
It gives the key to {{ site.claude_code }} when {{ site.claude_code }} needs it, so the key isn't in the {{ site.claude_code }} settings.

The key doesn't expire.
It works until an administrator revokes it in {{site.ai_gateway}}.

In this guide, you configure {{site.ai_gateway}} and create the kong-harnesses profile as an administrator does.
Then you set up {{ site.claude_code }} as a developer does.

## Create an AI Consumer and its key

An [AI Consumer](/ai-gateway/entities/ai-consumer/) identifies the developer at the gateway.
Give each developer an AI Consumer and a key of their own.

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

1. Remove an older `CONSUMER_API_KEY` from this shell.
   If the variable was exported before, the shell keeps exporting it, and the programs that you start from this shell get the new key:

   ```sh
   unset CONSUMER_API_KEY
   ```

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
       command: "jq -er '.api_key | strings'"
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ developer_credential | indent }}

   {:.info}
   > The server generates the `api_key` value and shows it only in this response.
   > `CONSUMER_API_KEY` keeps it in this shell for the sign-in step of this guide.
   > The command doesn't export the variable, so the programs that you start from this shell don't get the key.
   >
   > If the request fails, or the response has no key, the command exits with an error and `CONSUMER_API_KEY` is empty.
   > Fix the error and run the command again.
   > If the error is `409`, a key named `developer-key` already exists.
   > The API returns a key only when it creates it.
   > If you lose the key, expand **Revoke the key** in [Cleanup](#cleanup) and run its requests, then create the key again.

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

{{ site.claude_code }} sends the key in `Authorization: Bearer` and `x-api-key`, so this [API key authentication](/ai-gateway/entities/ai-auth-strategy/#api-key-authentication) strategy removes `Authorization` and the AI Model Provider replaces `x-api-key` with your Anthropic key.

## Create the kong-harnesses profile

A kong-harnesses profile names the gateway, how developers sign in, and the model that {{ site.claude_code }} starts with.
It doesn't hold secrets.
A static-key profile doesn't name an identity provider, so it needs only a name, the gateway origin and the model.

The gateway origin is `http://127.0.0.1:8000`, the address of the quickstart data plane.
If your shell sets a proxy, add `127.0.0.1` to `NO_PROXY` (and `no_proxy` if it's set) in the shell that runs kong-harnesses.
The `NO_PROXY` setting exists only in the shell where you set it, so set it again in a new shell or add it to your shell profile before you run kong-harnesses there.
For loopback HTTP and proxy rules, see [Plain HTTP gateways](/kong-harnesses/profile-file/#plain-http-gateways).

Create a profile named `quickstart` that signs in with a static key:

```sh
kong-harnesses profile create --name quickstart --sign-in static-key --gateway-origin http://127.0.0.1:8000 --model claude-sonnet-5-5
```

kong-harnesses saves the profile and installs it on this computer.
It also sends a test request without the key to the gateway route of each agent CLI that the profile sets up.
This guide sets up only {{ site.claude_code }}, so you can ignore warnings about other agent CLIs.

{:.info}
> For production, use an `https://` gateway origin and publish the profile as [Profile hosting](/kong-harnesses/profiles-for-administrators/#profile-hosting) describes.
> For supported profile file encodings, see [Profile file encoding](/kong-harnesses/profile-file/#profile-file-encoding).
> The profile doesn't contain the key, so send each developer their own key through a password manager or another secure channel.
> Developers then run [`kong-harnesses setup`](/kong-harnesses/setup/) with the profile URL or file and `--client claude-code`, such as `kong-harnesses setup <profile>.json --client claude-code`.
> Without `--client`, `setup` configures every installed client that the profile lists.
> It first checks each client, skips each client that fails these checks, and names the fix.
> For example, it skips a client when the gateway doesn't serve its route or refuses the sign-in, or when the client needs an `https://` gateway.
> If a client that passes these checks then refuses the profile, `setup` stops before it writes the settings of any client.
> A developer who has only a key can run `kong-harnesses setup --client claude-code` without a profile file, as [Set up without a profile file](/kong-harnesses/setup/#set-up-without-a-profile-file) describes.

## Save the key and configure {{ site.claude_code }}

Copy the key to the clipboard without showing it, and save it in the profile.
Then remove the key from the clipboard and from the shell:

{% navtabs "save-the-key" %}
{% navtab "macOS" %}
1. Turn off Handoff in **System Settings** > **General** > **AirDrop & Handoff**.
   Universal Clipboard sends the clipboard to your other Apple devices, so it can send the key to them.

1. In the shell where you created the key, copy the key:

   ```sh
   printf %s "$CONSUMER_API_KEY" | pbcopy
   ```

1. Save the key in the profile:

   ```sh
   kong-harnesses login --profile quickstart
   ```

   `login` asks for the key and doesn't show it as you type.
   Paste the key.

1. Remove the key from the clipboard and from the shell:

   ```sh
   pbcopy < /dev/null
   unset CONSUMER_API_KEY
   ```

After each upgrade of kong-harnesses, run `kong-harnesses login --profile quickstart` once.
Each time the Keychain asks whether kong-harnesses can use the saved key, click **Always Allow**.
{% endnavtab %}
{% navtab "Linux" %}
1. In the shell where you created the key, copy the key:

   ```sh
   printf %s "$CONSUMER_API_KEY" | wl-copy
   ```

   On X11, use `xclip -selection clipboard` in place of `wl-copy`.

1. Save the key in the profile:

   ```sh
   kong-harnesses login --profile quickstart
   ```

   `login` asks for the key and doesn't show it as you type.
   Paste the key.

1. Remove the key from the clipboard and from the shell:

   ```sh
   wl-copy --clear
   unset CONSUMER_API_KEY
   ```

   On X11, use `xclip -selection clipboard < /dev/null` in place of `wl-copy --clear`.
{% endnavtab %}
{% navtab "Windows" %}
1. Turn off **Clipboard history** and **Clipboard history across your devices** in **Settings** > **System** > **Clipboard**.
   Clipboard sync can send the key to your other devices.

1. In the WSL shell where you created the key, copy the key:

   ```sh
   printf %s "$CONSUMER_API_KEY" | clip.exe
   ```

1. In PowerShell, save the key in the profile:

   ```powershell
   kong-harnesses login --profile quickstart
   ```

   `login` asks for the key and doesn't show it as you type.
   Paste the key.

1. In WSL, remove the key from the clipboard and from the shell:

   ```sh
   printf '' | clip.exe
   unset CONSUMER_API_KEY
   ```
{% endnavtab %}
{% endnavtabs %}

If your computer keeps a clipboard history, delete the key from it too.
You can turn clipboard sync on again now.

Configure {{ site.claude_code }} to use the profile:

```sh
kong-harnesses profile activate quickstart --client claude-code
```

`profile activate` sends a test request with the key to the gateway, writes the {{ site.claude_code }} settings, and then runs the `doctor` checks.
It shows each problem that it finds with a fix.
Fix the problems and run the same command again.

Some {{ site.claude_code }} features need a claude.ai or Anthropic Console account, or send data to Anthropic, so they change behind the gateway.
[Features that change behind the gateway](/ai-gateway/set-up-claude-code-with-kong-harnesses/#features-that-change-behind-the-gateway) lists them.

## Validate

Run `kong-harnesses doctor` to check the setup:

```sh
kong-harnesses doctor --profile quickstart --client claude-code
```

`doctor` checks the saved key, the connection to the gateway, the gateway route that {{ site.claude_code }} uses, and the {{ site.claude_code }} settings.
A static-key profile doesn't use an identity provider, so `doctor` skips the issuer check.
It shows a fix for each problem it finds, and it doesn't change any settings.

To also send one model request, add `--inference`.
The request can cost money: the prompt is "Reply with OK." and the answer is at most 16 tokens.

```sh
kong-harnesses doctor --profile quickstart --client claude-code --inference
```

Start a {{ site.claude_code }} session:

```sh
claude
```

Send a prompt to check that you get a reply.
{{ site.claude_code }} now sends every model request to {{site.ai_gateway}} with the key.
