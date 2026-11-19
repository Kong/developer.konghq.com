---
title: Set up {{ site.claude_code }} with kong-harnesses
content_type: how_to
permalink: /ai-gateway/set-up-claude-code-with-kong-harnesses/
breadcrumbs:
  - /ai-gateway/

description: Protect an AI Model with Okta, create a kong-harnesses profile, and start a {{ site.claude_code }} session that sends every model request through {{site.ai_gateway}}.

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
  - ai-auth-strategy
  - ai-model
  - ai-model-provider

tags:
  - ai
  - anthropic
  - openid-connect

related_resources:
  - text: Proxy AI CLI tools through {{site.ai_gateway}}
    url: /ai-gateway/ai-clis/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/
  - text: kong-harnesses setup
    url: /kong-harnesses/setup/

prereqs:
  inline:
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: md/ai-gateway/v2/prereqs/anthropic
    - title: Okta
      icon_url: /assets/icons/okta.svg
      include_content: prereqs/auth/oidc/okta-kong-harnesses
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
        If you open a new terminal for it, export the variables from the other prerequisites again.
    - title: A supported computer
      content: |
        kong-harnesses runs on macOS, on Windows 11, and on Linux desktops with Secret Service, such as Ubuntu 26.04, 24.04 and 22.04, and Red Hat Enterprise Linux 9, on amd64 and arm64.
        Set it up on the desktop you work on, not in WSL, a container or an SSH session.

tldr:
  q: How do I connect {{ site.claude_code }} to {{site.ai_gateway}} with kong-harnesses?
  a: |
    Protect an AI Model with an `openid-connect` AI Auth Strategy, and create a kong-harnesses profile with your gateway, your identity provider and the model. Run `kong-harnesses login --profile <profile>` and `kong-harnesses profile activate <profile> --client claude-code`, check the result with `kong-harnesses doctor --profile <profile> --client claude-code`, and start `claude`.

cleanup:
  inline:
    - title: Clean up kong-harnesses
      content: |
        Remove the settings that kong-harnesses added, sign out, and delete the profile:

        ```sh
        kong-harnesses profile cleanup
        kong-harnesses logout --profile quickstart
        kong-harnesses profile delete quickstart
        ```

        `profile delete` asks you to type `quickstart` to confirm.
    - title: Clean up Okta
      content: |
        In the Okta Admin Console, go to **Applications > Applications**, deactivate the `kong-harnesses` app, and delete it.
        If you added the `kong-harnesses` access policy, delete it on the **Access Policies** tab of the `default` authorization server.
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

[kong-harnesses](/kong-harnesses/) signs developers in to {{site.ai_gateway}} through their browser and gives {{ site.claude_code }} a short-lived access token when it needs one.
It keeps the sign-in in the computer's own secret store: the macOS Keychain, Windows DPAPI, or Secret Service on Linux.
No long-lived key goes into the {{ site.claude_code }} settings.

In this guide, you configure {{site.ai_gateway}} and create the kong-harnesses profile as an administrator does.
Then you set up {{ site.claude_code }} as a developer does.

## Create the AI Model

The AI Model uses the following entities:

* An `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that checks the Okta access token in `Authorization`.
* An [AI Model Provider](/ai-gateway/entities/ai-model-provider/) with your Anthropic key.
* An [AI Model](/ai-gateway/entities/ai-model/) for `claude-sonnet-5-5`.

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: okta-oidc
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Okta OIDC
    name: okta-oidc
    type: openid-connect
    config:
      issuer: !env ISSUER_URL
      audience_required:
        - api://default
      auth_methods:
        - bearer
      bearer_token_param_type:
        - header
      hide_credentials: true
      upstream_access_token_header: null
      cache_tokens_salt: okta-oidc-cache-salt
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
        - !ref okta-oidc#name
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - claude-sonnet-5-5
{% endentity_examples %}

With `upstream_access_token_header: null`, {{site.ai_gateway}} doesn't send the Okta access token to Anthropic.
Anthropic gets only your key.

## Install kong-harnesses

{% navtabs "install" %}
{% navtab "macOS and Linux" %}

Install kong-harnesses with [Homebrew](https://brew.sh):

```sh
brew install kong/kong-harnesses/kong-harnesses
```

{% endnavtab %}
{% navtab "Windows and Linux packages" %}

Download the Windows installer (`.msi`) or the Linux package (`.deb` or `.rpm`) for your computer from the kong-harnesses repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`, then install it:

* Windows: in PowerShell opened as an administrator, run `msiexec /i <file>.msi`
* Ubuntu: `sudo apt install ./<file>.deb`
* Red Hat Enterprise Linux: `sudo dnf install ./<file>.rpm`

{% endnavtab %}
{% endnavtabs %}

Check that the install worked:

```sh
kong-harnesses version
```

If the shell can't find `kong-harnesses`, open a new terminal, and export the variables from the prerequisites again.

## Create the kong-harnesses profile

A kong-harnesses profile names the gateway, the identity provider that developers sign in with, and the model that {{ site.claude_code }} starts with.
It contains settings only.
Create a profile named `quickstart` with [`kong-harnesses profile create`](/kong-harnesses/profile/create/):

{% navtabs "profile-create" %}
{% navtab "macOS and Linux" %}

```sh
kong-harnesses profile create \
  --name quickstart \
  --issuer "$ISSUER_URL" \
  --client-id "$OKTA_CLIENT_ID" \
  --audience api://default \
  --gateway-origin "$KONNECT_PROXY_URL" \
  --model claude-sonnet-5-5
```

