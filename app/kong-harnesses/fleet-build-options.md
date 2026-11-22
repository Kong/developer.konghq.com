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

`kong-harnesses fleet build` generates [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) and a machine-wide profile per group sharing platform, delivery, policy, and `managed-mcp.json` (`exclusive`), as [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/) shows.

{:.warning}
> **Keep secrets out of managed files:** Every account can read managed settings and `managed-mcp.json`.
> Remove all secrets from `--policy` and `--mcp-config` (`env`, `ANTHROPIC_CUSTOM_HEADERS`, MCP server definitions), and use [per-user credentials](https://code.claude.com/docs/en/managed-mcp#authenticate-with-per-user-credentials).

## Delivery method and existing policy

{{ site.claude_code }} ranks managed sources in [precedence order](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources):

1. Remote settings (claude.ai admin console or Claude apps gateway).
1. MDM policy (see [MDM policy location](#mdm-policy-location)).
1. Managed settings files (`managed-settings.json` and `managed-settings.d/`).

By default, {{ site.claude_code }} reads most keys (including `apiKeyHelper`) from the highest administrator source setting a policy key to a value other than `null` or empty objects (`false`, `0`, and `""` count as set; otherwise the highest setting a non-`null` policy key).
Sources setting only `managedSourcesBehavior` or `wslInheritsWindowsSettings` don't count.
[Select keys apply across administrator sources](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source), including `env` and MCP locks.

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Platforms
    key: platforms
  - title: Use and policy input
    key: usage
rows:
  - flag: "`--delivery file` (default)"
    platforms: macOS, Linux, Windows
    usage: |
      Writes `managed-settings.d/kong-harnesses.json` when an MDM policy doesn't set a policy key.
      Pass `managed-settings.json` with `--policy POLICY_FILE`, or `--no-policy` when absent (even with `managed-settings.d/` files).
  - flag: "`--delivery mdm`"
    platforms: macOS, Windows
    usage: |
      Use when an MDM policy sets a policy key, or for MDM delivery.
      Pass the current MDM policy with `--policy POLICY_FILE`, or `--no-policy` only without an MDM policy.
{% endtable %}

Policy rules:

* **Remote settings:** Migrate policy into MDM or `managed-settings.json`, keeping remote settings only for [Anthropic-hosted cloud sessions](https://code.claude.com/docs/en/server-managed-settings#choose-between-server-managed-and-endpoint-managed-settings) or unmanaged devices.
  Otherwise, delete them only after deploying to every covered computer.
  On managed computers, remove credentials loading a conflicting remote policy (organization claude.ai sign-in, `CLAUDE_CODE_OAUTH_TOKEN`, or direct API key, [Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)).
* **Rejected `--policy` values:**
  * `forceLoginMethod`, `forceLoginGatewayUrl`, `policyHelper`, `policyHelpers`
  * Non-`customEndpoint` text `allowedProviders` entries
  * `Authorization`, `Proxy-Authorization`, `X-Api-Key`, `Host`, malformed lines, or attribution-conflicting headers in `ANTHROPIC_CUSTOM_HEADERS`
  * Non-string `env` values {{ site.claude_code }} drops, and invalid version bounds ([Version range checks](#version-range-checks))
* **Additional checks:** Remove `forceLoginOrgUUID` (blocks `apiKeyHelper` at startup) and `enforceAnthropicSignIn`.
  Confirm `disableAllHooks` isn't `true` and `availableModels` and `deniedModels` permit every build model.
* **MDM custom headers:** Because the build pins `ANTHROPIC_CUSTOM_HEADERS` and each `env` key comes from the highest administrator source defining it, move non-secret file headers into `--policy` in first-wins and merge modes.
* **Drop-ins (file builds):** `--policy` reads only `managed-settings.json`, while {{ site.claude_code }} [merges `managed-settings.d/` alphabetically](https://code.claude.com/docs/en/managed-settings#split-a-file-based-policy-across-teams).
  Check all drop-ins regardless of sort order for `policyHelper`, `policyHelpers`, `forceLoginMethod`, `forceLoginGatewayUrl`, `forceLoginOrgUUID`, `enforceAnthropicSignIn`, and non-`customEndpoint` `allowedProviders` entries (lists combine).
  Confirm files sorting after `kong-harnesses.json` don't override `apiKeyHelper`, `env`, or `modelPicker`, and move earlier non-secret `ANTHROPIC_CUSTOM_HEADERS` into `managed-settings.json`.
* **Merged sources:** For `managedSourcesBehavior: "merge"` on MDM builds, include it in `--policy` and confirm `managed-settings.json` and `managed-settings.d/` don't add conflicting keys or unwanted list entries such as `permissions.allow` rules or hooks ([Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source)).
  An MDM policy setting a policy key to a value other than `null` or empty objects still supplies `apiKeyHelper` over a file build.

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

`--mcp-servers` sets which MCP servers {{ site.claude_code }} loads, defaulting to `allowlist` only without gateway MCP servers (required otherwise).

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Behavior and gateway delivery
    key: behavior
  - title: Flags
    key: flags
rows:
  - mode: "`exclusive`"
    behavior: Writes `managed-mcp.json` under `root/` (needs a gateway server), blocks developer, project, and plugin servers, and deploys gateway servers automatically.
    flags: |
      Pass current `managed-mcp.json` with `--mcp-config 'MCP_CONFIG_FILE'` when present (omit only when absent).
      Incompatible with `--mcp-url`, `--mcp-command`, and `--wsl inherit`.
  - mode: "`allowlist`"
    behavior: |
      Sets `allowManagedMcpServersOnly: true` and joins eligible managed `allowedMcpServers` with gateway and flag entries.
      Developers run `kong-harnesses profile activate work --client claude-code`.
    flags: |
      Repeat `--mcp-url 'URL_PATTERN'` (remote) or `--mcp-command 'COMMAND_JSON_ARRAY'` (stdio).
      Incompatible with `--mcp-config`.
  - mode: "`any`"
    behavior: |
      Doesn't add an MCP lock (existing locks stay active).
      Developers run `kong-harnesses profile activate work --client claude-code`.
    flags: Incompatible with `--mcp-url`, `--mcp-command`, and `--mcp-config`.
{% endtable %}

MCP rules:

* **Exceptions and denylist:** In-process Agent SDK servers (`type: "sdk"`) skip `managed-mcp.json`, allowlist, and `deniedMcpServers` checks ([How a server is evaluated](https://code.claude.com/docs/en/managed-mcp#how-a-server-is-evaluated)).
  In `exclusive` mode, `managedMcpServers` and [exclusive-control exceptions](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) (Claude Desktop connectors, and Claude in Chrome with `allowClaudeInChromeWithManagedMcp`) still load.
  Remove duplicate `managedMcpServers` entries at gateway URLs under another name.
  In `allowlist` mode, `managedMcpServers` and [allowlist-exempt servers](https://code.claude.com/docs/en/managed-mcp#servers-that-skip-the-allowlist-check) (built-in IDE, Chrome, Agent SDK) also load.
  In every mode (including `exclusive`), `deniedMcpServers` across all scopes blocks every other matching server, including gateway servers.
  Confirm policies don't deny gateway servers before deploying.
* **Allowlist checks of `managed-mcp.json` servers (`exclusive`):** {{ site.claude_code }} checks a `managed-mcp.json` server against `allowedMcpServers` when its URL, command, arguments, or headers name a variable.
  [Earlier versions check more servers](https://code.claude.com/docs/en/managed-mcp#how-allowlists-and-denylists-apply-to-the-managed-set): below `2.1.305`, also a server that names a variable only in `env`, and below `2.1.259`, every `managed-mcp.json` server whenever an allowlist is set.
  `fleet build` applies the checks of the minimum version that the computers get, from `--claude-code-minimum` or the `requiredMinimumVersion` of `--policy` ([Version range checks](#version-range-checks)), and both earlier checks when the build sets no minimum.
  A checked server is blocked only when the allowlist doesn't permit it or a deny entry matches it.
* **MCP policy results (`exclusive`):** `fleet build` gives each server that it writes into `managed-mcp.json` one result: loads, blocked, or undecided.
  It checks deny entries first, and [expands the variables](https://code.claude.com/docs/en/managed-mcp#how-policy-entries-expand) in `serverUrl` and `serverCommand` entries and in the server with the values in the policy's `env`.
  A `serverName` entry matches the name as written, before variables expand.
  An entry is a match when these known values make it match.
  A server is undecided when its result depends on a variable that the policy's `env` doesn't set, in an entry or in the server.
  An `allowedMcpServers` `serverUrl` entry is also undecided, at every minimum version, when the policy's `env` sets a variable that the entry names to a value that holds `/`, `?`, `#`, `@`, `:`, or `\`, because {{ site.claude_code }} `2.1.219` and later [ignore an allowlist entry](https://code.claude.com/docs/en/managed-mcp#how-policy-entries-expand) whose expansion changes the URL's scheme, host, or path.
  Write such an entry as a literal URL.
  A server that names a variable in `headersHelper` and that the **Allowlist checks of `managed-mcp.json` servers** rule doesn't check is also undecided when an allowlist is set and doesn't permit it, because the {{ site.claude_code }} docs don't say whether that variable starts the check.
  `fleet build` refuses a blocked or undecided server, and names each server, its cause, and the fix (for example, a literal allowlist entry, or the variable's value in the policy's `env`).
  The exception is a deny entry that provably matches one of your own `--mcp-config` servers: that is your policy's choice, so `fleet build` doesn't refuse that server, and {{ site.claude_code }} blocks it.
  A deny entry that only may match is still refused.
  `kong-harnesses doctor` never reports an undecided server as loaded.
* **Name collisions (`exclusive`):** Rename any `--mcp-config` server matching a gateway server name, or pass `--record` for an earlier build.
* **MDM allowlist displacement (`allowlist`):** Because the highest administrator source supplies locked `allowedMcpServers`, MDM `allowlist` builds replace file allowlists.
  Move needed entries to `--policy`, `--mcp-url`, or `--mcp-command`.
* **`serverName` entries (`allowlist`):** Added `serverUrl` entries stop `serverName` from matching remote servers, and `serverCommand` entries stop it from matching stdio servers.
  Replace matching `serverName` entries with `--mcp-url` or `--mcp-command`.
* **Plugin blockers (`allowlist` or `any`):** {{ site.claude_code }} skips the `profile activate` plugin, or one of its servers, when any of these apply:
  * A `managed-mcp.json` file exists.
  * A `managedMcpServers` entry points at the URL of a gateway server, because the [provided server takes precedence](https://code.claude.com/docs/en/managed-mcp#how-provided-servers-load) over the plugin server.
  * `strictPluginOnlyCustomization` is `true`, a list with `skills`, `agents`, `hooks`, or `mcp`, or any value that isn't a boolean, a list or `null` (strings included), which counts as `true`.
    `false`, `[]`, `null` (which removes the key), and list entries that name no surface lock nothing.
  * `strictKnownMarketplaces` (or alias `allowedMarketplaces`) is set without `{"source": "skills-dir"}`.
  * `blockedMarketplaces` lists `{"source": "skills-dir"}`.
  * `strictKnownMarketplaces` (`allowedMarketplaces`) has a wholly invalid value, which fails closed (wholly invalid `blockedMarketplaces` is dropped with a warning, [Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)).

  When the profile has gateway MCP servers and `--mcp-servers` isn't `exclusive`, `fleet build` refuses a `--policy` setting a plugin blocker and names each key {{ site.claude_code }} ignores for its case and each `strictPluginOnlyCustomization` entry that names no surface.
  Write lowercase `source` in `{"source": "skills-dir"}` because `fleet build`, `doctor`, and {{ site.claude_code }} match keys with exact case.
  Build with `--mcp-servers exclusive` or change the setting in `--policy` and every other managed source.
* **Invalid MCP lists:** In every mode, also when the profile has no gateway MCP servers, `fleet build` refuses a `--policy` whose `allowedMcpServers` or `deniedMcpServers` value isn't a list (`null` included), or holds an entry that doesn't have exactly one key, `serverName`, `serverUrl`, or `serverCommand`, with a valid value.
  {{ site.claude_code }} drops such an entry and enforces the rest, but `fleet build` can't know what the entry was meant to allow or deny.
  A `deniedMcpServers` value that isn't a list blocks no server.
  To set no list, leave the key out of `--policy`.
* **Invalid allowlist (`allowlist` or `any`):** {{ site.claude_code }} enforces a wholly invalid managed `allowedMcpServers` value as an empty managed allowlist ([Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)).
  The value doesn't skip the plugin, and `managedMcpServers` and allowlist-exempt servers still load.
  The empty list applies only when the invalid value supplies the managed allowlist.
  With the MCP lock (`allowManagedMcpServersOnly: true`), a valid list in an administrator source with higher precedence, such as server-managed settings, takes its place ([Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source)).
  When the empty list applies and the MCP lock is set, or no other settings scope sets `allowedMcpServers`, it's the only list, so no server that a developer adds loads, gateway plugin servers included.
  In `any` mode without the MCP lock, an `allowedMcpServers` entry in user, project, or local settings can still permit a server.
  `fleet build` refuses a `--policy` with such a value, as the **Invalid MCP lists** rule says.
* **CLI startup flags:** Remove `--mcp-config` and `--strict-mcp-config` from wrappers, aliases, and IDE settings, because either [exits at startup](https://code.claude.com/docs/en/managed-mcp#servers-passed-with-mcp-config-or-strict-mcp-config) with `managed-mcp.json` and `--strict-mcp-config` skips plugin servers in `allowlist` or `any`.

### Allowlist values and quoting

In `allowlist` mode, pass these values:

* `URL_PATTERN`: `http`, `https`, or `*` remote URL with optional `*` wildcards in visible ASCII (for example, `'https://MCP_HOST/*'`).
  Use `xn--` ASCII for international hosts and percent-encode non-ASCII paths.
* `COMMAND_JSON_ARRAY`: Non-empty JSON string array matching the exact stdio command and arguments (for example, `'["npx","-y","PACKAGE"]'`).

Omit `${...}` (`fleet build` rejects it, and {{ site.claude_code }} [expands `${...}`](https://code.claude.com/docs/en/managed-mcp#how-policy-entries-expand) from developer shell and managed `env`).
Quote each value to preserve `*` and JSON quotes:

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
      [Windows PowerShell 5.1 strips inner double quotes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing#passing-arguments-that-contain-quote-characters), so escape each with `\` (for example, `--mcp-command '[\"npx\",\"-y\",\"PACKAGE\"]'`).
      This works only when no backslash comes right before a double quote.
      Otherwise, use PowerShell 7.3 or later.
{% endtable %}

## Host apps, WSL, and executable path

### Host settings

By default, `--host-settings ignore` omits `parentSettingsBehavior` and keeps any policy value.
`--host-settings merge` sets `parentSettingsBehavior: "merge"`, keeping restrictive host settings (IDE extensions, Agent SDK apps) and admitting these unless locked ([Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy), [Restrict parent settings](https://code.claude.com/docs/en/claude-apps-gateway#restrict-parent-settings)):

* Permission allow rules (unless `allowManagedPermissionRulesOnly: true`)
* Sandbox network domains (unless `sandbox.network.allowManagedDomainsOnly: true`)
* Sandbox read paths (unless `sandbox.filesystem.allowManagedReadPathsOnly: true`)

Confirm host apps don't pass `forceLoginOrgUUID` (blocks `apiKeyHelper` when unset in managed settings), `availableModels` excluding build models, or plugin blockers.
Claude Desktop doesn't call `apiKeyHelper` and needs its own [third-party gateway configuration](https://code.claude.com/docs/en/llm-gateway-connect#desktop-app).

### WSL on Windows

WSL is outside the default Windows rollout because {{ site.claude_code }} in WSL reads only `/etc/claude-code` unless a Windows administrator source (`HKLM\SOFTWARE\Policies\ClaudeCode`, `managed-settings.json`, or `managed-settings.d/`) enables [`wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings).
`--wsl inherit` sets `wslInheritsWindowsSettings: true`, writes helpers running Windows `kong-harnesses.exe` through WSL interop, and requires Windows interop enabled, a supported Linux {{ site.claude_code }} install ([Install in WSL](https://code.claude.com/docs/en/setup#install-in-wsl)), and any private gateway CA trusted in each WSL distribution.

WSL limits:

* Incompatible with `--mcp-servers exclusive`.
* With `--wsl inherit`, `fleet build` refuses a non-empty value of `NODE_EXTRA_CA_CERTS`, `CLAUDE_CODE_CLIENT_CERT`, or `CLAUDE_CODE_CLIENT_KEY` in the `env` of `--policy`, because {{ site.claude_code }} in WSL inherits them and can't open the Windows paths they name.
  Omit them from all three Windows administrator sources because `env` merges into WSL.
* Gateway MCP servers don't load in WSL in any mode, and enforcement requires an unchanged {{ site.claude_code }}.
* Without `--wsl inherit` (including default `ignore`), Windows `fleet build` refuses any `--policy` enabling `wslInheritsWindowsSettings`.
  Confirm all three Windows administrator sources omit it or set `null`, `false`, or `"false"` (any other value enables inheritance).

### Executable path restrictions

`--executable` must be an absolute path in UTF-8 on every platform, without the characters in this table:

{% table %}
columns:
  - title: Platform
    key: platform
  - title: Path to
    key: form
  - title: Disallowed characters
    key: chars
rows:
  - platform: macOS
    form: "`kong-harnesses`"
    chars: Line breaks and NUL bytes, and control characters for MDM builds
  - platform: Linux
    form: "`kong-harnesses`"
    chars: Line breaks and NUL bytes
  - platform: Windows
    form: "`kong-harnesses.exe`, with a drive letter and backslashes"
    chars: "`\"`, `%`, `!`, and control characters, and `'` with `--wsl inherit`"
{% endtable %}

## Keep or revert recorded flags

When rebuilding with `--record`, `fleet build` refuses omitted recorded choices unless you keep or revert them:

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
    keep: Pass `--model` per family again (local profile stays unchanged).
    revert: Omit the family's `--model` and pass `--profile-models`.
  - earlier: "`--mcp-servers any` or `exclusive`"
    keep: Pass the mode again (with `--mcp-config 'MCP_CONFIG_FILE'` for `exclusive`).
    revert: |
      From `any`, pass `allowlist` or `exclusive`.
      From `exclusive`, run `kong-harnesses fleet remove --record 'RECORD_FILE' --mcp-config 'MCP_CONFIG_FILE'` (add `--policy 'POLICY_FILE'` for MDM and `--output-dir` if policy keys or your own servers remain) and follow [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/).
      Because any remaining `managed-mcp.json` keeps [exclusive control](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) and blocks the gateway MCP plugin, migrate your other servers out of it, remove `managed-mcp.json`, and start the new build without the old `--record`.
  - earlier: "`--claude-code-minimum` or `--claude-code-maximum`"
    keep: Pass each bound again or update it.
    revert: Pass `--claude-code-any-version` alone (clears both) or beside one bound (clears the other).
  - earlier: "`--host-settings merge`"
    keep: Pass `--host-settings merge`.
    revert: Pass `--host-settings ignore`, then confirm MDM policy, `managed-settings.json`, and `managed-settings.d/` don't set `merge`.
  - earlier: "`--wsl inherit` (Windows)"
    keep: Pass `--wsl inherit`.
    revert: Pass `--wsl ignore`, then confirm [WSL on Windows](#wsl-on-windows) sources omit it or set `null`, `false`, or `"false"`.
  - earlier: "`--mcp-url` or `--mcp-command` (`allowlist`)"
    keep: Pass each server flag again.
    revert: Pass `--gateway-mcp-only` to drop unlisted earlier entries.
{% endtable %}

## Version bounds

`--claude-code-minimum` writes `requiredMinimumVersion` and `minimumVersion`, and `--claude-code-maximum` writes `requiredMaximumVersion`.

### Version range checks

`fleet build` refuses a range when:

* `--claude-code-minimum` is earlier than `2.1.163`, the first release reading version bounds (flags only).
* `--claude-code-minimum` or `--claude-code-maximum` differs from the `requiredMinimumVersion` or `requiredMaximumVersion` that `--policy` sets.
* The maximum version (`--claude-code-maximum` or combined `requiredMaximumVersion`) is earlier than `2.1.285`, the first release keeping every session on the gateway.
* The minimum version (`--claude-code-minimum`, or combined `requiredMinimumVersion` or `minimumVersion`) is later than the maximum version.

### How version bounds behave

Version bounds apply at startup and updates:

* **Startup:** {{ site.claude_code }} refuses to start outside the range and prompts for an approved version (running sessions continue until restart).
* **Native and npm:** Background updates and `claude update` stay in range.
* **Homebrew:** Pin the version in your install tool because updates use `brew upgrade`.
* **Claude Desktop:** Deploy a release with bundled {{ site.claude_code }} in range, and keep it from updating out of range:

{% table %}
columns:
  - title: Platform
    key: platform
  - title: Keep Claude Desktop in range
    key: how
rows:
  - platform: macOS
    how: "[Turn off automatic updates](https://code.claude.com/docs/en/desktop#device-management-policies) through MDM."
  - platform: Linux
    how: Pin the version in your package manager.
  - platform: Windows
    how: "[Turn off automatic updates](https://code.claude.com/docs/en/desktop#device-management-policies) through MDM. Microsoft Store installs still update."
{% endtable %}

## Model overrides

`fleet build` applies `--model` to managed settings and the machine-wide profile:

* **Family detection:** Detects `opus`, `sonnet`, `haiku`, or `fable` from `NEW_MODEL_ID`, or accepts `--model FAMILY=NEW_MODEL_ID` (for example, `--model sonnet=NEW_MODEL_ID`).
  Repeat `--model` per family (duplicates are refused), using 1 to 128 visible ASCII characters per ID.
* **Settings and roles:** Updates the family slot and only roles matching its previous model (`active`, `default`, `subagent`, `background_classifier`, and `auto_mode`), leaving others unchanged.
* **`/cost` rates:** Includes `modelPricing` for the new model whenever the profile or {{ site.ai_gateway }} provides all required USD rates (`input`, `output`, `cache_read`, and `cache_write`, or `cache_write_1h` for one-hour prompt caching), even if other models lack rates.
* **Local profile:** Your build computer's local profile stays unchanged, so repeat `--model` on rebuilds unless passing `--profile-models`.
