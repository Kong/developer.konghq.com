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
        Install {{ site.claude_code }} 2.1.278 or later:

        ```sh
        curl -fsSL https://claude.ai/install.sh | bash
        ```
    - title: A profile from your administrator
      content: |
        Your {{site.ai_gateway}} administrator gives you a profile as an HTTPS URL or a JSON file. The profile names the gateway, the identity provider you sign in with, and the models you can use. It holds no secrets.
    - title: A supported computer
      content: |
        kong-harnesses runs on macOS, on Windows 11, and on Linux desktops with Secret Service, such as Ubuntu 26.04, 24.04 and 22.04, and Red Hat Enterprise Linux 9, on amd64 and arm64.

tldr:
  q: How do I connect {{ site.claude_code }} to {{site.ai_gateway}} on a new computer?
  a: |
    Install kong-harnesses, then run `kong-harnesses setup <profile-url> --client claude-code` with the profile URL from your administrator. Setup signs you in through your browser and configures {{ site.claude_code }}. Run `kong-harnesses doctor` to check the result, then start `claude`.

---

kong-harnesses signs you in to {{site.ai_gateway}} through your browser and gives {{ site.claude_code }} a short-lived access token for each request. It keeps only the renewal credential, in your computer's own secret store: the macOS Keychain, Windows DPAPI, or Secret Service on Linux. No long-lived key goes into the {{ site.claude_code }} settings.

## Install kong-harnesses

{% navtabs "install" %}
{% navtab "macOS and Linux" %}

Install kong-harnesses with [Homebrew](https://brew.sh):

```sh
brew install kong/kong-harnesses/kong-harnesses
```

{% endnavtab %}
{% navtab "Windows and Linux packages" %}

Download the Windows installer (`.msi`) or the Linux package (`.deb` or `.rpm`) for your computer from the [kong-harnesses repository](https://cloudsmith.io/~kong/repos/kong-harnesses/packages/), then install it:

* Windows: `msiexec /i <file>.msi`
* Ubuntu: `sudo apt install ./<file>.deb`
* Red Hat Enterprise Linux: `sudo dnf install ./<file>.rpm`

{% endnavtab %}
{% endnavtabs %}

Check that the install worked:

```sh
kong-harnesses version
```

## Run setup

Run setup with the profile URL or file from your administrator:

```sh
kong-harnesses setup <profile-url> --client claude-code
```

Setup does three things in this order:

1. It shows the gateway and the identity provider of the profile, and asks you to type the profile name. Check that both are the ones your administrator named before you type it.
1. It opens your browser to sign you in. Sign in as you do for other company tools.
1. It configures {{ site.claude_code }} to use the gateway, and then checks the result.

If a step fails, setup stops and names the step. Fix the problem it names and run the same command again. Setup continues from the step that failed.

{:.info}
> Without `--client claude-code`, setup also configures the other agent CLIs on your computer that the profile lists, such as Codex. It shows the list and asks before it changes anything.

## Check the setup

Run the checks:

```sh
kong-harnesses doctor
```

`doctor` checks the sign-in, the connection to the gateway, the gateway route that {{ site.claude_code }} uses, and the {{ site.claude_code }} settings. It shows a fix for each problem it finds. It changes nothing.

To also send one real model request, add `--inference`. The request can cost money: the prompt is "Reply with OK." and the answer is at most 16 tokens.

```sh
kong-harnesses doctor --inference
```

## Start {{ site.claude_code }}

Start a session as usual:

```sh
claude
```

Every model request now goes through {{site.ai_gateway}}. `/model` lists the models that the gateway serves. kong-harnesses renews your access token by itself, so you sign in again only when your sign-in expires or your company revokes it.

On macOS, run `kong-harnesses login` once after each upgrade of kong-harnesses. When the Keychain asks whether kong-harnesses can use its sign-in, select **Always Allow**.

## Features that change behind the gateway

Some {{ site.claude_code }} features need a claude.ai or Anthropic Console account, or send data to Anthropic. Your profile decides which of them setup turns off. To see the features that your profile turns off, and why, run:

```sh
kong-harnesses profile get <profile-name>
```

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Why it is off
    key: why
  - title: What you can do
    key: recover
rows:
  - feature: claude.ai connectors
    why: The gateway sign-in replaces the claude.ai sign-in, so connectors cannot load.
    recover: "Add the MCP servers you need with `claude mcp add`."
  - feature: Fast mode
    why: It works only with the Anthropic API directly, and its check calls `api.anthropic.com`.
    recover: Nothing behind the gateway.
  - feature: "`/bug`, `/feedback` and the feedback survey"
    why: They send your conversation or your ratings to Anthropic.
    recover: Ask your administrator to keep them on in the profile.
  - feature: Cost warnings
    why: They report Anthropic API spend, and a gateway session has none.
    recover: "If the gateway publishes its prices, setup asks whether to install them for `/cost`. Installing them needs administrator rights."
  - feature: Automatic updates
    why: The update check and other background requests go outside the gateway, to Anthropic and GitHub. The same setting turns off release notes, network requests from plugins, cloud sessions and pull request status badges.
    recover: "Run `claude update` when you want a newer release, or ask your administrator to keep automatic updates on in the profile."
  - feature: WebFetch domain check
    why: "{{ site.claude_code }} asks `api.anthropic.com` whether it may fetch each domain."
    recover: "WebFetch still works, without Anthropic's list of blocked domains. To limit the domains, add `WebFetch(domain:...)` permission rules."
  - feature: WebSearch on some models
    why: A model that cannot run WebSearch answers without a search, as if it had searched. For each model that the gateway or the profile names as one that cannot search, WebSearch reports that no search ran.
    recover: Switch to a Claude model with `/model` when you need a web search.
{% endtable %}

A profile can also turn off Anthropic's usage metrics, error reports and feature flags. {{ site.claude_code }} itself hides `/usage-credits`, organization memory sync, Remote Control and the Artifact tool, because they need a claude.ai sign-in or a direct connection to Anthropic.

When your administrator changes the profile, run the same `kong-harnesses setup` command again to apply the change.
