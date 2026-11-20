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
  - text: "{{ site.claude_code }} traffic outside {{site.ai_gateway}}"
    url: /kong-harnesses/claude-code-outside-traffic/

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
        On macOS and Linux, if you open a new terminal for it, export the variables from the other prerequisites again.

tldr:
  q: How do I connect {{ site.claude_code }} to {{site.ai_gateway}} with kong-harnesses?
  a: |
    Protect an AI Model with an `openid-connect` AI Auth Strategy, and create a kong-harnesses profile with your gateway, your identity provider and the model.
    Run `kong-harnesses login --profile <profile>` and `kong-harnesses profile activate <profile> --client claude-code`.
    Check the result with `kong-harnesses doctor --profile <profile> --client claude-code`, and start `claude`.

cleanup:
  inline:
    - title: Clean up kong-harnesses
      content: |
        Remove the {{ site.claude_code }} settings that kong-harnesses added, sign out, and delete the profile:

        ```sh
        kong-harnesses profile cleanup --client claude-code
        kong-harnesses logout --profile quickstart
        kong-harnesses profile delete quickstart
        ```

        `profile delete` asks you to type `quickstart` to confirm.
    - title: Clean up Okta
      content: |
        In the Okta Admin Console, go to **Applications > Applications**, and deactivate the `kong-harnesses` app.
        On the **Inactive** tab, delete the app.
        If you added the `kong-harnesses` access policy, delete it on the **Access Policies** tab of the `default` authorization server.
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

[kong-harnesses](/kong-harnesses/) signs developers in to {{site.ai_gateway}} through their browser and gives {{ site.claude_code }} a short-lived access token when it needs one.
It keeps the sign-in in the computer's own secret store: the macOS Keychain, Windows DPAPI, or Secret Service on Linux.
kong-harnesses doesn't write a long-lived key to the {{ site.claude_code }} settings.

In this guide, you configure {{site.ai_gateway}} and create the kong-harnesses profile as an administrator does.
Then you set up {{ site.claude_code }} as a developer does.

## Create the AI Model

Create the following entities:

* An `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that checks the Okta access token in the `Authorization` header.
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

When `upstream_access_token_header` is `null`, {{site.ai_gateway}} doesn't send the Okta access token to Anthropic.
Anthropic gets only your key.
The strategy accepts any valid access token from your Okta authorization server for the `api://default` audience, also a token that Okta issued to another app.

## Create the kong-harnesses profile

A kong-harnesses profile names the gateway, the identity provider that developers sign in with, and the model that {{ site.claude_code }} starts with.
It holds no secrets.
Create a profile named `quickstart` with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
The gateway origin is `http://127.0.0.1:8000`, the address of the quickstart data plane.
Use `127.0.0.1` instead of `localhost`, because `localhost` depends on the system resolver.

{:.info}
> kong-harnesses accepts a plain `http://` gateway origin only for `localhost` or a loopback address, such as `127.0.0.1` or `[::1]`.
> For every other gateway host, use an `https://` origin with a certificate that the operating system trusts.
> The issuer and its endpoints always need `https://`.
> The omp and pi agent CLIs also work with an `http://` gateway on this computer.
> Codex, OpenCode and Hermes need an `https://` gateway.
> They send the sign-in through proxy settings that kong-harnesses can't check, so kong-harnesses leaves them out on an `http://` gateway.

{:.warning}
> On a shared computer, protect a local gateway with a static key or a separate audience, not with the sign-in that production uses.
> Any program on this computer can listen on the gateway port and get the access token that {{ site.claude_code }} sends.

If you set a proxy with `HTTPS_PROXY`, `HTTP_PROXY`, `ALL_PROXY` or their lowercase forms, add the host of this `http://` gateway to `NO_PROXY` before you continue.
A proxy that carries a request to an `http://` gateway can read your access token.
When a proxy applies to the gateway host, `profile activate` and `setup` don't configure a client.
They stop with an error that names `NO_PROXY`.
`doctor` also fails.

Run the kong-harnesses and `claude` commands of this guide in the same shell, because the `NO_PROXY` setting exists only there.
Before you start `claude` in a new shell, set it again, or add it to your shell profile.
Without it, kong-harnesses doesn't give {{ site.claude_code }} an access token.

The following commands add `127.0.0.1` and `localhost` to `NO_PROXY` and keep the hosts that are already in the list.
Separate the entries in `NO_PROXY` with commas.

{% navtabs "no-proxy" %}
{% navtab "macOS and Linux" %}

```sh
list="127.0.0.1,localhost${no_proxy:+,$no_proxy}${NO_PROXY:+,$NO_PROXY}"
export no_proxy="$list" NO_PROXY="$list"
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
$env:NO_PROXY = '127.0.0.1,localhost' + $(if ($env:NO_PROXY) { ",$env:NO_PROXY" })
```

To keep the setting for new PowerShell windows, add `127.0.0.1,localhost` to the `NO_PROXY` user environment variable.

{% endnavtab %}
{% endnavtabs %}

Create the profile:

