---
title: "Changes that {{site.kong_harnesses}} makes on a developer's computer"
description: "See what `kong-harnesses setup` saves and writes on a developer's computer for each provider mode, and what `profile cleanup` restores."
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
  - text: kong-harnesses profiles for administrators
    url: /kong-harnesses/profiles-for-administrators/
  - text: kong-harnesses setup
    url: /kong-harnesses/setup/
  - text: kong-harnesses profile cleanup
    url: /kong-harnesses/profile/cleanup/
---

[`kong-harnesses setup`](/kong-harnesses/setup/) installs a {{site.kong_harnesses}} profile on a developer's computer, signs the developer in, and writes the settings of each agent CLI that the profile sets up.
To write and publish the profile, see [{{site.kong_harnesses}} profiles for administrators](/kong-harnesses/profiles-for-administrators/).

## Setup

A developer installs the profile with `setup` and the URL or the file:

```sh
kong-harnesses setup PROFILE_URL
```

```sh
kong-harnesses setup ./PROFILE_NAME.json
```

`setup` runs `profile import`, `login` and `profile activate`, in this order.
Before it installs the profile, it shows the gateway and the identity provider of the profile, and asks the developer to type the profile name.
It skips `login` for an `environment-key` profile, and when every agent CLI that it sets up is OpenCode or Hermes Agent, which sign in through their own plugins.
When the command doesn't name `--client`, `setup` sets up every installed agent CLI that the profile lists.
Add `--client claude-code` to set up only {{ site.claude_code }}.

When the developer adds `--auto-approve`, `setup` doesn't ask the developer to type the profile name or to confirm the list of agent CLIs, and prints the import summary to stderr.
The sign-in step still opens the browser, or asks for the static key.
Use `--auto-approve` only in an onboarding script that your organization owns, because it skips the developer's check of the gateway and the identity provider.
When a step fails, `setup` stops and names the step.
Fix the reported error, then run the same `setup` command again.
A step that is already done changes nothing: a sign-in that works stays, and an agent CLI that is already set up stays as it is.
When the gateway refuses an agent CLI, for example because its route is missing or refuses the sign-in, `setup` names the fix.
When the command doesn't name `--client`, `setup` leaves that agent CLI out and sets up the others.
When the command names `--client`, `setup` stops.
When an agent CLI can't take the profile, `setup` stops before it writes the settings of any agent CLI.
Fix the cause, then run `setup` again.

`login` saves the sign-in in the operating system's credential store: only the renewal credential, or the static key.

## {{ site.claude_code }} settings

`profile activate` writes these keys to the {{ site.claude_code }} user settings, `~/.claude/settings.json`, or `settings.json` in `CLAUDE_CONFIG_DIR` when it's set:

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
      {{ site.claude_code }} runs it to get a short-lived access token, or the static key of a key profile.
      A `subscription` profile doesn't write it, and removes an `apiKeyHelper` that the file already contains.
      `profile cleanup` restores the removed value.
  - key: "`env.CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY` and `env.CLAUDE_CODE_API_KEY_HELPER_TTL_MS`"
    value: |
      `1`, and a 5-minute cache for the `apiKeyHelper` result.
      Discovery has an effect only in the `anthropic` mode.
  - key: "`env.ANTHROPIC_AUTH_TOKEN` and `env.ANTHROPIC_API_KEY`"
    value: Empty, so a key in the shell doesn't replace the sign-in.
  - key: "Model keys, such as `env.ANTHROPIC_MODEL`"
    value: The models that the profile names.
  - key: "Feature switches, such as `env.DISABLE_TELEMETRY`"
    value: "The {{ site.claude_code }} features that the profile turns off or on."
  - key: "`env.ANTHROPIC_CUSTOM_HEADERS`"
    value: |
      The headers that the profile's `attribution` block names, when the profile has one.
      For a `subscription` profile, the session hook in the `hooks` row adds the `x-kong-id-token` header.
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
    keys: |
      `env.CLAUDE_CODE_USE_FOUNDRY` and `env.CLAUDE_CODE_SKIP_FOUNDRY_AUTH` set to `1`, and `env.ANTHROPIC_FOUNDRY_BASE_URL` set to the gateway origin.
      The model picker and the `availableModels` allowlist show only the profile's models, `replaceBuiltInOptions` hides the built-in models, and `env.ANTHROPIC_DEFAULT_MODEL` is the profile's default model.
  - mode: "`mantle`"
    keys: |
      `env.CLAUDE_CODE_USE_MANTLE` and `env.CLAUDE_CODE_SKIP_MANTLE_AUTH` set to `1`, and `env.ANTHROPIC_BEDROCK_MANTLE_BASE_URL` set to the gateway origin.
      The model picker and the `availableModels` allowlist show only the profile's models, `replaceBuiltInOptions` hides the built-in models, and `env.ANTHROPIC_DEFAULT_MODEL` is the profile's default model.
{% endtable %}

`profile activate` also writes the settings of each other agent CLI that the profile sets up.
For these settings, see [`profile activate`](/kong-harnesses/profile/activate/).
`profile activate` refuses a credential that the {{ site.claude_code }} settings file already contains in `env.ANTHROPIC_AUTH_TOKEN` or `env.ANTHROPIC_API_KEY`.
In the `foundry` mode, [`doctor`](/kong-harnesses/doctor/) fails when the shell or the settings file sets `ANTHROPIC_FOUNDRY_API_KEY` or `ANTHROPIC_FOUNDRY_AUTH_TOKEN`, because {{ site.claude_code }} would send that key instead of the sign-in.

## Cleanup

[`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) restores each value that activation replaced, when the key still has the value that activation wrote.
A value that the developer changed after activation stays as the developer left it.
Cleanup changes only agent CLI settings, and keeps the installed profiles and the saved sign-ins.
