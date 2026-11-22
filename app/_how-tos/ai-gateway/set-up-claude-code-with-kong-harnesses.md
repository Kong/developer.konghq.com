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
  - text: "{{ site.claude_code }} on the web and Claude in Slack"
    url: /kong-harnesses/claude-code-web-and-slack/

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
        Install {{ site.claude_code }} 2.1.284 or later.
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

[kong-harnesses](/kong-harnesses/) signs developers in to {{site.ai_gateway}} through their browser and gives {{ site.claude_code }} a short-lived access token when needed.
It stores the sign-in in the operating system secret store (macOS Keychain, Windows DPAPI, or Secret Service on Linux) rather than writing a long-lived key to {{ site.claude_code }} settings.

In this guide, you configure {{site.ai_gateway}} and create the kong-harnesses profile as an administrator, then set up {{ site.claude_code }} as a developer.

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

A kong-harnesses profile names the gateway, the identity provider, and the starting model for {{ site.claude_code }}.
It doesn't store secrets.
The gateway origin for the quickstart data plane is `http://127.0.0.1:8000`.
Use `127.0.0.1` instead of `localhost`, because `localhost` depends on the system resolver.

{:.info}
> kong-harnesses accepts a plain `http://` gateway origin only for `localhost` or a loopback address, such as `127.0.0.1` or `[::1]`.
> For every other gateway host, use an `https://` origin with a certificate that the operating system trusts.
> The issuer and its endpoints always need `https://`.
> Only {{ site.claude_code }}, omp, and pi work with an `http://` gateway.
> Codex, OpenCode, and Hermes Agent need an `https://` gateway.
> See [Plain HTTP gateways](/kong-harnesses/profile-file/#plain-http-gateways) for the client rules.

{:.warning}
> On a shared computer, protect a local gateway with a static key or a separate audience, not with the sign-in that production uses.
> Any program on this computer can listen on the gateway port and get the access token that {{ site.claude_code }} sends.

If `HTTPS_PROXY`, `HTTP_PROXY`, `ALL_PROXY`, or their lowercase forms are set, add `127.0.0.1` and `localhost` to `NO_PROXY` (and `no_proxy` on macOS and Linux) before you continue.
A proxy that forwards a request to an `http://` gateway can read your access token.
When a proxy applies to the gateway host in the current shell, `profile activate` and `setup` don't configure a client and stop with an error that names `NO_PROXY`.
When `profile activate` configures {{ site.claude_code }} for an `http://` gateway, it writes `NO_PROXY` and `no_proxy` into {{ site.claude_code }} user settings.
{{ site.claude_code }} uses those settings values instead of the shell's `NO_PROXY` for its own requests and passes them to subprocesses it starts, including the kong-harnesses credential helper.
`kong-harnesses credential` and `kong-harnesses token` check only their own process environment, without reading settings files, and withhold the access token when a proxy applies to the gateway host there.
`doctor` fails when a proxy applies to the gateway host before `profile activate` writes those settings.
It also fails when project or managed settings could send the gateway through a proxy, or when `doctor` can't check project or managed proxy settings.
Separate `NO_PROXY` entries with commas, and keep the setting in every shell where you run kong-harnesses, or add it to your shell profile:

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

Create a profile named `quickstart` with [`kong-harnesses profile create`](/kong-harnesses/profile/create/):

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

In PowerShell, replace the placeholders with `ISSUER_URL` and `OKTA_CLIENT_ID` from the prerequisites:

```powershell
kong-harnesses profile create --name quickstart --issuer 'YOUR_ISSUER_URL' --client-id 'YOUR_CLIENT_ID' --audience api://default --gateway-origin http://127.0.0.1:8000 --model claude-sonnet-5-5
```

{% endnavtab %}
{% endnavtabs %}

kong-harnesses reads your Okta endpoints from the discovery document, saves and installs the profile, and sends an unauthenticated test request to each configured agent CLI route.
Because this guide sets up only {{ site.claude_code }}, ignore warnings about other agent CLIs.

{:.info}
> In production, the administrator creates the profile once and shares its HTTPS URL or JSON file with developers, who run [`kong-harnesses setup`](/kong-harnesses/setup/):
>
> ```sh
> kong-harnesses setup <profile-url> --client claude-code
> ```
>
> `setup` installs the profile, signs the developer in, and configures {{ site.claude_code }} in one run.
> When the profile changes, developers run the same `setup` command again.

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
Follow each `fix:` line that appears, fix any remaining problems, and run the same command again.
If `profile activate` asks to install the gateway prices for `/cost`, you can decline, because the install needs administrator rights.

## Features that change behind the gateway

Some {{ site.claude_code }} features need a claude.ai or Anthropic Console account, send data to Anthropic, or behave differently with gateway models.
To inspect the {{ site.claude_code }} choices in the profile, run:

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
  - feature: Cost warnings
    why: They report Anthropic API spend, and a gateway session doesn't incur Anthropic API spend.
    recover: Nothing to do.
  - feature: "`/cost` prices"
    why: "{{ site.claude_code }} prices each model at Anthropic's prices, not at your gateway's prices."
    recover: >-
      If the profile or the gateway states prices, `profile activate` asks to install them.
      The install needs administrator rights, and works only on macOS and Linux.
      A model without a stated price keeps the price that {{ site.claude_code }} uses by default.
  - feature: WebSearch on some models
    why: >-
      Some models cannot search the web, but answer as if they did.
      When the gateway or the profile names such a model, WebSearch says that no search ran.
    recover: Switch to a Claude model with `/model` when you need a web search.
{% endtable %}

A profile also controls features that contact Anthropic or other hosts outside the gateway, including claude.ai connectors, fast mode, `/bug`, `/feedback`, the feedback survey, automatic updates, the WebFetch domain check, usage metrics, feature flags, and automatic install of Anthropic's plugin marketplace.
[{{ site.claude_code }} traffic outside {{site.ai_gateway}}](/kong-harnesses/claude-code-outside-traffic/) lists each host that these features contact, what changes when they are off, and how to change them.
[{{ site.claude_code }} on the web and Claude in Slack](/kong-harnesses/claude-code-web-and-slack/) explains how to turn off Claude products that run sessions outside the developer's computer, without the gateway.
The profile and the {{site.ai_gateway}} route decide whether the advisor tool and tool search of {{ site.claude_code }} are on.
{{ site.claude_code }} itself hides `/usage-credits`, organization memory sync and Remote Control, because they need a claude.ai sign-in or a direct connection to Anthropic.
The Artifact tool works only in the cases that [Artifact availability](/kong-harnesses/claude-code-outside-traffic/#artifact-availability) lists.

## Validate

Run `kong-harnesses doctor` to check the setup:

```sh
kong-harnesses doctor --profile quickstart --client claude-code
```

`doctor` checks the sign-in, gateway connection, {{ site.claude_code }} gateway route, and {{ site.claude_code }} settings without changing any settings.
Follow each `fix:` line that appears, resolve any failure it reports, and run `doctor` again until all checks pass.

The model request of `--inference` can cost money: the prompt is "Reply with OK." and the answer is at most 16 tokens.
To also send one model request, add `--inference`:

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