{% navtabs "profile-create" %}
{% navtab "macOS and Linux" %}

```sh
kong-harnesses profile create \
  --name quickstart \
  --issuer "$ISSUER_URL" \
  --client-id "$OKTA_CLIENT_ID" \
  --audience api://default \
  --gateway-origin http://127.0.0.1:8000 \
  --model claude-sonnet-5-5
```

{% endnavtab %}
{% navtab "Windows" %}

Run kong-harnesses and {{ site.claude_code }} in PowerShell.
Replace the placeholders with the values of `ISSUER_URL` and `OKTA_CLIENT_ID` from the prerequisites:

```powershell
kong-harnesses profile create --name quickstart --issuer 'YOUR_ISSUER_URL' --client-id 'YOUR_CLIENT_ID' --audience api://default --gateway-origin http://127.0.0.1:8000 --model claude-sonnet-5-5
```

{% endnavtab %}
{% endnavtabs %}

kong-harnesses reads the endpoints of your Okta authorization server from its discovery document, then saves the profile and installs it on this computer.
It also sends a test request without your sign-in to the gateway route of each agent CLI that the profile sets up.
This guide sets up only {{ site.claude_code }}, so you can ignore warnings about other agent CLIs.

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
It shows each problem that it finds with a fix.
Fix the problems and run the same command again.
If `profile activate` asks to install the gateway prices for `/cost`, you can decline, because the install needs administrator rights.

## Features that change behind the gateway

Some {{ site.claude_code }} features need a claude.ai or Anthropic Console account, or send data to Anthropic.
The profile lists which of these features `profile activate` turns off.
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
    why: "{{ site.claude_code }} loads connectors only with a claude.ai sign-in, so they never load with a gateway sign-in. With the developers' own Claude subscriptions, connector traffic goes to `mcp-proxy.anthropic.com`, outside the gateway."
    recover: "Add the MCP servers you need with `claude mcp add`."
  - feature: Fast mode
    why: It bills at a higher rate, and it needs fast mode access on the Anthropic organization behind the gateway.
    recover: "Ask your administrator to set `fast_mode` to `true` in the profile. Fast mode works only on the providers that the [fast mode requirements](https://code.claude.com/docs/en/fast-mode#requirements) list."
  - feature: "`/bug`, `/feedback` and the feedback survey"
    why: They send your conversation or your ratings to Anthropic.
    recover: Ask your administrator to turn them on in the profile.
  - feature: Cost warnings
    why: They report Anthropic API spend, and a gateway session has none.
    recover: Nothing to do.
  - feature: "`/cost` prices"
    why: "{{ site.claude_code }} prices each model at Anthropic's prices, not at your gateway's prices."
    recover: "If the profile or the gateway states prices, `profile activate` asks to install them. The install needs administrator rights, and works only on macOS and Linux. A model without a stated price keeps the price that {{ site.claude_code }} uses by default."
  - feature: Automatic updates
    why: The update check and other background requests go outside the gateway, to Anthropic, GitHub and Homebrew. The setting also turns off automatic plugin updates. It turns off release notes and pull request status badges too, unless the profile turns on a feature such as telemetry.
    recover: "Run `claude update` when you want a newer release, or upgrade a Homebrew, WinGet or Linux package manager install with that package manager. You can also ask your administrator to keep automatic updates on in the profile."
  - feature: WebFetch domain check
    why: "{{ site.claude_code }} asks `api.anthropic.com` whether it may fetch each domain."
    recover: "WebFetch still works, without Anthropic's list of blocked domains. To limit the domains, add `WebFetch(domain:...)` permission rules."
  - feature: WebSearch on some models
    why: Some models cannot search the web, but answer as if they did. When the gateway or the profile names such a model, WebSearch says that no search ran.
    recover: Switch to a Claude model with `/model` when you need a web search.
{% endtable %}

A profile can also turn off Anthropic's usage metrics, error reports and feature flags, and the automatic install of Anthropic's plugin marketplace.
[{{ site.claude_code }} traffic outside {{site.ai_gateway}}](/kong-harnesses/claude-code-outside-traffic/) lists each host that these features contact, and how to turn off each one.
The profile and the {{site.ai_gateway}} route decide whether the advisor tool and tool search of {{ site.claude_code }} are on.
{{ site.claude_code }} itself hides `/usage-credits`, organization memory sync, Remote Control and the Artifact tool, because they need a claude.ai sign-in or a direct connection to Anthropic.

## Validate

Run `kong-harnesses doctor` to check the setup:

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

Start a {{ site.claude_code }} session:

```sh
claude
```

Send a prompt to check that you get a reply.
{{ site.claude_code }} now sends every model request to {{site.ai_gateway}}.
kong-harnesses renews your access token by itself.
Run `kong-harnesses login --profile quickstart` when your sign-in expires or your company revokes it.

On macOS, run `kong-harnesses login --profile quickstart` once after each upgrade of kong-harnesses.
Each time the Keychain asks whether kong-harnesses can use its sign-in, click **Always Allow**.
