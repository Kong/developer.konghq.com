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

`kong-harnesses fleet build` generates [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) and a machine-wide profile per computer group sharing platform, delivery, policy, and `managed-mcp.json` (`exclusive`).
See [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/) for setup, or [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/) for `fleet remove`.

{:.warning}
> **Keep secrets out of managed files:** Every account can read managed settings and `managed-mcp.json`.
> Remove all secrets from `--policy` and `--mcp-config` (`env`, `ANTHROPIC_CUSTOM_HEADERS`, MCP server definitions), and use [per-user credentials](https://code.claude.com/docs/en/managed-mcp#authenticate-with-per-user-credentials).

## Delivery method and existing policy

{{ site.claude_code }} ranks managed sources in [precedence order](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources):

1. Remote settings (claude.ai admin console or Claude apps gateway).
1. MDM policy (`com.anthropic.claudecode` on macOS, `HKLM\SOFTWARE\Policies\ClaudeCode` `Settings` on Windows).
1. Managed settings files (`managed-settings.json` and `managed-settings.d/`).

By default, {{ site.claude_code }} reads most keys (including `apiKeyHelper`) from the highest administrator source setting a policy key to a non-`null`, non-empty value (or else the highest setting a non-`null` policy key).
Sources setting only `managedSourcesBehavior` or `wslInheritsWindowsSettings` don't count.
[Select keys apply from every administrator source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source), including `env` and MCP locks.

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
      Pass XML `com.anthropic.claudecode.plist` or Windows `Settings` JSON (not `.reg`) with `--policy POLICY_FILE`, or `--no-policy` only without an MDM policy.
{% endtable %}

Review these policy rules:

* **Remote settings:** Migrate policy into MDM or `managed-settings.json`.
  Keep remote settings for [Anthropic-hosted cloud sessions](https://code.claude.com/docs/en/server-managed-settings#choose-between-server-managed-and-endpoint-managed-settings) or unmanaged devices.
  Otherwise, remove them from their source only after deploying to every covered computer.
  On managed computers, remove credentials loading a conflicting remote policy (organization claude.ai sign-in, `CLAUDE_CODE_OAUTH_TOKEN`, or direct API key, see [Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)).
* **Rejected `--policy` values:** `fleet build` rejects:
  * `forceLoginMethod`, `forceLoginGatewayUrl`, `policyHelper`, or `policyHelpers`
  * Text `allowedProviders` entries other than `customEndpoint`
  * `Authorization`, `Proxy-Authorization`, `X-Api-Key`, `Host`, malformed lines, or attribution-conflicting headers in `ANTHROPIC_CUSTOM_HEADERS`
  * Non-string `env` values that {{ site.claude_code }} drops, and invalid version bounds ([Version range checks](#version-range-checks))
* **Additional policy checks:** Remove `forceLoginOrgUUID` (blocks `apiKeyHelper` at startup) and `enforceAnthropicSignIn`.
  Confirm `disableAllHooks` isn't `true` and `availableModels` and `deniedModels` permit every build model.
* **MDM custom headers:** Because the build pins `ANTHROPIC_CUSTOM_HEADERS` and each `env` key comes from the highest administrator source defining it, move non-secret custom headers from files into `--policy` in first-wins and merge modes.
* **Drop-ins on file builds:** `--policy` inspects only `managed-settings.json`, while {{ site.claude_code }} [merges `managed-settings.d/` alphabetically](https://code.claude.com/docs/en/managed-settings#split-a-file-based-policy-across-teams).
  Check every drop-in regardless of sort order for `policyHelper`, `policyHelpers`, `forceLoginMethod`, `forceLoginGatewayUrl`, `forceLoginOrgUUID`, `enforceAnthropicSignIn`, and non-`customEndpoint` `allowedProviders` entries (`allowedProviders` lists combine).
  Confirm files sorting after `kong-harnesses.json` don't override `apiKeyHelper`, `env`, or `modelPicker`, and move non-secret `ANTHROPIC_CUSTOM_HEADERS` from earlier drop-ins into `managed-settings.json`.
* **Merged sources:** When `managedSourcesBehavior` is `merge` on an MDM build, include it in `--policy` and confirm `managed-settings.json` and `managed-settings.d/` don't add conflicting keys or unwanted list entries such as `permissions.allow` rules or hooks ([Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source)).
  An MDM policy setting a policy key still supplies `apiKeyHelper` over a file build.

## MCP server modes and exceptions

`--mcp-servers` controls which MCP servers {{ site.claude_code }} loads.
It defaults to `allowlist` only without gateway MCP servers, and is required when the profile defines them.

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
      Pass the group's current `managed-mcp.json` with `--mcp-config 'MCP_CONFIG_FILE'` when one exists (omit only when absent).
      Incompatible with `--mcp-url`, `--mcp-command`, and `--wsl inherit`.
  - mode: "`allowlist`"
    behavior: |
      Sets `allowManagedMcpServersOnly: true` and joins eligible managed `allowedMcpServers` with gateway and flag entries.
      Developers run `kong-harnesses profile activate work --client claude-code`.
    flags: Repeat `--mcp-url 'URL_PATTERN'` (remote) or `--mcp-command 'COMMAND_JSON_ARRAY'` (stdio).
  - mode: "`any`"
    behavior: |
      Doesn't add an MCP lock (existing locks stay active).
      Developers run `kong-harnesses profile activate work --client claude-code`.
    flags: Incompatible with `--mcp-url`, `--mcp-command`, and `--mcp-config`.
{% endtable %}

Review these MCP rules:

* **Exceptions and denylist:** In-process Agent SDK servers (`type: "sdk"`) skip `managed-mcp.json`, allowlist, and `deniedMcpServers` checks ([How a server is evaluated](https://code.claude.com/docs/en/managed-mcp#how-a-server-is-evaluated)).
  In `exclusive` mode, `managedMcpServers` and [exclusive-control exceptions](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) (Claude Desktop connectors, and Claude in Chrome with `allowClaudeInChromeWithManagedMcp`) still load.
  Remove duplicate `managedMcpServers` entries at gateway URLs under another name.
  In `allowlist` mode, `managedMcpServers` and [allowlist-exempt servers](https://code.claude.com/docs/en/managed-mcp#servers-that-skip-the-allowlist-check) (built-in IDE, Chrome, Agent SDK) also load.
  In every mode (including `exclusive`), `deniedMcpServers` across all scopes blocks every other matching server, including gateway servers.
  Verify your policies don't deny a gateway MCP server before deploying.
* **Name collisions (`exclusive`):** Rename any `--mcp-config` server matching a gateway server name, or pass `--record` for an earlier build.
* **MDM allowlist displacement (`allowlist`):** Because the highest administrator source supplies `allowedMcpServers` when locked, an MDM `allowlist` build replaces file allowlists.
  Move needed entries into `--policy`, `--mcp-url`, or `--mcp-command`.
* **`serverName` entries (`allowlist`):** Added `serverUrl` entries stop `serverName` from matching remote servers, and added `serverCommand` entries stop `serverName` from matching stdio servers.
  Replace matching `serverName` entries with `--mcp-url` or `--mcp-command`.
* **Allowlist flag values and quoting (`allowlist`):**
  * `URL_PATTERN`: Remote URL with `http`, `https`, or `*` scheme, optional `*` wildcards, and visible ASCII only (for example, `'https://MCP_HOST/*'`).
    Use `xn--` ASCII for international hosts and percent-encode non-ASCII paths.
  * `COMMAND_JSON_ARRAY`: Non-empty JSON array of strings matching the exact stdio command and arguments (for example, `'["npx","-y","PACKAGE"]'`).
  * Quote values so your shell preserves `*` and JSON quotes, and omit `${...}` (`fleet build` rejects it, and {{ site.claude_code }} [expands `${...}`](https://code.claude.com/docs/en/managed-mcp#how-policy-entries-expand) from each developer's shell and managed `env`).
  * On Windows, use single-quoted JSON in PowerShell 7.3 or later.
    In Windows PowerShell 5.1, which [strips inner double quotes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing#passing-arguments-that-contain-quote-characters), escape each inner double quote with `\` (for example, `--mcp-command '[\"npx\",\"-y\",\"PACKAGE\"]'`) only when the value doesn't contain a backslash immediately before a double quote.
    Otherwise, use PowerShell 7.3 or later.
* **Plugin blockers (`allowlist` or `any`):** {{ site.claude_code }} skips the `profile activate` plugin when any of these apply:
  * A `managed-mcp.json` file exists.
  * `strictPluginOnlyCustomization` is `true` or a list with `skills`, `agents`, `hooks`, or `mcp` (`false` and `[]` don't block).
  * `strictKnownMarketplaces` (or alias `allowedMarketplaces`) is set without `{"source": "skills-dir"}`.
  * `blockedMarketplaces` lists `{"source": "skills-dir"}`.
  * `strictPluginOnlyCustomization` (neither boolean nor array), `strictKnownMarketplaces` (`allowedMarketplaces`), or `allowedMcpServers` has a wholly invalid value, which fails closed (wholly invalid `blockedMarketplaces` is dropped with a warning, see [Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)).

  Write lowercase `source` with `skills-dir` (`{"source": "skills-dir"}`), because `fleet build`, `doctor`, and {{ site.claude_code }} match keys with exact case.
  Avoid a `managedMcpServers` entry at a gateway URL because [provided servers take precedence](https://code.claude.com/docs/en/managed-mcp#how-provided-servers-load).
* **CLI startup flags:** Remove `--mcp-config` and `--strict-mcp-config` from wrappers, aliases, and IDE settings, because either [exits at startup](https://code.claude.com/docs/en/managed-mcp#servers-passed-with-mcp-config-or-strict-mcp-config) with `managed-mcp.json` and `--strict-mcp-config` skips plugin servers in `allowlist` or `any` mode.

## Host apps, WSL, and executable path

Optional flags control host settings (`--host-settings`), WSL inheritance (`--wsl`), and the binary path (`--executable`).

### Host settings

By default, `--host-settings ignore` omits `parentSettingsBehavior` and keeps any existing policy value.
`--host-settings merge` sets `parentSettingsBehavior: "merge"`, keeping restrictive host settings (IDE extensions, Agent SDK apps) and admitting these host rules unless locked ([Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy), [Restrict parent settings](https://code.claude.com/docs/en/claude-apps-gateway#restrict-parent-settings)):

* Permission allow rules (unless `allowManagedPermissionRulesOnly: true`)
* Sandbox network domains (unless `sandbox.network.allowManagedDomainsOnly: true`)
* Sandbox read paths (unless `sandbox.filesystem.allowManagedReadPathsOnly: true`)

Confirm host apps don't pass `forceLoginOrgUUID` (blocks `apiKeyHelper` when unset in managed settings), an `availableModels` list excluding build models, or plugin-blocking settings.
Claude Desktop doesn't call `apiKeyHelper` and needs its own [third-party gateway configuration](https://code.claude.com/docs/en/llm-gateway-connect#desktop-app).

### WSL on Windows

WSL is outside the default Windows rollout because {{ site.claude_code }} in WSL reads only `/etc/claude-code` unless a Windows administrator source (`HKLM\SOFTWARE\Policies\ClaudeCode`, `managed-settings.json`, or `managed-settings.d/`) enables [`wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings).
`--wsl inherit` sets `wslInheritsWindowsSettings: true`, writes helpers running Windows `kong-harnesses.exe` through WSL interop, and requires Windows interop enabled, a supported Linux {{ site.claude_code }} install ([Install in WSL](https://code.claude.com/docs/en/setup#install-in-wsl)), and any private gateway CA trusted in each WSL distribution.

Review these WSL limits:

* Incompatible with `--mcp-servers exclusive`.
* `fleet build` rejects `NODE_EXTRA_CA_CERTS`, `CLAUDE_CODE_CLIENT_CERT`, and `CLAUDE_CODE_CLIENT_KEY` in `--policy` because WSL can't open Windows paths.
  Confirm all three Windows administrator sources omit them too because `env` merges into WSL.
* Gateway MCP servers don't load in WSL in any mode, and enforcement applies only while developers run an unchanged {{ site.claude_code }}.
* Without `--wsl inherit` (including default `ignore`), `fleet build` on Windows refuses any `--policy` enabling `wslInheritsWindowsSettings`.
  Confirm all three Windows administrator sources omit it or set `null`, `false`, or `"false"`, because any other value enables inheritance.

### Executable path restrictions

`--executable` must be the absolute path of `kong-harnesses` (or `kong-harnesses.exe` with drive letter and backslashes on Windows):

* **Windows:** Must not contain `"`, `%`, `!`, or control characters, nor `'` with `--wsl inherit`.
* **macOS and Linux:** Must not contain line breaks or NUL bytes, nor control characters for macOS MDM builds.

## Keep or revert recorded flags

When rebuilding with `--record`, `fleet build` refuses omitted recorded choices without a keep or revert flag:

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
      From `exclusive`, run `kong-harnesses fleet remove --record 'RECORD_FILE' --mcp-config 'MCP_CONFIG_FILE'` (add `--policy 'POLICY_FILE'` for MDM and `--output-dir` if policy keys or your own servers remain).
      Apply its output with [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/) before rebuilding.
  - earlier: "`--claude-code-minimum` or `--claude-code-maximum`"
    keep: Pass each bound again or a new version.
    revert: Pass `--claude-code-any-version` alone to clear both, or beside one bound to clear the other.
  - earlier: "`--host-settings merge`"
    keep: Pass `--host-settings merge`.
    revert: Pass `--host-settings ignore`, then verify MDM policy, `managed-settings.json`, and `managed-settings.d/` don't set `merge`.
  - earlier: "`--wsl inherit` (Windows)"
    keep: Pass `--wsl inherit`.
    revert: Pass `--wsl ignore`, then verify the Windows sources in [WSL on Windows](#wsl-on-windows) omit it or set `null`, `false`, or `"false"`.
  - earlier: "`--mcp-url` or `--mcp-command` (`allowlist`)"
    keep: Pass each server flag again.
    revert: Pass `--gateway-mcp-only` to drop unlisted earlier entries.
{% endtable %}

For profiles with gateway MCP servers, `fleet build` refuses to omit `--mcp-servers` even when keeping `allowlist`.

## Version bounds

`--claude-code-minimum` writes `requiredMinimumVersion` and `minimumVersion`, and `--claude-code-maximum` writes `requiredMaximumVersion`.

### Version range checks

`fleet build` refuses a version range when:

* `--claude-code-minimum` is earlier than `2.1.163`, the first release reading version bounds (flags only).
* The maximum version (`--claude-code-maximum` or combined `requiredMaximumVersion`) is earlier than `2.1.285`, the first release keeping every session on the gateway.
* The minimum version (`--claude-code-minimum`, or combined `requiredMinimumVersion` or `minimumVersion`) is later than the maximum version.

### How version bounds behave

Version bounds enforce the range at startup and during updates:

* **Startup check:** {{ site.claude_code }} refuses to start outside the range and prompts to install an approved version (a running session continues until restart).
* **Native and npm installs:** Background updates and `claude update` stay within the bounds.
* **Homebrew:** Updates run through `brew upgrade`, so pin the version in your install tool.
* **Claude Desktop:** Deploy a release with a bundled {{ site.claude_code }} in range.
  [Turn off automatic updates](https://code.claude.com/docs/en/desktop#device-management-policies) through MDM on macOS and Windows (Microsoft Store installs still update), or pin the version in your Linux package manager.

## Model overrides

`fleet build` applies `--model` overrides to managed settings and the machine-wide profile:

* **Family detection:** `fleet build` detects `opus`, `sonnet`, `haiku`, or `fable` from `NEW_MODEL_ID`, or takes `--model FAMILY=NEW_MODEL_ID` (for example, `--model sonnet=NEW_MODEL_ID`).
  Repeat `--model` per family (`fleet build` refuses duplicate flags per family), using 1 to 128 visible ASCII characters per ID.
* **Settings and roles:** `--model` updates the family slot and only roles matching the family's previous model (`active`, `default`, `subagent`, `background_classifier`, and `auto_mode`), leaving other roles unchanged.
* **`/cost` rates:** Managed settings include `/cost` rates (`modelPricing`) for the new model whenever the profile or {{ site.ai_gateway }} provides all required USD rates (`input`, `output`, `cache_read`, and `cache_write`, or `cache_write_1h` with one-hour prompt caching), even if other models lack rates.
* **Local profile unchanged:** Your build computer's local profile stays unchanged, so repeat `--model` on later rebuilds unless you pass `--profile-models`.
