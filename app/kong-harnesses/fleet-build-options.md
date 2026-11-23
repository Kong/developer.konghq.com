---
title: "{{ site.claude_code }} fleet build options"
description: Delivery methods, existing policy rules, MCP server modes, host settings, WSL inheritance, recorded flags, version bounds, and model overrides for kong-harnesses fleet builds.

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
  - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
    url: /kong-harnesses/maintain-a-claude-code-fleet/
  - text: Remove a {{ site.claude_code }} fleet build
    url: /kong-harnesses/remove-a-claude-code-fleet-build/
  - text: Troubleshoot a {{ site.claude_code }} fleet
    url: /kong-harnesses/troubleshooting/claude-code-fleet/
  - text: kong-harnesses errors and exit codes
    url: /kong-harnesses/errors/
  - text: "{{ site.claude_code }} managed settings"
    url: https://code.claude.com/docs/en/managed-settings
---

`kong-harnesses fleet build` writes [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) and a machine-wide profile for one group of computers.
The computers in a group share the platform, the delivery method, the policy, and, for the `exclusive` MCP mode, the `managed-mcp.json` file.
This page describes the build options.
For the rollout steps, see [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).

{:.warning}
> **Keep secrets out of managed files:** Every account on a computer can read managed settings and `managed-mcp.json`.
> Remove all secrets from the `--policy` and `--mcp-config` files, including secrets in `env`, `ANTHROPIC_CUSTOM_HEADERS`, and MCP server definitions.
> Use [per-user credentials](https://code.claude.com/docs/en/managed-mcp#authenticate-with-per-user-credentials) instead.

## Delivery method and existing policy

The delivery method decides where the build puts the managed settings.
Choose it from the policy sources that your computers already have.

### How managed sources rank

{{ site.claude_code }} ranks the managed sources in this [precedence order](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources), highest first:

1. Remote settings, from the claude.ai admin console or the Claude apps gateway
1. MDM policy, at the [MDM policy location](#mdm-policy-location)
1. Managed settings files, `managed-settings.json` and `managed-settings.d/`

A policy key is any key other than `managedSourcesBehavior` and `wslInheritsWindowsSettings`.
A policy value is a value other than `null` or an empty object that a source sets for a policy key.
An object that holds only empty objects also counts as empty.
`false`, `0`, and `""` count as policy values.
These don't count as policy values:

* `false` or `"false"` for `disableAutoMode`, `disableDeepLinkRegistration`, `permissions.disableBypassPermissionsMode`, or `permissions.disableAutoMode`
* An `env` that isn't an object
* A `null` under `permissions`

By default, {{ site.claude_code }} reads most keys, including `apiKeyHelper`, from one administrator source.
It puts the sources in ranks, best first:

1. Sources with at least one policy value as written
1. Sources whose policy values are only substitutes that {{ site.claude_code }} uses for invalid values
1. Sources that set policy keys only to empty objects, such as `"env": {}`

From the best rank that has a source, {{ site.claude_code }} uses the source that is highest in the precedence order.
So the rank comes first.
For example, a file build outranks an MDM policy that holds only substitutes or empty objects.

A `null` still counts as a policy value for the list keys that {{ site.claude_code }} reads as an empty list:

* `allowedMcpServers`
* `availableModels`
* `allowedHttpHookUrls`
* `httpHookAllowedEnvVars`
* `allowedChannelPlugins`
* `allowedProviders`
* `forceLoginOrgUUID`

A `null` `gatewayInternalNetworks` also counts as a policy value.
{{ site.claude_code }} reads it as a network that doesn't match any address.
When the highest managed source on a computer holds it, `/login` refuses every new [cloud gateway](https://code.claude.com/docs/en/claude-apps-gateway) sign-in on that computer.
For details, see [Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed).
`fleet build` refuses a `--policy` that sets `gatewayInternalNetworks` to `null`.

A `null` `crossSessionInbound` also counts as a policy value, because {{ site.claude_code }} reads it as `"refuse"`.
A `null` `remoteControl` also counts as a policy value, because {{ site.claude_code }} reads it as the `off` profile.

Some keys apply from every administrator source, including `env` and the MCP locks.
For the list, see [Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source).

### Choose the delivery method

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Platforms
    key: platforms
  - title: When to use and what to pass
    key: usage
rows:
  - flag: "`--delivery file` (default)"
    platforms: macOS, Linux, Windows
    usage: |
      Use when no MDM policy sets a policy value as written.
      The build writes `managed-settings.d/kong-harnesses.json`.
      Pass the current `managed-settings.json` with `--policy POLICY_FILE`.
      If there isn't a `managed-settings.json` file, pass `--no-policy`, even when `managed-settings.d/` has files.
  - flag: "`--delivery mdm`"
    platforms: macOS, Windows
    usage: |
      Use when an MDM policy sets a policy value as written, or when you deliver the settings through MDM.
      Pass the current MDM policy with `--policy POLICY_FILE`.
      Pass `--no-policy` only when there isn't an MDM policy.
{% endtable %}

### Check the existing policy

Before you build, check each policy source:

* **Remote settings:** Move the policy into MDM or `managed-settings.json`.
  Keep remote settings only for [Anthropic-hosted cloud sessions](https://code.claude.com/docs/en/server-managed-settings#choose-between-server-managed-and-endpoint-managed-settings) or unmanaged devices.
  Otherwise, delete them, but only after you deploy to every computer that they cover.
  On managed computers, remove the credentials that load a conflicting remote policy: an organization claude.ai sign-in, `CLAUDE_CODE_OAUTH_TOKEN`, or a direct API key.
  For details, see [Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability).
* **Values that `fleet build` refuses:** `fleet build` refuses a `--policy` that sets any of these:
  * `forceLoginMethod` or `forceLoginGatewayUrl`, with a value other than `null`
  * A `policyHelper` or `policyHelpers` value that supplies settings on the target platform, from a helper path or script, or from a `defaultSettings` or `default` payload.
    This includes a `policyHelper` path that {{ site.claude_code }} can't run, because {{ site.claude_code }} then refuses to start.
  * An `allowedProviders` text entry other than `customEndpoint`
  * In `ANTHROPIC_CUSTOM_HEADERS`: `Authorization`, `Proxy-Authorization`, `X-Api-Key`, `Host`, a malformed line, or a header that conflicts with attribution
  * An `env` value that {{ site.claude_code }} can't use: an object with its own `toString` key, also inside a list, or a value whose text holds a NUL byte.
    An object with its own `toString` key makes {{ site.claude_code }} drop every value in the `env` of that policy source.
    Other values convert to text, such as numbers, booleans, `null`, lists, and objects.
  * A version range that fails the [version range checks](#version-range-checks)
* **Other keys to remove:** Remove `forceLoginOrgUUID`, because it blocks `apiKeyHelper` at startup.
  Also remove `enforceAnthropicSignIn`.
* **Other keys to check:** Confirm that `disableAllHooks` isn't `true`.
  Confirm that `availableModels` and `deniedModels` permit every model of the build.
* **Custom headers in MDM builds:** The build sets `ANTHROPIC_CUSTOM_HEADERS`, and each `env` key comes from the highest administrator source that defines it.
  So in the first-wins and merge modes, move the non-secret headers from managed settings files into `--policy`.
* **Drop-ins in file builds:** `--policy` reads only `managed-settings.json`, but {{ site.claude_code }} also [merges the files in `managed-settings.d/` in alphabetical order](https://code.claude.com/docs/en/managed-settings#split-a-file-based-policy-across-teams).
  Check every drop-in, in any sort position, for these keys:
  * `policyHelper` and `policyHelpers`
  * `forceLoginMethod`, `forceLoginGatewayUrl`, and `forceLoginOrgUUID`
  * `enforceAnthropicSignIn`
  * `allowedProviders` entries other than `customEndpoint`, because lists combine

  Confirm that no drop-in that sorts after `kong-harnesses.json` overrides `apiKeyHelper`, `env`, or `modelPicker`.
  Move non-secret `ANTHROPIC_CUSTOM_HEADERS` from drop-ins that sort before `kong-harnesses.json` into `managed-settings.json`.
* **Merged sources:** For `managedSourcesBehavior: "merge"` in an MDM build, include the key in `--policy`.
  Confirm that `managed-settings.json` and `managed-settings.d/` don't add conflicting keys or unwanted list entries, such as `permissions.allow` rules or hooks.
  For details, see [Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source).
* **MDM policy and a file build:** An MDM policy with a policy value as written outranks a file build.
  {{ site.claude_code }} then uses the `apiKeyHelper` of the MDM policy, or no helper when the MDM policy doesn't have one.
  A file build outranks an MDM policy that holds only substitutes or empty objects, because the `apiKeyHelper` that `fleet build` writes is a policy value as written.

### MDM policy location

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

## MCP server modes and exceptions

`--mcp-servers` sets which MCP servers {{ site.claude_code }} loads.
If the profile has gateway MCP servers, the flag is required.
Otherwise, it defaults to `allowlist`.

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
      Joins the valid managed `allowedMcpServers` entries with the gateway entries and the flag entries.
      Developers run `kong-harnesses profile activate work --client claude-code`.
    flags: |
      Add `--mcp-url 'URL_PATTERN'` for each remote server, or `--mcp-command 'COMMAND_JSON_ARRAY'` for each stdio server.
      You can't use `--mcp-config`.
  - mode: "`any`"
    behavior: |
      Doesn't add an MCP lock.
      Existing locks stay active.
      Developers run `kong-harnesses profile activate work --client claude-code`.
    flags: You can't use `--mcp-url`, `--mcp-command`, or `--mcp-config`.
{% endtable %}

### Servers that skip some MCP checks

* In-process servers (`type: "sdk"`) skip the `managed-mcp.json`, allowlist, and `deniedMcpServers` checks.
  The app that started the session registers them, for example an Agent SDK app, the VS Code extension, or Claude Desktop for its connectors.
  For details, see [How a server is evaluated](https://code.claude.com/docs/en/managed-mcp#how-a-server-is-evaluated).
* In `exclusive` mode, these servers also [load with `managed-mcp.json`](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json):
  * `managedMcpServers` entries
  * The server that {{ site.claude_code }} creates when a [mod](https://code.claude.com/docs/en/plugins/mods/overview) adds tools
  * Claude in Chrome, when device policy sets `allowClaudeInChromeWithManagedMcp` to `true`
  * The claude.ai connectors that {{ site.claude_code }} fetches, when managed settings set `allowAllClaudeAiMcps` to `true`

  These servers load with `managed-mcp.json`, but not all of them skip the other checks.
  The claude.ai connectors still go through the allowlist and denylist checks.
* In `allowlist` mode, these servers [skip the allowlist check](https://code.claude.com/docs/en/managed-mcp#servers-that-skip-the-allowlist-check):
  * `managedMcpServers` entries
  * Built-in servers, such as Claude in Chrome, the `ide` server, and servers that the {{ site.claude_code }} CLI configures
  * The Slack tools of a Claude Tag session

### Denylist

In every mode, including `exclusive`, a `deniedMcpServers` entry in any scope blocks each server that it matches, including the gateway servers.
Only in-process servers (`type: "sdk"`) skip the denylist.
`managedMcpServers` servers and Claude in Chrome don't skip it.
Before you deploy, confirm that no policy denies the gateway servers.

### Allowlist checks of managed MCP servers

This rule applies to the `exclusive` mode.

{{ site.claude_code }} checks a `managed-mcp.json` server against `allowedMcpServers` when the URL, command, arguments, or headers of the server name a variable.
[Earlier versions check more servers](https://code.claude.com/docs/en/managed-mcp#how-allowlists-and-denylists-apply-to-the-managed-set):

* Below `2.1.305`, they also check a server that names a variable only in `env`.
* Below `2.1.259`, they check every `managed-mcp.json` server when an allowlist is set.

`fleet build` applies the checks of the minimum version that the computers get.
It takes the minimum from `--claude-code-minimum` or from the `requiredMinimumVersion` of `--policy`, as described in [Version range checks](#version-range-checks).
When the build doesn't set a minimum, it applies both earlier checks.

A checked server is blocked only when the allowlist doesn't permit it or a deny entry matches it.

### MCP policy results

This rule applies to the `exclusive` mode.

`fleet build` gives each server that it writes into `managed-mcp.json` one result: loads, blocked, or undecided.

To find the result, `fleet build` checks the deny entries first.
It [expands the variables](https://code.claude.com/docs/en/managed-mcp#how-policy-entries-expand) in `serverUrl` and `serverCommand` entries and in the server, with the values in the `env` of the policy as the build deploys it.
It compares each entry with the server after this expansion.
A `serverName` entry is an exception: it matches the name as written, before the variables expand.

`fleet build` marks a server undecided when one of these cases keeps it from deciding whether the server loads:

* The result depends on a variable that the `env` of the policy doesn't set, in an entry or in the server.
* An `allowedMcpServers` `serverUrl` entry names a variable, and the `env` of the policy sets that variable to a value that can move the URL.
  Such a value holds `/`, `?`, `#`, `@`, `:`, `\`, `*`, `%`, white space, a control or invisible character, or a character that isn't ASCII, or it is `.` or `..`.
  {{ site.claude_code }} `2.1.219` and later [ignore an allowlist entry](https://code.claude.com/docs/en/managed-mcp#how-policy-entries-expand) whose expansion changes the scheme, host, port, or path scope of the URL.
  This case applies at every minimum version.
  Write such an entry as a literal URL.
* The server names a variable in `headersHelper`, an allowlist is set, and the allowlist doesn't permit the server.
  The [allowlist checks](#allowlist-checks-of-managed-mcp-servers) don't already check this server.
  The {{ site.claude_code }} docs don't say whether a variable in `headersHelper` starts the check.
* An entry names a variable, and the computers can run a {{ site.claude_code }} version earlier than `2.1.219`.
  The {{ site.claude_code }} docs describe how entries expand only from `2.1.219`.
  Build with `--claude-code-minimum 2.1.219` or later, or write the entry as a literal value.
  If `--policy` sets the minimum, set `requiredMinimumVersion` and `minimumVersion` to `2.1.219` or later instead.
* The server or an entry names a variable that {{ site.claude_code }} can read as an empty credential, even when the `env` of the policy sets it.
  A remote server that takes its host from such a variable then doesn't have a host to reach.
  Write the value as a literal.
* The URL of the server or of a `serverUrl` entry has a form that `fleet build` can't compare as {{ site.claude_code }} does, such as a percent escape or a host that isn't ASCII.
  Write the URL in plain ASCII, without percent escapes, backslashes, or spaces.

`fleet build` refuses a blocked or undecided server.
It names each server, the cause, and the fix, such as a literal allowlist entry or a value for the variable in the `env` of the policy.

There's one exception.
When a deny entry is sure to match one of your own `--mcp-config` servers, `fleet build` doesn't refuse the server, because the deny is the choice of your policy.
{{ site.claude_code }} blocks that server.
`fleet build` still refuses a deny entry that only may match.

`kong-harnesses doctor` never reports an undecided server as loaded.

### More MCP rules

* **Provided servers at a gateway address (every mode):** `fleet build` refuses a `managedMcpServers` entry that points, or may point, to the address of a gateway MCP server, also under another name.
  In the `allowlist` and `any` modes, {{ site.claude_code }} loads the provided server instead of the gateway server at the same URL.
  The gateway server then doesn't load with the credential of the profile.
  In the `exclusive` mode, {{ site.claude_code }} loads both.
  When both define the same name, the `managed-mcp.json` entry takes precedence.
  This rule doesn't refuse one kind of entry: an `http` entry for a gateway server with its own OAuth sign-in.
  That entry must have the same OAuth settings, must not set headers, and must have only fields that `fleet build` can check.
  The entry must still pass the checks in [Invalid MCP lists](#invalid-mcp-lists), so it can't set `command`, `args`, `env`, or `headersHelper`.
  Remove each entry that `fleet build` refuses.
* **Name collisions (`exclusive`):** Rename each `--mcp-config` server that has the same name as a gateway server.
  If an earlier fleet build wrote that server, pass the record of that build with `--record` instead.
  If the record holds the definition of that server and you changed the server after that build, `fleet build` keeps your server, so the name collision stays.
  Rename or remove that server.
  If the record lists only server names, `fleet build` leaves out each `--mcp-config` server that has a recorded name, also when you changed that server after that build.
  The new `managed-mcp.json` then holds the current gateway servers of the profile and each `--mcp-config` server that `fleet build` didn't leave out.
* **Servers at a gateway address (`exclusive`):** `fleet build` refuses an `--mcp-config` server with another name that points, or may point, to the address of a gateway MCP server.
  It doesn't refuse a server that the denylist of the policy always blocks.
  It also doesn't refuse an `http` server that signs in as the gateway server does, doesn't set headers, and has only fields that `fleet build` can check, such as `type`, `url`, `oauth`, and `headersHelper`.
  For a gateway server with its own OAuth sign-in, such a server has the same OAuth settings and no `headersHelper`.
  For other gateway servers, such a server runs the `kong-harnesses mcp-headers` helper for the profile and has no OAuth settings.
  Remove each refused server.
* **MDM allowlist replaces file allowlists (`allowlist`):** The highest administrator source supplies the locked `allowedMcpServers`.
  So an MDM `allowlist` build replaces the allowlists in managed settings files.
  Move the entries that you need to `--policy`, `--mcp-url`, or `--mcp-command`.
* **`serverName` entries (`allowlist`):** Added `serverUrl` entries stop `serverName` entries from matching remote servers.
  Added `serverCommand` entries stop them from matching stdio servers.
  Replace the matching `serverName` entries with `--mcp-url` or `--mcp-command`.
* **CLI startup flags:** Remove `--mcp-config` and `--strict-mcp-config` from wrappers, aliases, and IDE settings.
  When {{ site.claude_code }} can read and parse `managed-mcp.json`, it [exits at startup](https://code.claude.com/docs/en/managed-mcp#servers-passed-with-mcp-config-or-strict-mcp-config) on a workstation in these cases:
  * `--mcp-config` passes servers.
  * You pass `--strict-mcp-config`.

  In `allowlist` or `any` mode, `--strict-mcp-config` skips the plugin servers.

### Plugin blockers

This rule applies to the `allowlist` and `any` modes.

{{ site.claude_code }} skips the plugin that `profile activate` installs, or one of its servers, in these cases:

* A `managed-mcp.json` file exists.
* A `managedMcpServers` entry points to the URL of a gateway server, because the [provided server takes precedence](https://code.claude.com/docs/en/managed-mcp#how-provided-servers-load) over the plugin server.
* `strictPluginOnlyCustomization` is `true`, or a list with `skills`, `agents`, `hooks`, or `mcp`.
  Any other value that isn't a boolean, a list, or `null`, such as a string, also counts as `true`.
  These values don't lock anything: `false`, `[]`, `null`, and list entries that don't name a surface.
  A `null` removes the key.
* The marketplace allowlist is set without `{"source": "skills-dir"}`.
  The allowlist key is `strictKnownMarketplaces`, or its alias `allowedMarketplaces`.
  If one file sets both, {{ site.claude_code }} uses `strictKnownMarketplaces` and [ignores the alias](https://code.claude.com/docs/en/settings-reference#marketplace-key-aliases).
* `blockedMarketplaces` lists `{"source": "skills-dir"}`.
* The marketplace allowlist has a wholly invalid value, which fails closed.
  A wholly invalid `blockedMarketplaces` is dropped with a warning.
  For details, see [Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed).

When the profile has gateway MCP servers and `--mcp-servers` isn't `exclusive`, `fleet build` refuses a `--policy` that sets a `strictPluginOnlyCustomization` or marketplace blocker in this list.
If `--policy` sets both allowlist keys, `fleet build` checks both.
The error names the first blocker that `fleet build` finds.
For a `strictPluginOnlyCustomization` lock, it also names each entry that doesn't name a surface.
For a marketplace allowlist, it also names each `source` key that {{ site.claude_code }} ignores because its letter case doesn't match.
Write `source` in lowercase in `{"source": "skills-dir"}`, because `fleet build`, `doctor`, and {{ site.claude_code }} match keys with exact case.

To fix a `strictPluginOnlyCustomization` or marketplace blocker, build with `--mcp-servers exclusive`, or change the setting in `--policy` and in every other managed source.

For the `managedMcpServers` item in this list, `fleet build` uses the address rules in [More MCP rules](#more-mcp-rules) instead, in every mode.

### Invalid MCP lists

This rule applies to every mode, also when the profile doesn't have gateway MCP servers.

`fleet build` refuses a `--policy` in these cases:

* The `allowedMcpServers` or `deniedMcpServers` value isn't a list.
  `fleet build` also refuses a `null` value.
* An `allowedMcpServers` or `deniedMcpServers` entry doesn't have exactly one key with a valid value.
  The key must be `serverName`, `serverUrl`, or `serverCommand`.
* `managedMcpServers` is `null`, isn't an object, or has an entry that {{ site.claude_code }} drops.

{{ site.claude_code }} drops an invalid entry and still applies the other entries.
It drops a `deniedMcpServers` value that isn't a list, so that value doesn't block any server.
It drops a `managedMcpServers` value that isn't an object.
`fleet build` can't know what the dropped entry or value was meant to allow, deny, or provide.
If you don't want a list or provided servers, leave the key out of `--policy`.

{{ site.claude_code }} [loads a `managedMcpServers` entry](https://code.claude.com/docs/en/managed-mcp#what-an-entry-can-contain) only when it passes all of these checks:

* The type is `http`, `sse`, or `streamable-http`.
* The URL is an `https://` URL with a host.
* The entry doesn't have a `command`, `args`, `env`, or `headersHelper` key.
* No value holds a `${...}` reference.
* The name has only letters, digits, hyphens, and underscores.
* No key or value holds a control character or an invisible format character.

In the `allowlist` and `any` modes, {{ site.claude_code }} enforces a wholly invalid managed `allowedMcpServers` value, also `null`, as an empty managed allowlist.
For details, see [Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed).
The value doesn't skip the plugin, and `managedMcpServers` and the allowlist-exempt servers still load.

The empty list applies only when the invalid value supplies the managed allowlist.
With the MCP lock (`allowManagedMcpServersOnly: true`), a valid list in an administrator source with higher precedence, such as server-managed settings, takes its place.
For details, see [Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source).

When the empty list applies, it's the only list if the MCP lock is set or no other settings scope sets `allowedMcpServers`.
Then the servers that a developer adds don't load, and the gateway plugin servers don't load either.
In `any` mode without the MCP lock, an `allowedMcpServers` entry in user, project, or local settings can still permit a server.

### Allowlist values and quoting

In `allowlist` mode, pass these values:

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

## Host apps, WSL, and executable path

### Host settings

`--host-settings` decides whether embedding host apps, such as IDE extensions and Agent SDK apps, can add settings.

* `--host-settings ignore` is the default.
  It doesn't write `parentSettingsBehavior`, and keeps any value that the policy sets.
* `--host-settings merge` sets `parentSettingsBehavior: "merge"`.
  It keeps restrictive host settings.
  It also admits these host settings unless a managed key locks them:
  * Permission allow rules, unless `allowManagedPermissionRulesOnly` is `true`
  * Sandbox network domains, unless `sandbox.network.allowManagedDomainsOnly` is `true`
  * Sandbox read paths, unless `sandbox.filesystem.allowManagedReadPathsOnly` is `true`

  For details, see [Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy) and [Restrict parent settings](https://code.claude.com/docs/en/claude-apps-gateway#restrict-parent-settings).

Confirm that host apps don't pass any of these:

* `forceLoginOrgUUID`, which blocks `apiKeyHelper` when managed settings don't set it
* An `availableModels` list that leaves out models of the build
* A plugin blocker

Claude Desktop doesn't call `apiKeyHelper`.
It needs its own [third-party gateway configuration](https://code.claude.com/docs/en/llm-gateway-connect#desktop-app).

### WSL on Windows

WSL isn't part of the default Windows rollout.
{{ site.claude_code }} in WSL reads only `/etc/claude-code`, unless a Windows administrator source enables [`wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings).
The Windows administrator sources are `HKLM\SOFTWARE\Policies\ClaudeCode`, `managed-settings.json`, and `managed-settings.d/`.

`--wsl inherit` sets `wslInheritsWindowsSettings: true`.
It writes helpers that run the Windows `kong-harnesses.exe` through WSL interop.
It requires:

* Windows interop turned on
* A supported Linux {{ site.claude_code }} install in WSL, as described in [Install in WSL](https://code.claude.com/docs/en/setup#install-in-wsl)
* Any private gateway CA trusted in each WSL distribution

WSL limits:

* You can't use `--wsl inherit` with `--mcp-servers exclusive`.
* With `--wsl inherit`, `fleet build` refuses a non-empty `NODE_EXTRA_CA_CERTS`, `CLAUDE_CODE_CLIENT_CERT`, or `CLAUDE_CODE_CLIENT_KEY` in the `env` of `--policy`.
  {{ site.claude_code }} in WSL inherits them and can't open the Windows paths that they name.
  `env` merges into WSL, so also leave them out of all three Windows administrator sources.
* Gateway MCP servers don't load in WSL in any mode.
* Enforcement in WSL needs an unchanged {{ site.claude_code }}.
* Without `--wsl inherit`, also with the default `--wsl ignore`, a Windows `fleet build` refuses a `--policy` that enables `wslInheritsWindowsSettings`.
  Confirm that all three Windows administrator sources leave it out or set it to `null`, `false`, or `"false"`.
  Any other value enables inheritance.

### Executable path restrictions

`--executable` must be an absolute UTF-8 path on every platform.
It can't hold the characters in this table:

{% table %}
columns:
  - title: Platform
    key: platform
  - title: Path to
    key: form
  - title: Characters not allowed
    key: chars
rows:
  - platform: macOS
    form: "`kong-harnesses`"
    chars: |
      Line breaks and NUL bytes.
      For MDM builds, also control characters.
  - platform: Linux
    form: "`kong-harnesses`"
    chars: Line breaks and NUL bytes
  - platform: Windows
    form: "`kong-harnesses.exe`, with a drive letter and backslashes"
    chars: |
      `"`, `%`, `!`, and control characters.
      With `--wsl inherit`, also `'`.
{% endtable %}

## Keep or revert recorded flags

When you rebuild with `--record`, `fleet build` refuses to drop a choice that the earlier build recorded.
Use the table to keep, change, or revert each choice of the earlier build:

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
    keep: |
      Pass `--model` for each family again.
      Your local profile doesn't change.
    revert: Leave out the `--model` of the family and pass `--profile-models`.
  - earlier: "`--mcp-servers any` or `exclusive`"
    keep: |
      Pass the mode again.
      For `exclusive`, also pass `--mcp-config 'MCP_CONFIG_FILE'`.
    revert: |
      From `any`, pass `allowlist` or `exclusive`.

      From `exclusive`, run `kong-harnesses fleet remove --record 'RECORD_FILE' --mcp-config 'MCP_CONFIG_FILE'`.
      For MDM builds, add `--policy 'POLICY_FILE'`.
      If policy keys or your own servers remain, add `--output-dir`.
      Then follow [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/).
      A remaining `managed-mcp.json` keeps [exclusive control](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) and blocks the gateway MCP plugin.
      So move your other servers out of it, remove `managed-mcp.json`, and start the new build without the old `--record`.
  - earlier: "`--claude-code-minimum` or `--claude-code-maximum`"
    keep: Pass each bound again, or update it.
    revert: |
      Pass `--claude-code-any-version` alone to remove both recorded bounds, or with one bound to remove the other recorded bound.
      Bounds in `--policy` still apply.
  - earlier: "`--host-settings merge`"
    keep: Pass `--host-settings merge`.
    revert: |
      Pass `--host-settings ignore`.
      Then confirm that the MDM policy, `managed-settings.json`, and `managed-settings.d/` don't set `merge`.
  - earlier: "`--wsl inherit` (Windows)"
    keep: Pass `--wsl inherit`.
    revert: |
      Pass `--wsl ignore`.
      Then confirm that the [Windows administrator sources](#wsl-on-windows) leave it out or set it to `null`, `false`, or `"false"`.
  - earlier: "`--mcp-url` or `--mcp-command` (`allowlist`)"
    keep: Pass each server flag again.
    revert: Pass `--gateway-mcp-only` to drop the earlier entries that you don't list.
{% endtable %}

## Version bounds

`--claude-code-minimum` writes `requiredMinimumVersion` and `minimumVersion`.
`--claude-code-maximum` writes `requiredMaximumVersion`.

### Version range checks

When you rebuild with `--delivery mdm` and `--record` names an earlier MDM build, `fleet build` first takes the settings of that build out of the policy that it reads from `--policy`.
It removes each value that the build added and restores each value that the build replaced.
It keeps values that you changed after that build.
The version checks use the policy that remains.

`fleet build` refuses a version range in these cases:

* A flag value isn't three numbers separated by dots, without leading zeros, such as `2.1.300`.
  For example, `2.1`, `v2.1.300`, and `2.01.300` aren't valid.
* `--claude-code-minimum` is earlier than `2.1.163`, the first release that reads version bounds.
  This check applies only to the flag.
* `--claude-code-minimum` differs from a valid `requiredMinimumVersion` or `minimumVersion` in `--policy`.
* `--claude-code-maximum` differs from a valid `requiredMaximumVersion` in `--policy`.
* You pass `--claude-code-minimum`, and `--policy` sets `requiredMinimumVersion` and `minimumVersion` to different versions.
* The maximum version is earlier than `2.1.285`, the first release that keeps every session on the gateway.
  The maximum version is `--claude-code-maximum` when you pass it, and `requiredMaximumVersion` in `--policy` otherwise.
* The minimum version is later than the maximum version.
  The minimum version is `--claude-code-minimum` when you pass it.
  Otherwise, `fleet build` checks `requiredMinimumVersion` and `minimumVersion` in `--policy`, each on its own, against the maximum version.

{{ site.claude_code }} ignores a policy bound that isn't a valid version, so `fleet build` ignores it too.

### How version bounds behave

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

## Model overrides

`fleet build` applies `--model` to the managed settings and the machine-wide profile:

* **Family:** `fleet build` detects the `opus`, `sonnet`, `haiku`, or `fable` family from `NEW_MODEL_ID`.
  You can also name the family with `--model FAMILY=NEW_MODEL_ID`, for example `--model sonnet=NEW_MODEL_ID`.
  Pass `--model` once for each family that you want to change.
  `fleet build` refuses two for the same family.
  Each ID has 1 to 128 visible ASCII characters.
* **Settings and roles:** `fleet build` updates the family slot.
  It also updates each role that used the previous model of the family: `active`, `default`, `subagent`, `background_classifier`, and `auto_mode`.
  Other roles don't change.
* **`/cost` rates:** `fleet build` adds `modelPricing` for the new model when the profile or {{ site.ai_gateway }} provides all the required USD rates.
  The required rates are `input`, `output`, `cache_read`, and `cache_write`, or `cache_write_1h` for one-hour prompt caching.
  Other models without rates don't stop this.
* **Local profile:** The profile on your build computer doesn't change.
  So pass `--model` again on each rebuild, unless you pass `--profile-models`.
