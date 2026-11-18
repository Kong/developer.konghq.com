---
title: Set up {{ site.claude_code }} with kong-harnesses
content_type: how_to
permalink: /ai-gateway/set-up-claude-code-with-kong-harnesses/
breadcrumbs:
  - /ai-gateway/

description: Install kong-harnesses, sign in once, and start a {{ site.claude_code }} session that sends every model request through {{site.ai_gateway}}.

products:
  - ai-gateway

works_on:
  - konnect
  - on-prem

automated_tests: false

min_version:
  ai-gateway: '2.4'

tags:
  - ai
  - anthropic

related_resources:
  - text: Proxy AI CLI tools through {{site.ai_gateway}}
    url: /ai-gateway/ai-clis/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/

prereqs:
  skip_product: true
  inline:
    - title: "{{ site.claude_code }}"
      icon_url: /assets/icons/third-party/claude.svg
      content: |
        Install {{ site.claude_code }} 2.1.278 or later. On macOS and Linux:

        ```sh
        curl -fsSL https://claude.ai/install.sh | bash
        ```

        On Windows, in PowerShell:

        ```powershell
        irm https://claude.ai/install.ps1 | iex
        ```

        Open a new terminal and run `claude --version` to check the install. If the terminal cannot find `claude`, do the PATH step that the installer prints.
    - title: A profile from your administrator
      content: |
        Your {{site.ai_gateway}} administrator gives you a profile that signs you in through your browser, as an HTTPS URL or a JSON file. The profile names the gateway, the identity provider you sign in with, and the settings for each agent CLI. It contains settings only.
    - title: A supported computer
      content: |
        kong-harnesses runs on macOS, on Windows 11, and on Linux desktops with Secret Service, such as Ubuntu 26.04, 24.04 and 22.04, and Red Hat Enterprise Linux 9, on amd64 and arm64. Set it up on the desktop you work on, not in WSL, a container or an SSH session.

        If your gateway uses a private certificate authority, ask your administrator to add its certificate to your computer's trust store.

tldr:
  q: How do I connect {{ site.claude_code }} to {{site.ai_gateway}} on a new computer?
  a: |
    Install kong-harnesses, then run `kong-harnesses setup <profile-url> --client claude-code` with the profile URL from your administrator. Setup signs you in through your browser and configures {{ site.claude_code }}. Run `kong-harnesses doctor --client claude-code` to check the result, then start `claude`.

---

kong-harnesses signs you in to {{site.ai_gateway}} through your browser and gives {{ site.claude_code }} a short-lived access token when it needs one. It keeps your sign-in in your computer's own secret store: the macOS Keychain, Windows DPAPI, or Secret Service on Linux. No long-lived key goes into the {{ site.claude_code }} settings.

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

Open a new terminal and check that the install worked:

```sh
kong-harnesses version
```

## Run setup

Run setup with the profile URL from your administrator. For a file, use its path in place of `<profile-url>`.

```sh
kong-harnesses setup <profile-url> --client claude-code
```

Setup does three things in this order:

1. It shows the gateway and the identity provider of the profile, and asks you to type the profile name. Check that both are the ones your administrator named before you type it.
1. It opens your browser to sign you in. Sign in with your company account.
1. It configures {{ site.claude_code }} to use the gateway, and then checks the result.

If a step fails, setup stops and names the step and the problem. Fix the problem and run the same command again. Setup keeps a sign-in that still works and settings that are already in place. For a profile URL, it asks you to type the profile name again.

{:.info}
> Without `--client claude-code`, setup also configures the other agent CLIs on your computer that the profile lists, such as Codex. It shows the list and asks before it changes their settings.

## Check the setup

Run the checks:

```sh
kong-harnesses doctor --client claude-code
```

`doctor` checks the sign-in, the connection to the gateway, the gateway route that {{ site.claude_code }} uses, and the {{ site.claude_code }} settings. It shows a fix for each problem it finds. It does not change any settings. Fix each failure and run it again until no check fails.

To also send one model request, add `--inference`. The request can cost money: the prompt is "Reply with OK." and the answer is at most 16 tokens.

```sh
kong-harnesses doctor --client claude-code --inference
```

## Start {{ site.claude_code }}

Start a session as usual:

```sh
claude
```

Send a prompt to check that you get a reply. Every model request now goes through {{site.ai_gateway}}. `/model` shows the models that the gateway serves. kong-harnesses renews your access token by itself. Run `kong-harnesses login` when your sign-in expires or your company revokes it.

On macOS, run `kong-harnesses login` once after each upgrade of kong-harnesses. Each time the Keychain asks whether kong-harnesses can use its sign-in, click **Always Allow**.

## Features that change behind the gateway

Some {{ site.claude_code }} features need a claude.ai or Anthropic Console account, or send data to Anthropic. Your profile decides which of them setup turns off. To see the {{ site.claude_code }} choices in your profile, run this with the profile name that setup showed:

```sh
kong-harnesses profile get <profile-name>
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
    recover: "If the profile or the gateway states prices, setup asks to install them. The install needs administrator rights, and works only on macOS and Linux. A model without a stated price keeps the price that {{ site.claude_code }} uses by default."
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

A profile can also turn off Anthropic's usage metrics, error reports and feature flags, and the automatic install of Anthropic's plugin marketplace. The profile and the gateway route decide whether the advisor and tool search are on. {{ site.claude_code }} itself hides `/usage-credits`, organization memory sync, Remote Control and the Artifact tool, because they need a claude.ai sign-in or a direct connection to Anthropic.

When your administrator changes the profile, run the same `kong-harnesses setup` command again to apply the change.
