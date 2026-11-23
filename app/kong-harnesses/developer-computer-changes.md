---
title: "Changes that {{site.kong_harnesses}} makes on a developer's computer"
description: "See what {{site.kong_harnesses}} setup saves and writes on a developer's computer for each provider mode, and what profile cleanup restores."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

min_version:
  ai-gateway: '2.4'

tags:
  - cli

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: "{{site.kong_harnesses}} profiles for administrators"
    url: /kong-harnesses/profiles-for-administrators/
  - text: kong-harnesses setup
    url: /kong-harnesses/setup/
  - text: kong-harnesses profile cleanup
    url: /kong-harnesses/profile/cleanup/
---

[`kong-harnesses setup`](/kong-harnesses/setup/) installs a {{site.kong_harnesses}} profile on a developer's computer, signs the developer in, and writes the settings of each agent CLI that the profile sets up.
To write and publish the profile, see [{{site.kong_harnesses}} profiles for administrators](/kong-harnesses/profiles-for-administrators/).

## Setup

A developer installs the profile with `setup`, from a URL or from a file.

From an HTTPS URL:

```sh
kong-harnesses setup PROFILE_URL
```

From a local JSON file:

```sh
kong-harnesses setup ./PROFILE_NAME.json
```

`setup` runs the following steps in order:

1. `profile import` shows the gateway and the identity provider of the profile, asks the developer to type the profile name, and installs the profile.
1. `login` signs the developer in, and saves the renewal credential or the static key in the operating system's credential store.
   When the developer enters the key of a gateway MCP server that asks for one, `login` saves that key in the same store.
1. `profile activate` writes the settings of each agent CLI that `setup` sets up.

`setup` skips `login` for an `environment-key` profile.
`setup` also skips `login` when every agent CLI that `setup` sets up is OpenCode or Hermes Agent, because these agent CLIs sign in through their own plugins.
After `setup` sets up OpenCode or Hermes Agent, the developer runs the sign-in command that `kong-harnesses status` names for that agent CLI, and then restarts the agent CLI.
This sign-in is also needed when the same run sets up {{ site.claude_code }}.

When the command doesn't name `--client`, `setup` sets up every installed agent CLI that the profile lists and that passes the [agent CLI checks](#agent-cli-checks).
Add `--client claude-code` to set up only {{ site.claude_code }}.

When the developer adds `--auto-approve`, `setup` doesn't ask the developer to type the profile name or to confirm the list of agent CLIs, and prints the import summary to stderr.
The sign-in step still opens the browser, or asks for the static key.
Use `--auto-approve` only in an onboarding script that your organization owns, because `--auto-approve` skips the developer's check of the gateway and the identity provider.

When a step fails, `setup` stops and names the step.
Fix the reported error, then run the same `setup` command again.
A step that is already done doesn't change anything: a sign-in that works stays, and an agent CLI that is already set up stays as it is.

### Agent CLI checks

Before `setup` sets up an agent CLI, `setup` sends a test request to the gateway route of that agent CLI.
The test request contains the developer's sign-in, unless the agent CLI signs in through its own plugin or the profile uses the `subscription` sign-in.

In the following cases, `setup` warns that the agent CLI may not reach the gateway, tells the developer to send a prompt from that agent CLI to check, and goes on to the next check of the agent CLI:

- `setup` can't build a request like the one that the agent CLI sends, for example because the {{ site.claude_code }} managed settings set a credential, a gateway URL or a proxy.
  `setup` then doesn't send a test request.
- The gateway doesn't have a route for the test request or refuses the test request, and the test request doesn't contain a part that the agent CLI adds itself, such as a header from the agent CLI's own settings or a client certificate.
  A route can depend on that missing part.
- For a `subscription` profile, the gateway asks for the developer's Claude sign-in before the gateway routes the test request.

A later check can still stop `setup` before `setup` writes the settings of any agent CLI.

In the following cases, a check fails, and `setup` names the fix for the agent CLI:

- The gateway route of the agent CLI is missing, or the gateway refuses the sign-in.
- The profile uses a plain `http://` gateway, and the agent CLI is Codex, OpenCode or Hermes Agent.
- The agent CLI is OpenCode, and its npm plugin registry uses plain `http://` on another computer.

When the command doesn't name `--client`, `setup` leaves out each agent CLI that fails a check and sets up the remaining agent CLIs, or stops when none remain.
When the command names `--client`, `setup` stops.
Before `setup` writes any settings, `setup` checks that each remaining agent CLI can use the profile.
When one of them can't, `setup` stops and doesn't write the settings of any agent CLI.

