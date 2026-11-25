---
title: "Plan a {{ site.claude_code }} fleet build with kong-harnesses"
description: Choose the delivery method, MCP server mode, host settings, WSL inheritance, version bounds, and model overrides for a {{ site.claude_code }} fleet build with kong-harnesses.

content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - ai
  - anthropic
  - cli

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: Roll out {{ site.claude_code }} through MDM
    url: /kong-harnesses/roll-out-claude-code-through-mdm/
  # TODO: restore when the maintain page is published
  # - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
  #   url: /kong-harnesses/maintain-a-claude-code-fleet/
  - text: Remove a {{ site.claude_code }} fleet build with kong-harnesses
    url: /kong-harnesses/remove-a-claude-code-fleet-build/
  - text: "{{ site.claude_code }} managed settings"
    url: https://code.claude.com/docs/en/managed-settings
---

You can use `kong-harnesses fleet build` to write [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) and a machine-wide profile for one group of computers.
The computers in a group share the platform, the delivery method, the policy, and, for the `exclusive` MCP mode, the `managed-mcp.json` file.
Use this guide to decide how you want to plan your fleet build before you roll-out the build.
For the rollout steps, see [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).

<!-- TODO: link the generated `kong-harnesses fleet build` flag reference here when it is published. -->

{:.warning}
> **Keep secrets out of managed files:** Every account on a computer can read managed settings and `managed-mcp.json`.
> Remove all secrets from the `--policy` and `--mcp-config` files, including secrets in [`env`](https://code.claude.com/docs/en/settings-reference#env), [`ANTHROPIC_CUSTOM_HEADERS`](https://code.claude.com/docs/en/env-vars#variables), and MCP server definitions.
> Use [per-user credentials](https://code.claude.com/docs/en/managed-mcp#authenticate-with-per-user-credentials) instead.

## How {{ site.claude_code }} managed settings work

{{ site.claude_code }} managed settings are the settings that your organization deploys to its developers' computers.
{{ site.claude_code }} gives them precedence over user, project, and local settings, so a developer can't override them.
`fleet build` writes the managed settings that point {{ site.claude_code }} at {{ site.ai_gateway }}.

Each setting is a key in a JSON file, written in camelCase, such as [`apiKeyHelper`](https://code.claude.com/docs/en/settings-reference#apikeyhelper).

### Where managed settings come from

Managed settings reach a computer from three sources.
This table shows where you set each source and when {{ site.claude_code }} reads it:

{% table %}
columns:
  - title: Source
    key: source
  - title: Where you set it
    key: where
  - title: When {{ site.claude_code }} reads it
    key: reads
rows:
  - source: Remote settings
    where: The claude.ai admin console, or a Claude apps gateway
    reads: At startup, and every hour after that
  - source: MDM policy
    where: A configuration profile on macOS, or a registry value under `HKLM` on Windows
    reads: At startup, and when it changes, checked every 30 minutes
  - source: Managed settings files
    where: "`managed-settings.json` and the files in `managed-settings.d/`, in a system folder on each computer"
    reads: At startup, and when a file changes
{% endtable %}

The system folder is `/Library/Application Support/ClaudeCode/` on macOS, `/etc/claude-code/` on Linux and WSL, and `C:\Program Files\ClaudeCode\` on Windows.
`managed-mcp.json` lives in the same folder.

### Which source applies

{{ site.claude_code }} checks the sources in a fixed order.
From highest to lowest, they rank as remote settings, the MDM policy, and the managed settings files.
By default, {{ site.claude_code }} uses only the highest-ranked source that sets a policy key, and skips the rest.
The `Skipped sources` line in `/status` names each source that {{ site.claude_code }} skipped.

You can modify this ranking behavior in the following ways:

* Set [`managedSourcesBehavior`](https://code.claude.com/docs/en/settings-reference#managedsourcesbehavior) to `"merge"` in the highest-ranked source to make {{ site.claude_code }} combine every source instead.
* {{ site.claude_code }} reads a short list of keys from every source, so a lower-ranked source can still set them.
  The list includes `env`, [`deniedMcpServers`](https://code.claude.com/docs/en/settings-reference#deniedmcpservers), and [`allowManagedMcpServersOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedmcpserversonly).
  For the full list, see [Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source).

### Where a setting can live

{{ site.claude_code }} reads settings from four scopes:

* **User:** `~/.claude/settings.json`, which each developer controls
* **Project:** `.claude/settings.json` in a project folder
* **Local:** `.claude/settings.local.json` in a project folder
* **Managed:** The three sources that your organization controls

Some keys work in any scope, and others work only in a managed source.
For example, `deniedMcpServers` works in any scope, so a developer can also set it in their own user settings.
`allowManagedMcpServersOnly` works only in a managed source.

To see which source a computer used, start {{ site.claude_code }}, run `/status`, and read the `Setting sources` line.
To list the invalid entries that {{ site.claude_code }} dropped, run `claude doctor`.
After you deploy a build, [`kong-harnesses doctor`](/kong-harnesses/doctor/) reports the build ID and any gateway MCP server that the settings block.
For the checks to run on a test computer, see [Validate](/kong-harnesses/roll-out-claude-code-through-mdm/#validate).

## Choose the delivery method

You can either deliver the profile with mobile device management (MDM) with `--delivery mdm` or a file with `--delivery file`.
Linux only supports `file`.

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Platforms
    key: platforms
  - title: What to pass
    key: usage
rows:
  - flag: "`--delivery file` (default)"
    platforms: macOS, Linux, Windows
    usage: |
      The build writes `managed-settings.d/kong-harnesses.json`.
      Pass the current `managed-settings.json` with `--policy 'POLICY_FILE'`.
      If there isn't a `managed-settings.json` file, pass `--no-policy`, even when `managed-settings.d/` has files.
  - flag: "`--delivery mdm`"
    platforms: macOS, Windows
    usage: |
      Pass the current MDM policy with `--policy 'POLICY_FILE'`.
      Pass `--no-policy` only when there isn't an MDM policy.
{% endtable %}

An MDM policy that sets {{ site.claude_code }} settings outranks a file build.
{{ site.claude_code }} then uses the `apiKeyHelper` of the MDM policy, or doesn't use a helper when the MDM policy doesn't define one.
For the full ranking, see [How {{ site.claude_code }} combines managed sources](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources).

### Check your existing policy

A policy is the set of {{ site.claude_code }} managed settings that your organization already deploys to its computers.
It can come from three sources: remote settings, an MDM policy, or managed settings files, which are `managed-settings.json` and the drop-in files in `managed-settings.d/`.
You pass the current policy for your delivery method to the build with `--policy`: the `managed-settings.json` file for `--delivery file`, or the MDM policy for `--delivery mdm`.

`fleet build` checks the `--policy` file and refuses any value that conflicts with the gateway, naming each one.
It can't see the other policy sources, so check these yourself before you build:

* **Remote settings:** Move the policy into MDM or `managed-settings.json`.
  Keep remote settings only for [Anthropic-hosted cloud sessions](https://code.claude.com/docs/en/server-managed-settings#choose-between-server-managed-and-endpoint-managed-settings) or unmanaged devices.
  Otherwise, delete them, but only after you deploy to every computer that they cover.
  On managed computers, remove the credentials that load a conflicting remote policy: an organization claude.ai sign-in, `CLAUDE_CODE_OAUTH_TOKEN`, or a direct API key.
  For details, see [Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability).
* **Drop-ins in file builds:** A drop-in is a `.json` file in the `managed-settings.d/` folder, next to `managed-settings.json`.
  {{ site.claude_code }} [merges `managed-settings.json` first, then each drop-in in alphabetical order](https://code.claude.com/docs/en/managed-settings#split-a-file-based-policy-across-teams).
  `--policy` reads only `managed-settings.json`, so `fleet build` can't see your drop-ins.
  A file build also writes its own settings to `managed-settings.d/kong-harnesses.json`.
  This check applies to `--delivery file`.
  For `--delivery mdm`, see Merged sources in this list.

  Check each drop-in for these keys, which conflict with the gateway:
  * [`policyHelper`](https://code.claude.com/docs/en/settings-reference#policyhelper) or `policyHelpers`
  * [`forceLoginMethod`](https://code.claude.com/docs/en/settings-reference#forceloginmethod), [`forceLoginGatewayUrl`](https://code.claude.com/docs/en/settings-reference#forcelogingatewayurl), [`forceLoginOrgUUID`](https://code.claude.com/docs/en/settings-reference#forceloginorguuid), or [`enforceAnthropicSignIn`](https://code.claude.com/docs/en/settings-reference#enforceanthropicsignin)
  * [`allowedProviders`](https://code.claude.com/docs/en/settings-reference#allowedproviders) entries other than `customEndpoint`

  Also confirm that no drop-in that sorts after `kong-harnesses.json` sets `apiKeyHelper`, `env`, or [`modelPicker`](https://code.claude.com/docs/en/settings-reference#modelpicker), because it overrides the value that the build writes.
* **Custom headers:** The build sets `ANTHROPIC_CUSTOM_HEADERS`.
  Move non-secret headers from managed settings files and from drop-ins that sort before `kong-harnesses.json` into `--policy`.
* **Merged sources:** For `managedSourcesBehavior: "merge"` in an MDM build, include the key in `--policy`.
  Confirm that `managed-settings.json` and `managed-settings.d/` don't add conflicting keys or unwanted list entries, such as [`permissions.allow`](https://code.claude.com/docs/en/settings-reference#permissions-allow) rules or [hooks](https://code.claude.com/docs/en/settings-reference#hooks).
  For details, see [Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source).
* **Other keys:** Search each source that you control for these keys, and fix any value that conflicts with the build:
  * `forceLoginOrgUUID` requires claude.ai sign-ins to belong to one Anthropic organization, and it blocks `apiKeyHelper` at startup.
    Remove it.
  * `enforceAnthropicSignIn` requires a claude.ai login on Anthropic's API, or an Enterprise Admin Console sign-in.
    Remove it.
  * [`disableAllHooks`](https://code.claude.com/docs/en/settings-reference#disableallhooks) turns off hooks, and the build adds a hook that reports blocked MCP servers.
    Confirm that it isn't `true`.
  * [`availableModels`](https://code.claude.com/docs/en/settings-reference#availablemodels) restricts which models developers can select, and [`deniedModels`](https://code.claude.com/docs/en/settings-reference#deniedmodels) blocks specific models.
    Confirm that they permit every model of the build.

### MDM policy location

An MDM policy is stored in a different place on each platform, and `--delivery mdm` reads it from a different file for each.
Use this table to find your current policy:

{% table %}
columns:
  - title: Platform
    key: platform
  - title: MDM policy location
    key: location
  - title: "`--policy` file for `--delivery mdm`"
    key: file
rows:
  - platform: macOS
    location: "`com.anthropic.claudecode` preference domain"
    file: "XML `com.anthropic.claudecode.plist`"
  - platform: Windows
    location: "`REG_SZ` value `Settings` under `HKLM\\SOFTWARE\\Policies\\ClaudeCode`"
    file: "`Settings` JSON (not a `.reg` file)"
{% endtable %}

## Choose an MCP server mode

Your profile can list gateway MCP servers.
`--mcp-servers` sets how the managed computers get them, and whether developers can add other MCP servers.
If the profile has gateway MCP servers, the flag is required.
Otherwise, it defaults to `allowlist`.

You can choose one of these modes:

* `exclusive` gives {{ site.claude_code }} only the servers in `managed-mcp.json`, so a developer can't add one.
* `allowlist` lets developers add only the servers that you allow.
* `any` leaves MCP servers to each developer.

Use this table to see what each mode does and which flags it takes:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: What it does
    key: behavior
  - title: Flags
    key: flags
rows:
  - mode: "`exclusive`"
    behavior: |
      Writes `managed-mcp.json` under `root/`, and deploys the gateway servers with it.
      Blocks developer, project, and plugin servers.
      Needs at least one gateway MCP server.
    flags: |
      Pass the current `managed-mcp.json` with `--mcp-config 'MCP_CONFIG_FILE'`.
      Leave the flag out only when there isn't a `managed-mcp.json` file.
      You can't use `--mcp-url`, `--mcp-command`, or `--wsl inherit`.
  - mode: "`allowlist`"
    behavior: |
      Sets `allowManagedMcpServersOnly: true`.
      Joins the valid managed [`allowedMcpServers`](https://code.claude.com/docs/en/settings-reference#allowedmcpservers) entries with the gateway entries and the flag entries.
      Developers run `kong-harnesses profile activate PROFILE_NAME --client claude-code`.
    flags: |
      Add `--mcp-url 'URL_PATTERN'` for each remote server, or `--mcp-command 'COMMAND_JSON_ARRAY'` for each stdio server.
      You can't use `--mcp-config`.
  - mode: "`any`"
    behavior: |
      Doesn't add an MCP lock.
      Existing locks stay active.
      Developers run `kong-harnesses profile activate PROFILE_NAME --client claude-code`.
    flags: You can't use `--mcp-url`, `--mcp-command`, or `--mcp-config`.
{% endtable %}

### Before you build

`fleet build` checks `--policy` and each server that it writes to `managed-mcp.json`.
It refuses a conflict and names the server or key, the cause, and the fix.
Check these before you build:

* **Deny entries:** `deniedMcpServers` is a list of MCP servers that {{ site.claude_code }} never loads.
  A matching entry blocks a server in every mode, including the gateway servers, and nothing overrides it.
  Search every managed source that you control for the key: the MDM policy that you pass to `--policy`, `managed-settings.json`, and each drop-in.
  Remove or narrow each entry that matches a gateway MCP server.
  Developers can also set the key in their own settings, which `fleet build` can't see.
  After you deploy to a test computer, run `kong-harnesses doctor`.
  It lists each gateway MCP server that {{ site.claude_code }} doesn't load, and says whether your organization's denylist or the developer's own settings blocks it.
* **Provided servers:** Remove each [`managedMcpServers`](https://code.claude.com/docs/en/settings-reference#managedmcpservers) entry, which provides a remote MCP server to every user from managed settings, that points to the address of a gateway MCP server, even under another name.
  In the `allowlist` and `any` modes, {{ site.claude_code }} loads the provided server instead of the gateway server, so the gateway server doesn't load with the credential of the profile.
* **Name collisions (`exclusive`):** Rename each `--mcp-config` server that has the same name as a gateway server.
* **Variables in policy entries:** If a result depends on a variable that the `env` of the policy doesn't set, `fleet build` can't tell whether {{ site.claude_code }} loads the server, and refuses it.
  Write the entry as a literal value, or set the variable in the `env` of the policy.
* **MDM allowlists (`allowlist`):** The highest administrator source supplies the locked `allowedMcpServers`, so an MDM build replaces the allowlists in managed settings files.
  Move the entries that you need to `--policy`, `--mcp-url`, or `--mcp-command`.
* **`serverName` entries (`allowlist`):** An `allowedMcpServers` entry names a server with exactly one of `serverName`, `serverUrl`, or `serverCommand`, which match the server by name, by remote URL, or by stdio command.
  Added `serverUrl` entries stop `serverName` entries from matching remote servers, and added `serverCommand` entries stop them from matching stdio servers.
  Replace the matching `serverName` entries with `--mcp-url` or `--mcp-command`.
* **Plugin blockers (`allowlist` and `any`):** {{ site.claude_code }} skips the plugin that `profile activate` installs when any of these is set:
  * A `managed-mcp.json` file exists.
  * [`strictPluginOnlyCustomization`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization), which blocks skills, agents, hooks, and MCP servers from user and project sources, is `true` or a list with `skills`, `agents`, `hooks`, or `mcp`.
  * A marketplace allowlist ([`strictKnownMarketplaces`](https://code.claude.com/docs/en/settings-reference#strictknownmarketplaces), or its alias `allowedMarketplaces`) is set without `{"source": "skills-dir"}`.
  * [`blockedMarketplaces`](https://code.claude.com/docs/en/settings-reference#blockedmarketplaces) lists `{"source": "skills-dir"}`.

  Build with `--mcp-servers exclusive`, or change the setting in `--policy` and in every other managed source.
* **Invalid lists:** If you don't want an allowlist, a denylist, or provided servers, leave the key out of `--policy`.
  {{ site.claude_code }} drops or misreads a `null` or invalid value, so `fleet build` refuses it.
* **CLI startup flags:** Remove `--mcp-config` and `--strict-mcp-config` from wrappers, aliases, and IDE settings.
  When {{ site.claude_code }} can read `managed-mcp.json`, it [exits at startup](https://code.claude.com/docs/en/managed-mcp#servers-passed-with-mcp-config-or-strict-mcp-config) if `--mcp-config` passes servers or you pass `--strict-mcp-config`.

For how {{ site.claude_code }} evaluates each server, see [How a server is evaluated](https://code.claude.com/docs/en/managed-mcp#how-a-server-is-evaluated).

### Allowlist values and quoting

In `allowlist` mode, you list each server that developers may add as a flag value.
Your shell can change these values before `fleet build` reads them, so how you quote them depends on the shell you use.

Pass these values:

* `URL_PATTERN`: A remote URL that starts with `http://`, `https://`, or `*://`, for example, `'https://MCP_HOST/*'`.
  It can have `*` wildcards, and must use visible ASCII characters only.
  Write international host names in `xn--` ASCII form, and percent-encode non-ASCII paths.
* `COMMAND_JSON_ARRAY`: A non-empty JSON array of strings that matches the exact stdio command and its arguments, for example, `'["npx","-y","PACKAGE"]'`.

Don't use `${...}` in these values.
`fleet build` refuses it, because {{ site.claude_code }} [expands `${...}`](https://code.claude.com/docs/en/managed-mcp#how-policy-entries-expand) from the developer's shell and from the managed `env`.

Quote each value, so that the shell keeps the `*` and the JSON quotes:

{% table %}
columns:
  - title: Platform and shell
    key: shell
  - title: How to quote
    key: quote
rows:
  - shell: macOS and Linux
    quote: "Single quotes, for example `--mcp-command '[\"npx\",\"-y\",\"PACKAGE\"]'`."
  - shell: Windows, PowerShell 7.3 or later
    quote: Single quotes, as on macOS and Linux.
  - shell: Windows PowerShell 5.1
    quote: |
      [Windows PowerShell 5.1 strips inner double quotes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing#passing-arguments-that-contain-quote-characters), so escape each one with `\`, for example `--mcp-command '[\"npx\",\"-y\",\"PACKAGE\"]'`.
      This works only when no backslash comes right before a double quote.
      Otherwise, use PowerShell 7.3 or later.
  - shell: Windows, Git Bash
    quote: |
      For a Windows build, use single quotes, as on macOS and Linux.
      For a macOS or Linux build, use PowerShell instead.
      Git Bash turns an argument that starts with `/`, such as `/usr/local/bin/kong-harnesses`, into a Windows path, and `fleet build` then refuses the macOS or Linux `--executable`.
{% endtable %}

## Choose host settings and WSL

Some developers run {{ site.claude_code }} through another app, or inside Windows Subsystem for Linux (WSL), and each of these reads settings differently from a terminal session.
Choose how the build treats them.

### Host settings

Apps that embed {{ site.claude_code }}, such as IDE extensions and Agent SDK apps, can pass their own settings to it.
`--host-settings` controls whether those host apps can add settings to your policy, through the [`parentSettingsBehavior`](https://code.claude.com/docs/en/settings-reference#parentsettingsbehavior) key.

You can choose one of these values:

* `--host-settings ignore` is the default.
  It doesn't write `parentSettingsBehavior`, and keeps any value that the policy sets.
* `--host-settings merge` sets `parentSettingsBehavior: "merge"`.
  It keeps restrictive host settings.
  It also admits host permission allow rules, sandbox network domains, and sandbox read paths, unless one of these managed keys locks them:
  * [`allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly) makes managed settings the only source of permission rules.
  * [`sandbox.network.allowManagedDomainsOnly`](https://code.claude.com/docs/en/settings-reference#sandbox-network-allowmanageddomainsonly) locks the network allowlist to what managed settings define.
  * [`sandbox.filesystem.allowManagedReadPathsOnly`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowmanagedreadpathsonly) honors only the `allowRead` entries that come from managed settings.

  For details, see [Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy).

Confirm that host apps don't pass `forceLoginOrgUUID`, an `availableModels` list that leaves out models of the build, or a plugin blocker.
Claude Desktop doesn't call `apiKeyHelper`.
It needs its own [third-party gateway configuration](https://code.claude.com/docs/en/llm-gateway-connect#desktop-app).

### WSL on Windows

Developers on Windows computers can also run {{ site.claude_code }} inside WSL.
WSL isn't part of the default Windows rollout.
By default, {{ site.claude_code }} in WSL reads only `/etc/claude-code`, not your Windows policy, unless a Windows administrator source enables [`wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings).
The Windows administrator sources are `HKLM\SOFTWARE\Policies\ClaudeCode`, `managed-settings.json`, and `managed-settings.d/`.

To make WSL use the Windows settings of this build, pass `--wsl inherit`.
It sets `wslInheritsWindowsSettings: true` and writes helpers that run the Windows `kong-harnesses.exe` through WSL interop.
It requires:

* Windows interop turned on
* A supported Linux {{ site.claude_code }} install in WSL, as described in [Install in WSL](https://code.claude.com/docs/en/setup#install-in-wsl)
* Any private gateway CA trusted in each WSL distribution

With `--wsl inherit`:

* Gateway MCP servers don't load in WSL in any mode, and you can't use `--mcp-servers exclusive`.
* Enforcement in WSL needs an unchanged {{ site.claude_code }}.
* `env` merges into WSL, so leave `NODE_EXTRA_CA_CERTS`, `CLAUDE_CODE_CLIENT_CERT`, and `CLAUDE_CODE_CLIENT_KEY` out of all three Windows administrator sources.
  {{ site.claude_code }} in WSL can't open the Windows paths that they name.

Without `--wsl inherit`, confirm that all three Windows administrator sources leave out `wslInheritsWindowsSettings` or set it to `null`, `false`, or `"false"`.
Any other value enables inheritance.

### Executable path

The build writes the path of kong-harnesses into the credential helper that {{ site.claude_code }} runs on each managed computer.
So `--executable` is the path where you install kong-harnesses on the managed computers, not on your build computer.
It must be an absolute UTF-8 path, and it can't hold these characters:

* **macOS:** Line breaks and NUL bytes. For MDM builds, also control characters.
* **Linux:** Line breaks and NUL bytes.
* **Windows:** `"`, `%`, `!`, and control characters. With `--wsl inherit`, also `'`. Use the path of `kong-harnesses.exe`, with a drive letter and backslashes.

## Set version bounds

You can limit which {{ site.claude_code }} versions the managed computers may run.
`--claude-code-minimum` sets the oldest version, and `--claude-code-maximum` sets the newest.
You can pass either one or both.

`--claude-code-minimum` writes [`requiredMinimumVersion`](https://code.claude.com/docs/en/settings-reference#requiredminimumversion) and [`minimumVersion`](https://code.claude.com/docs/en/settings-reference#minimumversion).
`--claude-code-maximum` writes [`requiredMaximumVersion`](https://code.claude.com/docs/en/settings-reference#requiredmaximumversion).
Pass each version as three numbers separated by dots, without leading zeros, such as `2.1.300`.

* The minimum can't be earlier than `2.1.163`, the first release that reads version bounds.
* The maximum can't be earlier than `2.1.285`, the first release that keeps every session on the gateway.
* If `--policy` also sets a bound, pass the same version in the flag.
  Bounds in `--policy` still apply.

Version bounds apply at startup and during updates:

* **Startup:** `requiredMinimumVersion` and `requiredMaximumVersion` set the range.
  {{ site.claude_code }} doesn't start outside the range, and prompts for an approved version.
  Running sessions continue until they restart.
* **Native and npm installs:** `minimumVersion` and `requiredMaximumVersion` limit background updates and `claude update`.
* **Homebrew installs:** Updates use `brew upgrade`, so pin the version in your install tool.
* **Claude Desktop:** Deploy a release that bundles a {{ site.claude_code }} version in the range.
  Then keep Claude Desktop from updating out of the range:

{% table %}
columns:
  - title: Platform
    key: platform
  - title: Keep Claude Desktop in the range
    key: how
rows:
  - platform: macOS
    how: "[Turn off automatic updates](https://code.claude.com/docs/en/desktop#device-management-policies) through MDM."
  - platform: Linux
    how: Pin the version in your package manager.
  - platform: Windows
    how: |
      [Turn off automatic updates](https://code.claude.com/docs/en/desktop#device-management-policies) through MDM.
      Microsoft Store installs still update.
{% endtable %}

## Override models

By default, the build takes the models from your profile.
Use `--model` when the managed computers need a different model for a Claude family, for example when you move a family to a newer model.
`--model` changes the models in the managed settings and the machine-wide profile:

* **Family:** `fleet build` detects the `opus`, `sonnet`, `haiku`, or `fable` family from `NEW_MODEL_ID`.
  You can also name the family, for example `--model sonnet=NEW_MODEL_ID`.
  Pass `--model` once for each family that you want to change.
* **Settings and roles:** `fleet build` updates the family slot and each role that used the previous model of the family: `active`, `default`, `subagent`, `background_classifier`, and `auto_mode`.
* **`/cost` rates:** `fleet build` adds [`modelPricing`](https://code.claude.com/docs/en/settings-reference#modelpricing) for the new model when the profile or {{ site.ai_gateway }} provides all the required USD rates: `input`, `output`, `cache_read`, and `cache_write`, or `cache_write_1h` for one-hour prompt caching.
* **Local profile:** The profile on your build computer doesn't change.
  So pass `--model` again on each rebuild, unless you pass `--profile-models`.

## Rebuild from a record

You rebuild when you change a choice, or update a build that you already deployed.
To rebuild, pass the record of the earlier build with `--record`.
The record is the `kong-harnesses-fleet-BUILD_ID.json` file that the earlier build wrote to its `--output-dir`.
`fleet build` uses it to take the settings of the earlier build out of the policy before it applies the new ones.

When you rebuild with `--record`, `fleet build` refuses to drop a choice that the earlier build recorded.
Use this table to keep or revert each choice:

{% table %}
columns:
  - title: Earlier flag
    key: earlier
  - title: Keep
    key: keep
  - title: Revert
    key: revert
rows:
  - earlier: "`--model`"
    keep: Pass `--model` for each family again.
    revert: Leave out the `--model` of the family and pass `--profile-models`.
  - earlier: "`--mcp-servers any` or `exclusive`"
    keep: |
      Pass the mode again.
      For `exclusive`, also pass `--mcp-config 'MCP_CONFIG_FILE'`.
    revert: |
      From `any`, pass `allowlist` or `exclusive`.

      From `exclusive`, remove the build as described in [Remove a {{ site.claude_code }} fleet build with kong-harnesses](/kong-harnesses/remove-a-claude-code-fleet-build/), then start a new build without the old `--record`.
      A remaining `managed-mcp.json` keeps [exclusive control](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) and blocks the gateway MCP plugin, so move your other servers out of it and remove it.
  - earlier: "`--claude-code-minimum` or `--claude-code-maximum`"
    keep: Pass each bound again, or update it.
    revert: |
      Pass `--claude-code-any-version` alone to remove both recorded bounds, or with one bound to remove the other recorded bound.
      Bounds in `--policy` still apply.
  - earlier: "`--host-settings merge`"
    keep: Pass `--host-settings merge`.
    revert: |
      Pass `--host-settings ignore`.
      Then confirm that the MDM policy, `managed-settings.json`, and `managed-settings.d/` don't set `parentSettingsBehavior` to `merge`.
  - earlier: "`--wsl inherit` (Windows)"
    keep: Pass `--wsl inherit`.
    revert: |
      Pass `--wsl ignore`.
      Then confirm that the [Windows administrator sources](#wsl-on-windows) leave out `wslInheritsWindowsSettings` or set it to `null`, `false`, or `"false"`.
  - earlier: "`--mcp-url` or `--mcp-command` (`allowlist`)"
    keep: Pass each server flag again.
    revert: Pass `--gateway-mcp-only` to drop the earlier entries that you don't list.
{% endtable %}

## Common pitfalls

`fleet build` reports most mistakes as errors that name the cause and the fix.
These are the ones to avoid before you run it:

* **`--delivery mdm` on Linux:** Linux reads its policy only from managed settings files. Use `--delivery file`.
* **An MDM policy next to a file build:** An MDM policy that sets {{ site.claude_code }} settings outranks a file build. Build with `--delivery mdm` and pass the policy.
* **Policy sources that `fleet build` can't see:** Remote settings, drop-ins, and other managed sources. See [Check your existing policy](#check-your-existing-policy).
* **No `--policy` or `--no-policy` on a file build:** Pass the current `managed-settings.json`, or `--no-policy` when there isn't one.
* **No `--mcp-servers` when the profile has gateway MCP servers:** Choose `exclusive`, `allowlist`, or `any`.
* **A relative `--executable`:** Pass the absolute path of kong-harnesses on the managed computers, not on the build computer.
* **Unquoted allowlist values:** The shell strips the `*` and the JSON quotes. See [Allowlist values and quoting](#allowlist-values-and-quoting).
* **A rebuild that drops a recorded choice:** Pass each recorded flag again, or revert it as described in [Rebuild from a record](#rebuild-from-a-record).