{% endnavtab %}
{% navtab "Windows" %}

Run kong-harnesses and {{ site.claude_code }} in PowerShell.
Replace the placeholders with the values of `ISSUER_URL`, `OKTA_CLIENT_ID` and `KONNECT_PROXY_URL` from the prerequisites:

```powershell
kong-harnesses profile create --name quickstart --issuer 'YOUR_ISSUER_URL' --client-id 'YOUR_CLIENT_ID' --audience api://default --gateway-origin 'YOUR_PROXY_URL' --model claude-sonnet-5-5
```

{% endnavtab %}
{% endnavtabs %}

kong-harnesses reads the endpoints of your Okta authorization server from its discovery document, then saves the profile and installs it on this computer.
It also sends a test request to the gateway route of each agent CLI that the profile sets up.
This guide creates only the route that {{ site.claude_code }} uses, so `profile create` warns about the Codex and OpenCode routes.
You can ignore these warnings.

{:.info}
> In production, the administrator creates the profile once and gives developers its HTTPS URL or a JSON file.
> A developer then runs [`kong-harnesses setup`](/kong-harnesses/setup/) with it:
>
> ```sh
> kong-harnesses setup <profile-url> --client claude-code
> ```
>
> `setup` installs the profile, signs the developer in, and configures {{ site.claude_code }} in one run.
> When the administrator changes the profile, developers run the same `setup` command again.

## Sign in and configure {{ site.claude_code }}

Sign in to the profile:

```sh
kong-harnesses login --profile quickstart
```

kong-harnesses opens your browser.
Sign in with your Okta account.

Configure {{ site.claude_code }} to use the profile:

```sh
kong-harnesses profile activate quickstart --client claude-code
```

`profile activate` sends a test request with your sign-in to the gateway, writes the {{ site.claude_code }} settings, and then runs the `doctor` checks.
If a step fails, it names the step and the problem.
Fix the problem and run the same command again.

## Features that change behind the gateway

Some {{ site.claude_code }} features need a claude.ai or Anthropic Console account, or send data to Anthropic.
The profile decides which of them `profile activate` turns off.
To see the {{ site.claude_code }} choices in the profile, run:

```sh
kong-harnesses profile get quickstart
```

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Why it changes
    key: why
  - title: What you can do
    key: recover
rows:
  - feature: claude.ai connectors
    why: The gateway sign-in replaces the claude.ai sign-in, so connectors cannot load.
    recover: "Add the MCP servers you need with `claude mcp add`."
  - feature: Fast mode
    why: It works only with the Anthropic API directly, and its check calls `api.anthropic.com`.
    recover: "Nothing to do: Fast mode cannot work behind the gateway."
  - feature: "`/bug`, `/feedback` and the feedback survey"
    why: They send your conversation or your ratings to Anthropic.
    recover: Ask your administrator to keep them and automatic updates on in the profile.
  - feature: Cost warnings
    why: They report Anthropic API spend, and a gateway session has none.
    recover: Nothing to do.
  - feature: "`/cost` prices"
    why: "{{ site.claude_code }} prices each model at Anthropic's prices, not at your gateway's prices."
    recover: "If the profile or the gateway states prices, `profile activate` asks to install them. The install needs administrator rights, and works only on macOS and Linux. A model without a stated price keeps the price that {{ site.claude_code }} uses by default."
  - feature: Automatic updates
    why: The update check and other background requests go outside the gateway, to Anthropic and GitHub. The same setting turns off release notes, network requests from plugins, cloud sessions and pull request status badges.
    recover: "Run `claude update` when you want a newer release, or ask your administrator to keep automatic updates on in the profile."
  - feature: WebFetch domain check
    why: "{{ site.claude_code }} asks `api.anthropic.com` whether it may fetch each domain."
    recover: "WebFetch still works, without Anthropic's list of blocked domains. To limit the domains, add `WebFetch(domain:...)` permission rules."
  - feature: WebSearch on some models
    why: Some models cannot search the web, but answer as if they did. When the gateway or the profile names such a model, WebSearch says that no search ran.
    recover: Switch to a Claude model with `/model` when you need a web search.
{% endtable %}

A profile can also turn off Anthropic's usage metrics, error reports and feature flags, and the automatic install of Anthropic's plugin marketplace.
The profile and the gateway route decide whether the advisor and tool search are on.
{{ site.claude_code }} itself hides `/usage-credits`, organization memory sync, Remote Control and the Artifact tool, because they need a claude.ai sign-in or a direct connection to Anthropic.

## Validate

Run the checks:

```sh
kong-harnesses doctor --profile quickstart --client claude-code
```

`doctor` checks the sign-in, the connection to the gateway, the gateway route that {{ site.claude_code }} uses, and the {{ site.claude_code }} settings.
It shows a fix for each problem it finds.
It doesn't change any settings.
Fix each failure and run it again until no check fails.

To also send one model request, add `--inference`.
The request can cost money: the prompt is "Reply with OK." and the answer is at most 16 tokens.

```sh
kong-harnesses doctor --profile quickstart --client claude-code --inference
```

Start a session as usual:

```sh
claude
```

Send a prompt to check that you get a reply.
Every model request now goes through {{site.ai_gateway}}.
kong-harnesses renews your access token by itself.
Run `kong-harnesses login --profile quickstart` when your sign-in expires or your company revokes it.

On macOS, run `kong-harnesses login --profile quickstart` once after each upgrade of kong-harnesses.
Each time the Keychain asks whether kong-harnesses can use its sign-in, click **Always Allow**.