## {{ site.claude_code }} settings

`profile activate` writes the following keys to the {{ site.claude_code }} user settings, `~/.claude/settings.json`.
When `CLAUDE_CONFIG_DIR` is set, `profile activate` writes the keys to `settings.json` in `CLAUDE_CONFIG_DIR` instead.

{% table %}
columns:
  - title: Key
    key: key
  - title: Value
    key: value
rows:
  - key: "`apiKeyHelper`"
    value: |
      A command that runs `kong-harnesses credential` for the profile.
      {{ site.claude_code }} runs that command to get a short-lived access token, or the key of a `static-key` or `environment-key` profile.
      A `subscription` profile doesn't write `apiKeyHelper`, and removes an `apiKeyHelper` that the file already contains.
      `profile cleanup` restores the removed value.
  - key: "`env.CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY`"
    value: |
      `1`, which turns on the model discovery from the gateway.
      Discovery has an effect only in the `anthropic` mode.
  - key: "`env.CLAUDE_CODE_API_KEY_HELPER_TTL_MS`"
    value: "`300000`, a 5-minute cache for the `apiKeyHelper` result."
  - key: "`env.ANTHROPIC_AUTH_TOKEN` and `env.ANTHROPIC_API_KEY`"
    value: Empty, so a key in the shell doesn't replace the sign-in.
  - key: "Model keys, such as `env.ANTHROPIC_MODEL`"
    value: The models that the profile names.
  - key: "Feature switches, such as `env.DISABLE_TELEMETRY`"
    value: "The {{ site.claude_code }} features that the profile turns off or on."
  - key: "`env.ANTHROPIC_CUSTOM_HEADERS`"
    value: The headers that the profile's `attribution` block names, when the profile has one.
  - key: "`hooks`"
    value: |
      For a `subscription` profile, a hook on {{ site.claude_code }} session events adds `x-kong-id-token` with a short-lived access token from the identity provider to `env.ANTHROPIC_CUSTOM_HEADERS`, so the gateway can identify the developer of each request.
      The hook makes the settings file readable by its owner only, because the header contains a token.
      `profile activate` itself doesn't write a token.
      When the gateway or the profile names a model that can't run WebSearch, a `PostToolUse` hook on WebSearch replaces a result without a search with a statement that no search ran.
{% endtable %}

Each provider mode also writes its own keys:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Keys
    key: keys
rows:
  - mode: "`anthropic`"
    keys: "`env.ANTHROPIC_BASE_URL` set to the gateway origin."
  - mode: "`foundry`"
    keys: "`env.CLAUDE_CODE_USE_FOUNDRY` and `env.CLAUDE_CODE_SKIP_FOUNDRY_AUTH` set to `1`, and `env.ANTHROPIC_FOUNDRY_BASE_URL` set to the gateway origin."
  - mode: "`mantle`"
    keys: "`env.CLAUDE_CODE_USE_MANTLE` and `env.CLAUDE_CODE_SKIP_MANTLE_AUTH` set to `1`, and `env.ANTHROPIC_BEDROCK_MANTLE_BASE_URL` set to the gateway origin."
{% endtable %}

In the `foundry` and `mantle` modes, `profile activate` also writes the following keys:

- `availableModels`, an allowlist with only the profile's models, so the model picker shows only these models
- `replaceBuiltInOptions`, which hides the built-in models
- `env.ANTHROPIC_DEFAULT_MODEL`, set to the profile's default model

`profile activate` also writes the settings of each other agent CLI that the profile sets up.
For the settings of the other agent CLIs, see [`profile activate`](/kong-harnesses/profile/activate/).
`profile activate` refuses a credential that the {{ site.claude_code }} settings file already contains in `env.ANTHROPIC_AUTH_TOKEN` or `env.ANTHROPIC_API_KEY`.
In the `foundry` mode, [`doctor`](/kong-harnesses/doctor/) fails when the shell or the settings file sets `ANTHROPIC_FOUNDRY_API_KEY` or `ANTHROPIC_FOUNDRY_AUTH_TOKEN`, because {{ site.claude_code }} would send that key instead of the sign-in.

## Cleanup

[`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) restores each value that activation replaced, when the key still has the value that activation wrote.
A value that the developer changed after activation stays as the developer left it.
Cleanup changes only agent CLI settings, and keeps the installed profiles and the saved sign-ins.
