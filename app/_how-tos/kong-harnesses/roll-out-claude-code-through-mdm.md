---
title: Roll out {{ site.claude_code }} through MDM
content_type: how_to
permalink: /kong-harnesses/roll-out-claude-code-through-mdm/
breadcrumbs:
  - /kong-harnesses/

description: Build {{ site.claude_code }} managed settings from a kong-harnesses profile, deploy them through MDM, and let each developer sign in to {{ site.ai_gateway }} as themselves.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

automated_tests: false

min_version:
  ai-gateway: '2.4'

tags:
  - ai
  - anthropic

related_resources:
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: Install kong-harnesses for every user of a computer
    url: /kong-harnesses/install/
  - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
    url: /kong-harnesses/maintain-a-claude-code-fleet/
  - text: "{{ site.claude_code }} managed settings"
    url: https://code.claude.com/docs/en/managed-settings

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: kong-harnesses
      content: |
        This guide uses [kong-harnesses](/kong-harnesses/) to build the managed settings.
        Install a kong-harnesses release that includes `fleet build` and `fleet remove` on the computer where you build the managed settings.

        {:.info}
        > **Supported computers:** kong-harnesses runs on macOS, on Windows 11, and on Linux desktops with Secret Service, such as Ubuntu 26.04, 24.04, and 22.04, and Red Hat Enterprise Linux 9, on amd64 and arm64.
        > Set it up on the desktop you work on, not in WSL, a container, or an SSH session.

        {% navtabs "install-kong-harnesses" %}
        {% navtab "macOS" %}
        {% include tools/kong-harnesses/install/osx.md %}
        {% endnavtab %}
        {% navtab "Linux" %}
        {% include tools/kong-harnesses/install/linux.md %}
        {% endnavtab %}
        {% navtab "Windows" %}
        {% include tools/kong-harnesses/install/windows.md %}
        {% endnavtab %}
        {% endnavtabs %}

        Run `kong-harnesses fleet build --help` to confirm your release includes the fleet commands.
        If the shell can't find `kong-harnesses`, open a new terminal.
    - title: A kong-harnesses profile
      content: |
        Create an OIDC kong-harnesses profile using [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/), replacing the local `http://` address with the `https://` origin of your deployed gateway.
        Install the profile on your build computer.
        This guide names the profile `work`.
        Replace `work` with your profile name in every command and path.

        The gateway origin must use `https://`.
        `kong-harnesses fleet build` refuses a plain `http://` origin and refuses a Claude subscription sign-in profile.
        If your profile uses the Anthropic API provider, your build computer must reach the gateway.
        If the gateway certificate comes from a private CA, add that CA to the build computer's system trust store.
    - title: An MDM tool and test access
      content: |
        You need a mobile device management (MDM) tool that deploys packages and configuration profiles or policies, such as Jamf Pro on macOS or Microsoft Intune on Windows, or a configuration management tool on Linux.

        You also need administrator rights on one test computer for each platform and policy group and access to the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) in {{ site.ai_cost_management }} to confirm gateway routing.
        See [How the views relate](/ai-cost-management/analytics-and-debugging/#how-the-views-relate) for the role required to view a test user's events.

tldr:
  q: How do I roll out {{ site.claude_code }} to managed computers with kong-harnesses?
  a: |
    Sign in to your HTTPS kong-harnesses profile if it uses the Anthropic API, then run `kong-harnesses fleet build` for each platform and policy group.
    Deploy {{ site.claude_code }}, kong-harnesses, any private gateway CA, and the build files through your MDM tool to a test computer first.
    Validate with `kong-harnesses doctor`, `/status`, and a test prompt before rolling out to the rest of the group.
    Each developer signs in through the browser on first use.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        1. Before you uninstall kong-harnesses, ask every developer with a user-level activation to remove their user-level {{ site.claude_code }} settings, regardless of the build's MCP mode (even for an `exclusive` build).
           Add `--dry-run` to preview the changes:

           ```sh
           kong-harnesses profile cleanup --client claude-code
           ```

           [`profile cleanup`](/kong-harnesses/profile/cleanup/) doesn't take a profile name and removes whatever kong-harnesses setup the developer's user-level settings use, even for another profile.
           It works before or after you delete the build files, as long as kong-harnesses is still installed.
        1. Unassign the build package or script in your MDM tool so it doesn't reinstall after deletion.
           For an Intune macOS app (PKG), remove groups from both its Required and Available assignments.
        1. Run `kong-harnesses fleet remove` with the build's record file (`kong-harnesses-fleet-BUILD_ID.json`).
           For an MDM build, pass the policy file that the computers receive now with `--policy` (an older copy discards later changes).
           For an `exclusive` build, pass the `managed-mcp.json` that the computers have now with `--mcp-config`.
           Pass a new or empty folder with `--output-dir` whenever policy keys or your own MCP servers remain.

           To remove a file build, run `fleet remove` with `--record` (add `--mcp-config 'MCP_CONFIG_FILE' --output-dir fleet-removed-BUILD_ID` for an `exclusive` MCP build):

           ```sh
           kong-harnesses fleet remove --record 'BUILD_RECORD'
           ```

           To remove an MDM build, pass both `--record` and the current `--policy` file (add `--mcp-config 'MCP_CONFIG_FILE'` for an `exclusive` MCP build):

           ```sh
           kong-harnesses fleet remove \
             --record 'BUILD_RECORD' \
             --policy 'POLICY_FILE' \
             --output-dir fleet-removed-BUILD_ID
           ```

        1. Follow the instructions that `fleet remove` prints:
           * If `fleet remove` writes a policy under `mdm/`, review the listed removed and restored values and deploy the updated policy in place of the existing one.
           * If `fleet remove` prints `Remove the Claude Code policy from your MDM`, remove the {{ site.claude_code }} policy from your MDM tool even when `fleet remove` doesn't write an `mdm/` folder.
           * If `fleet remove` writes `managed-mcp.json` under `root/`, remove any kept gateway server definitions that changed after the build and deploy the updated file.
           * Delete every file path listed under `Remove` from each managed computer as an administrator.
        1. On macOS, forget the package receipt on each computer so your MDM tool can install a future package with the same identifier and version:

           ```sh
           sudo pkgutil --forget PACKAGE_IDENTIFIER
           ```
---

Use `kong-harnesses fleet build` to turn a kong-harnesses profile into a machine-wide profile and [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) that lock managed macOS, Linux, and Windows computers to {{ site.ai_gateway }}.
By default, {{ site.claude_code }} in Windows Subsystem for Linux (WSL) reads only its own managed settings unless you enable Windows inheritance with `--wsl inherit`.
Developers don't import profiles manually.
Each developer signs in as themselves in the browser the first time {{ site.claude_code }} requests a credential, and kong-harnesses renews the token automatically.

## Sign in to the profile

If your profile uses the Anthropic API provider, `kong-harnesses fleet build` fetches the gateway's model list with your sign-in.
Sign in to the `work` profile with [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

kong-harnesses opens your browser so you can sign in to your identity provider.

If your profile uses another Claude provider, such as Amazon Bedrock, `fleet build` uses the models defined in the profile or `--model` flags and doesn't need a sign-in.

## Choose build options

Run `kong-harnesses fleet build` once for each group of managed computers that share the same platform, delivery method, existing {{ site.claude_code }} policy, and (for `exclusive` MCP mode) `managed-mcp.json`.
Deploy each build only to its matching group.

{:.warning}
> **Keep secrets out of managed files:** Every account on a managed computer can read managed settings and `managed-mcp.json`.
> Before building, remove all secrets from any file you pass to `--policy` or `--mcp-config`, such as API keys in `env`, `ANTHROPIC_CUSTOM_HEADERS`, or MCP server definitions.
> Use [per-user credentials](https://code.claude.com/docs/en/managed-mcp#authenticate-with-per-user-credentials) for MCP servers that require keys.

### Delivery method and existing policy

{{ site.claude_code }} evaluates managed sources in [precedence order](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources):

1. Remote settings from the claude.ai admin console or a Claude apps gateway.
1. An MDM policy (`com.anthropic.claudecode` on macOS or `HKLM\SOFTWARE\Policies\ClaudeCode` `Settings` on Windows).
1. Managed settings files (`managed-settings.json` and `managed-settings.d/`).

By default, {{ site.claude_code }} takes most keys, including `apiKeyHelper`, only from the highest active source that sets a policy key to a value other than empty objects or `null`.
A source that sets only the control keys `managedSourcesBehavior` and `wslInheritsWindowsSettings` doesn't count.
{{ site.claude_code }} reads [select keys from every administrator source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source), including `env` and MCP locks.

{% table %}
columns:
  - title: Delivery flag
    key: delivery
  - title: Platforms
    key: platforms
  - title: When to use
    key: when
  - title: Policy flag
    key: policy
rows:
  - delivery: "`--delivery file` (default)"
    platforms: macOS, Linux, Windows
    when: Writes `managed-settings.d/kong-harnesses.json` when computers don't receive an MDM policy that sets a policy key.
    policy: Pass `--policy POLICY_FILE` with your `managed-settings.json`, or `--no-policy` if computers don't have one (even with other `managed-settings.d/` files).
  - delivery: "`--delivery mdm`"
    platforms: macOS, Windows
    when: Use when computers receive an MDM policy that sets a policy key, or when you prefer MDM policy delivery.
    policy: Pass your XML property list (`com.anthropic.claudecode.plist`) or JSON object file with the Windows `Settings` value (not a `.reg` export) using `--policy POLICY_FILE`, or pass `--no-policy`.
{% endtable %}

Review your existing policy before building:

* **Remote settings:** Migrate policy from the claude.ai admin console or a Claude apps gateway into your MDM policy or `managed-settings.json`.
  Keep server-managed settings only if developers also run [Anthropic-hosted cloud sessions](https://code.claude.com/docs/en/server-managed-settings#choose-between-server-managed-and-endpoint-managed-settings).
  Otherwise, remove the server-managed policy from its source only after the build is deployed to every computer it covers.
  On managed computers, remove every credential that loads the conflicting remote policy, including an organization claude.ai sign-in, `CLAUDE_CODE_OAUTH_TOKEN`, or a direct API key (see [Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)).
* **Keys that `fleet build` rejects:** Remove the following from your `--policy` input before building:
  * `forceLoginMethod` or `forceLoginGatewayUrl`
  * `policyHelper` or `policyHelpers`
  * Any text `allowedProviders` entry other than `customEndpoint`
  * `Authorization`, `Proxy-Authorization`, `X-Api-Key`, or `Host` headers in `ANTHROPIC_CUSTOM_HEADERS`
* **Keys you must check yourself:** Remove `forceLoginOrgUUID` (blocks `apiKeyHelper` at startup) and `enforceAnthropicSignIn`.
  Confirm `disableAllHooks` isn't `true`, and verify `availableModels` and `deniedModels` permit every model in the build.
* **Custom headers on MDM builds:** The build pins `ANTHROPIC_CUSTOM_HEADERS`, and {{ site.claude_code }} takes each `env` variable from the [highest administrator source that defines it](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source).
  Move any required non-secret custom headers from `managed-settings.json` and `managed-settings.d/` into your `--policy` file, in both first-wins and merge modes.
* **Drop-in files on file builds:** `--policy` inspects only `managed-settings.json`, while {{ site.claude_code }} [merges `managed-settings.d/` files alphabetically](https://code.claude.com/docs/en/managed-settings#split-a-file-based-policy-across-teams).
  Check every drop-in file regardless of sort order for `policyHelper`, `policyHelpers`, login keys (`forceLoginMethod`, `forceLoginGatewayUrl`, `forceLoginOrgUUID`, `enforceAnthropicSignIn`), and `allowedProviders` entries other than `customEndpoint` (because `allowedProviders` lists combine across files).
  Ensure files sorting after `kong-harnesses.json` don't override keys the build sets, such as `apiKeyHelper`, `env`, or `modelPicker`.
  Move required non-secret `ANTHROPIC_CUSTOM_HEADERS` from earlier drop-in files into `managed-settings.json` so the build preserves them.
* **Merged managed sources:** If your organization sets `managedSourcesBehavior` to `merge` with an MDM build, include `managedSourcesBehavior` in your `--policy` file.
  Verify your `managed-settings.json` and `managed-settings.d/` files don't add conflicting keys or unwanted list entries (see [Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source)).
  An MDM policy that sets a policy key still prevents a file build from supplying `apiKeyHelper` in merge mode.

### MCP server mode

The `--mcp-servers` flag controls which MCP servers {{ site.claude_code }} loads.
It defaults to `allowlist` only when the profile doesn't define gateway MCP servers.
When the profile defines gateway MCP servers, you must pass `--mcp-servers` explicitly.

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Behavior
    key: behavior
  - title: Gateway MCP delivery
    key: gateway
  - title: Related flags
    key: flags
rows:
  - mode: "`exclusive`"
    behavior: Writes `managed-mcp.json` under `root/` (requires at least one gateway MCP server) so {{ site.claude_code }} blocks developer, project, and plugin servers.
    gateway: Deployed automatically in `managed-mcp.json`.
    flags: |
      Pass an existing `managed-mcp.json` with `--mcp-config MCP_CONFIG_FILE`.
      Incompatible with `--mcp-url`, `--mcp-command`, and `--wsl inherit`.
  - mode: "`allowlist`"
    behavior: Sets `allowManagedMcpServersOnly` to `true` and combines eligible existing managed `allowedMcpServers` entries with gateway MCP servers and flag entries.
    gateway: Each developer runs `kong-harnesses profile activate work --client claude-code`.
    flags: Repeat `--mcp-url 'URL_PATTERN'` (`http`, `https`, or `*` scheme) or `--mcp-command 'COMMAND_JSON_ARRAY'` (exact stdio command array).
  - mode: "`any`"
    behavior: Doesn't add an MCP lock and leaves MCP server choices to developers (existing policy locks still apply).
    gateway: Each developer runs `kong-harnesses profile activate work --client claude-code`.
    flags: Incompatible with `--mcp-url`, `--mcp-command`, and `--mcp-config`.
{% endtable %}

Check the following rules when choosing an MCP mode:

* **Exceptions and denylist rules:** With `exclusive`, {{ site.claude_code }} still loads servers from `managedMcpServers` and other [exclusive-control exceptions](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json), including Claude Desktop connectors and Claude in Chrome when `allowClaudeInChromeWithManagedMcp` is enabled.
  Check `managedMcpServers` if the fleet must load only the servers in `managed-mcp.json`, and remove any `managedMcpServers` entry at a gateway MCP URL under a different name because {{ site.claude_code }} loads both.
  With `allowlist`, policy-provided servers (`managedMcpServers`) and [servers that skip the allowlist check](https://code.claude.com/docs/en/managed-mcp#servers-that-skip-the-allowlist-check) (including built-in IDE, Chrome, and Agent SDK servers) also load.
  In every mode, `deniedMcpServers` across all scopes blocks matching servers, including gateway MCP servers (see [How a server is evaluated](https://code.claude.com/docs/en/managed-mcp#how-a-server-is-evaluated)).
  Verify your policies don't deny a gateway MCP server.
* **Existing `managed-mcp.json` collisions (`exclusive`):** Rename any server in your `--mcp-config` file that shares a name with a gateway MCP server before building, or pass `--record` for an earlier fleet build.
* **MDM allowlists displace file allowlists (`allowlist`):** Because {{ site.claude_code }} takes `allowedMcpServers` from the [highest administrator source that sets one](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source) when the lock is active, an MDM `allowlist` build replaces allowlists in `managed-settings.json` and `managed-settings.d/`.
  Move required entries from managed settings files into your `--policy` file, or pass them with `--mcp-url` or `--mcp-command`.
* **Replace matching `serverName` entries (`allowlist`):** The build adds `serverUrl` entries for gateway MCP servers and `--mcp-url` flags, which stop `serverName` entries from matching remote servers.
  When you pass `--mcp-command`, the build adds `serverCommand` entries, which stop `serverName` entries from matching stdio servers.
  Replace matching `serverName` entries in your existing `allowedMcpServers` with `--mcp-url` or `--mcp-command`.
* **Literal allowlist values:** Write literal URLs and commands without `${...}` variable references.
  `fleet build` rejects `${...}` in `--mcp-url` and `--mcp-command`, and {{ site.claude_code }} [expands `${...}`](https://code.claude.com/docs/en/managed-mcp#how-policy-entries-expand) in policy entries from each developer's shell environment.
* **Settings that block the gateway MCP plugin (`allowlist` or `any`):** {{ site.claude_code }} won't load the plugin that `profile activate` installs when any of the following apply:
  * The computer has a `managed-mcp.json` file.
  * Managed settings set `strictPluginOnlyCustomization` to `true`, or to a list containing `skills`, `agents`, `hooks`, or `mcp` (`false` and `[]` don't block the plugin).
  * Managed settings set `strictKnownMarketplaces` (or its alias `allowedMarketplaces`) without a `{"source": "skills-dir"}` entry.
  * Managed settings list `{"source": "skills-dir"}` in `blockedMarketplaces`.
  * Managed settings set an unreadable or malformed value in those keys, which fails closed (see [Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)).

  Use `exclusive` or update those settings.
  Also avoid a `managedMcpServers` entry at the same URL as a gateway MCP server, because [provided servers take precedence](https://code.claude.com/docs/en/managed-mcp#how-provided-servers-load) over plugin servers at the same URL.
* **Conflicting CLI startup flags:** Remove `--mcp-config` and `--strict-mcp-config` from wrapper scripts, aliases, and IDE launch settings.
  When `managed-mcp.json` is present, {{ site.claude_code }} [exits at startup](https://code.claude.com/docs/en/managed-mcp#servers-passed-with-mcp-config-or-strict-mcp-config) if either flag is passed.
  With `allowlist` or `any`, `--strict-mcp-config` skips plugin MCP servers.

### Optional flags

Add optional flags to `kong-harnesses fleet build` when your deployment needs host settings merging, WSL inheritance, model overrides, or version pinning:

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Purpose
    key: purpose
rows:
  - flag: "`--host-settings merge`"
    purpose: Sets `parentSettingsBehavior` to `merge` so {{ site.claude_code }} merges restrictive settings from embedding host apps such as IDE extensions or Agent SDK apps.
  - flag: "`--wsl inherit`"
    purpose: Sets `wslInheritsWindowsSettings` to `true` on Windows and writes helper commands that run Windows `kong-harnesses.exe` through WSL interop.
  - flag: "`--model MODEL_ID` or `--model FAMILY=MODEL_ID`"
    purpose: Overrides the default model for a Claude family (see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/)).
  - flag: "`--claude-code-minimum VERSION`, `--claude-code-maximum VERSION`"
    purpose: Pins managed computers to a tested range of {{ site.claude_code }} versions, with `--claude-code-maximum` at `2.1.285` or later (see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/)).
{% endtable %}

Review these requirements before enabling host settings merging or WSL inheritance:

* **Host settings (`--host-settings merge`):**
  * The default (`ignore`) doesn't write `parentSettingsBehavior` and keeps any value in your existing policy.
  * When host settings merge, {{ site.claude_code }} keeps restrictive host settings and also admits the following host rules unless your managed settings lock them:
    * Host permission allow rules (unless `allowManagedPermissionRulesOnly` is `true`).
    * Sandbox network domains (unless `sandbox.network.allowManagedDomainsOnly` is `true`).
    * Sandbox read paths (unless `sandbox.filesystem.allowManagedReadPathsOnly` is `true`).
    See [Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy) and [Restrict parent settings](https://code.claude.com/docs/en/claude-apps-gateway#restrict-parent-settings).
  * Confirm the host app doesn't pass `forceLoginOrgUUID` (which blocks `apiKeyHelper` at startup when your managed settings don't set it), an `availableModels` list that excludes build models, or plugin-blocking settings.
  * Claude Desktop doesn't call `apiKeyHelper` and requires its own [third-party gateway configuration](https://code.claude.com/docs/en/llm-gateway-connect#desktop-app).
* **WSL on Windows (`--wsl inherit`):**
  * WSL is outside the default Windows rollout, because {{ site.claude_code }} in WSL reads only its own `/etc/claude-code` settings unless a Windows policy enables [`wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings).
  * `--wsl inherit` requires Windows interop enabled in each WSL distribution, a supported Linux {{ site.claude_code }} install ([Install in WSL](https://code.claude.com/docs/en/setup#install-in-wsl)), and any private gateway CA added inside each distribution.
  * `--wsl inherit` is incompatible with `--mcp-servers exclusive` and with an `--executable` path containing `'`, `"`, `%`, or `!`.
  * `fleet build` rejects `NODE_EXTRA_CA_CERTS`, `CLAUDE_CODE_CLIENT_CERT`, and `CLAUDE_CODE_CLIENT_KEY` in `--policy`, because WSL can't open Windows certificate paths.
    Because {{ site.claude_code }} merges `env` from every Windows administrator source into WSL, verify that `HKLM\SOFTWARE\Policies\ClaudeCode`, `managed-settings.json`, and `managed-settings.d/` don't set those variables either.
  * Gateway MCP servers don't load in WSL in any mode, and because developers control their WSL distribution, enforcement in WSL applies only while the developer runs an unchanged {{ site.claude_code }}.
  * Without `--wsl inherit`, verify that `HKLM\SOFTWARE\Policies\ClaudeCode`, `managed-settings.json`, and every file in `managed-settings.d/` omit `wslInheritsWindowsSettings` or set it to `null`, `false`, or `"false"`.
    Any other value turns WSL inheritance on.

## Build the managed settings

Run `kong-harnesses fleet build` for each target group.
You can build for any platform from one computer by setting `--platform`.

Before running the command, replace these placeholders and keep the quotes:

* `DELIVERY`: `file` or `mdm` (macOS and Windows only; Linux supports only `file` delivery).
* `POLICY_FILE`: Path to your copy of `managed-settings.json` for a file build or your MDM policy file for an MDM build (replace `--policy 'POLICY_FILE'` with `--no-policy` if the group doesn't have an existing policy file).
* `MCP_MODE`: `exclusive`, `allowlist`, or `any` (add `--mcp-config 'MCP_CONFIG_FILE'` with `exclusive`, or `--mcp-url` and `--mcp-command` with `allowlist`).
* `GROUP`: A short name without spaces for the computer group (`--output-dir` must be a new or empty folder).

Set `--executable` to the exact absolute path where the system-wide kong-harnesses package installs the binary (`kong-harnesses` on macOS and Linux, or `kong-harnesses.exe` with a drive letter and backslashes on Windows).
On Windows, `--executable` must not contain `"`, `%`, `!`, or control characters (and must not contain `'` with `--wsl inherit`).
On macOS and Linux, `--executable` must not contain line breaks or NUL bytes (and must not contain control characters for a macOS MDM build).

Build the managed settings for your target platform and delivery method:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --delivery DELIVERY \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --mcp-servers MCP_MODE \
  --output-dir fleet-macos-GROUP
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform linux \
  --executable /usr/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --mcp-servers MCP_MODE \
  --output-dir fleet-linux-GROUP
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build `
  --profile work `
  --platform windows `
  --delivery DELIVERY `
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' `
  --policy 'POLICY_FILE' `
  --mcp-servers MCP_MODE `
  --output-dir fleet-windows-GROUP
```

When passing `--mcp-url` or `--mcp-command`, quote each value so PowerShell preserves `*` wildcards and JSON quotes.
In Windows PowerShell 5.1, escape inner double quotes with `\` (for example, `--mcp-command '[\"npx\",\"-y\",\"PACKAGE\"]'`), or use PowerShell 7.3 or later.

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build files into the output folder and prints a summary showing the settings, any modified keys from your `--policy`, the build ID, the record file path, and the platform install command.

## Check the build output

Inspect the generated `kong-harnesses fleet build` output folder before deploying.
`fleet build` writes the files to install on each computer under `root/` at their target paths:

{% table %}
columns:
  - title: Platform
    key: platform
  - title: Managed settings (file build)
    key: settings
  - title: Machine-wide profile
    key: profile
  - title: "MCP servers (`exclusive` only)"
    key: servers
rows:
  - platform: macOS
    settings: "`/Library/Application Support/ClaudeCode/managed-settings.d/kong-harnesses.json`"
    profile: "`/Library/Application Support/kong-harnesses/profiles/work.json`"
    servers: "`/Library/Application Support/ClaudeCode/managed-mcp.json`"
  - platform: Linux
    settings: "`/etc/claude-code/managed-settings.d/kong-harnesses.json`"
    profile: "`/etc/kong-harnesses/profiles/work.json`"
    servers: "`/etc/claude-code/managed-mcp.json`"
  - platform: Windows
    settings: "`C:\\Program Files\\ClaudeCode\\managed-settings.d\\kong-harnesses.json`"
    profile: "`C:\\Program Files\\kong-harnesses\\profiles\\work.json`"
    servers: "`C:\\Program Files\\ClaudeCode\\managed-mcp.json`"
{% endtable %}

Depending on your platform and delivery mode, the output folder also contains:

* `scripts/preinstall` (macOS): The installer preinstall safety check script.
* `mdm/com.anthropic.claudecode.plist` (macOS MDM build): XML property list for the `com.anthropic.claudecode` Custom Settings payload.
* `mdm/Settings.json` (Windows MDM build): Single-line JSON for the `REG_SZ` value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode`.
* `kong-harnesses-fleet-BUILD_ID.json`: The build record file, written outside `root/`.

{:.info}
> **Keep a backup of the build record:** `kong-harnesses-fleet-BUILD_ID.json` stores your build choices, original `--policy`, and gateway MCP definitions.
> Keep it with your policy, because you need it to update the build with `--record` or remove it with `fleet remove`.

Before deploying, confirm these three checks:

* **Modified policy keys and `modelPicker`:** Review every key change that `fleet build` lists.
  If `fleet build` reports changing `modelPicker`, inspect the generated `modelPicker` before deploying, because it replaces your whole `modelPicker` (including `replaceBuiltInOptions`) when a model ID isn't auto-discovered.
* **No secrets and expected helpers:** Confirm the generated settings and `managed-mcp.json` don't contain secrets.
  The credential helper runs `kong-harnesses credential --profile work` from `--executable` without storing developer credentials.
  The build's hooks report blocked MCP servers and, when the gateway or profile marks a model as unable to run WebSearch, skipped web searches.
* **Build ID:** Record the build ID in `env.KONG_HARNESSES_FLEET_BUILD` so you can verify it in `kong-harnesses doctor` during validation.

On managed computers, kong-harnesses reads the machine-wide profile ahead of any user profile with the same name.
It refuses the profile unless only administrators can modify the file and its parent folders.
On macOS and Linux, `root` must own them without group or world write permissions.
On Windows, Administrators, SYSTEM, or TrustedInstaller must own and be the only writers up to `C:\Program Files`, without symbolic links or junctions on the path.

## Deploy to managed computers

Deploy the fleet build to one test computer for each platform and policy group first.
Roll out to the rest of the group only after [Validate](#validate) passes.

Install the following components on each target computer through your MDM tool:

1. **{{ site.claude_code }}:** Install a supported version that enforces `allowedProviders` (`2.1.285` or later).
   See [Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup) and [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
   Run the native installer in each developer's user context rather than as `root` or SYSTEM, because it installs into the running user's home folder (`~/.local/bin/claude` or `%USERPROFILE%\.local\bin\claude.exe`).
   On Linux, you can also install from the [`apt`, `dnf`, or `apk` repositories](https://code.claude.com/docs/en/setup#install-with-linux-package-managers).
1. **kong-harnesses:** Install the system-wide package at the exact `--executable` path (see [Install kong-harnesses for every user of a computer](/kong-harnesses/install/)).
   Don't install kong-harnesses with Homebrew on managed Macs, because Homebrew shares `/usr/local/bin` on Intel Macs.
1. **Private gateway CA (if used):** Add your gateway's CA certificate to the OS system trust store, and to each WSL distribution if you use `--wsl inherit`.
   `fleet build` doesn't install CA certificates.
1. **Build files under `root/`:** Install the files with administrator privileges using the steps in [Package or copy the build files](#package-or-copy-the-build-files).
1. **MDM policy (MDM builds only):**
   * On macOS, upload `mdm/com.anthropic.claudecode.plist` as a Custom Settings payload for `com.anthropic.claudecode` in place of any existing policy.
   * On Windows, set the `REG_SZ` value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode` to the single line in `mdm/Settings.json` in place of any existing value.
   * If migrating from a file build, unassign the old file-build package or script first (for an Intune macOS PKG, remove groups from both Required and Available assignments).
     Then delete `managed-settings.d/kong-harnesses.json` so {{ site.claude_code }} doesn't still read its `env` or MCP lock.

### Package or copy the build files

{% navtabs "deploy-fleet-files" %}
{% navtab "macOS" %}

1. Copy the entire fleet build output folder to a Mac using a tool that preserves permissions, such as `ditto` or `rsync -a`.
1. Open a terminal in the copied output folder and build the unsigned component package with the `pkgbuild` command that `fleet build` printed, replacing `PACKAGE_IDENTIFIER` and `PACKAGE_VERSION`:

   ```sh
   find root scripts -type d -exec chmod 755 {} + \
     && find root -type f -exec chmod 644 {} + \
     && chmod 755 scripts/preinstall \
     && pkgbuild \
       --root root \
       --scripts scripts \
       --install-location / \
       --identifier PACKAGE_IDENTIFIER \
       --version PACKAGE_VERSION \
       kong-harnesses-fleet.pkg
   ```

   `pkgbuild` creates an unsigned component package (`kong-harnesses-fleet.pkg`) with `root` ownership, 755/644 permissions, and the preinstall safety check script.
1. If your MDM path requires a signed distribution package, such as [Apple MDM](https://support.apple.com/guide/deployment/distribute-packages-to-mac-computers-dep873c25ac4/web) or a Jamf Pro [PreStage enrollment package](https://learn.jamf.com/r/en-US/jamf-pro-documentation-current/Computer_PreStage_Enrollment_Payload_Reference), wrap and sign `kong-harnesses-fleet.pkg` with your Keychain installer certificate:

   ```sh
   productbuild --sign 'INSTALLER_IDENTITY' \
     --package kong-harnesses-fleet.pkg \
     kong-harnesses-fleet-signed.pkg
   ```

1. Deploy the signed package (or unsigned `kong-harnesses-fleet.pkg` where supported) through your MDM tool.
   For Microsoft Intune, add it as a [macOS app (PKG)](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos) rather than a line-of-business app, because this package doesn't install a `.app` bundle under `/Applications` (Intune may not report install detection).

{% endnavtab %}
{% navtab "Linux" %}

1. Confirm the `acl` package (which provides `getfacl`) is installed on each managed computer.
1. Copy the `root/` folder from the fleet build output folder to the target computer.
1. From inside the copied `root/` folder, run the `sudo sh -c` copy command that `fleet build` printed.

The command checks target ownership, permissions, links, and ACLs, copies the files under `/`, and sets `root:root` ownership with mode 755 on folders and 644 on files.

{% endnavtab %}
{% navtab "Windows" %}

1. Before deploying, check that `C:\Program Files` allows only Administrators, SYSTEM, TrustedInstaller, or CREATOR OWNER to modify files, and confirm that existing destination folders (for example, `C:\Program Files\ClaudeCode`) can lose their explicit ACL rules.
1. Copy the `root/` folder from the fleet build output folder to the target computer.
1. Open Windows PowerShell as an administrator inside the copied `root/` folder and run the PowerShell copy command that `fleet build` printed.

The command checks target ownership, ACLs, links, and hard links, copies the files under `C:\`, sets Administrators ownership, and runs `icacls /reset` on every written path (including existing folders) so they inherit ACLs from `C:\Program Files`.

{% endnavtab %}
{% endnavtabs %}

{:.info}
> **Preinstall safety checks:** Before writing any file, the macOS preinstall script and Linux and Windows copy commands inspect existing target files and parent folders.
> * If installation stops with `Not installed:`, fix the reported condition on the named path and run the install again.
>   Common causes include a symlink, an extra hard link, an unexpected owner, writable permissions or ACLs, or a missing `getfacl` on Linux.
> * Remove an unexpected file or link only at a build file's exact path, and never remove system folders such as `/etc`, `/Library`, or `C:\Program Files`.
> * On Linux and Windows, if installation stops with `could not be written in full; fix the cause and run the step again`, the build can be partly written on the computer.
>   Fix the reported cause and run the install command again.

## Validate

Sign in to each test computer as a standard developer account without a saved sign-in to the profile, and verify the fleet build before sending a prompt.

1. If you built with `--mcp-servers allowlist` or `any` and the profile defines gateway MCP servers, activate the gateway MCP plugin as the developer with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

   ```sh
   kong-harnesses profile activate work --client claude-code
   ```

   kong-harnesses installs the gateway MCP plugin in `~/.claude/skills` (`%USERPROFILE%\.claude\skills` on Windows, or `skills` inside `CLAUDE_CONFIG_DIR`).
   If this fails because the developer's `settings.json` sets `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, remove those variables from `env` and run the command again.
1. Check the fleet configuration with [`kong-harnesses doctor`](/kong-harnesses/doctor/):

   ```sh
   kong-harnesses doctor --profile work --client claude-code
   ```

   Confirm that `doctor` reports your organization's managed settings configure {{ site.claude_code }} and that the printed build ID matches `fleet build`.
   With a test account that doesn't have a saved sign-in yet, `doctor` notes that the first request will open the browser, which is expected.
   Fix any reported errors before continuing.
1. Start {{ site.claude_code }} to verify the first-use browser sign-in:

   ```sh
   claude
   ```

   kong-harnesses opens the browser on startup (for Anthropic API model discovery) or on the first request.
   Sign in with the test developer's identity provider account and confirm the sign-in succeeds.
1. Run `/status` inside {{ site.claude_code }} before sending a prompt and inspect the `Setting sources` line.
   Expect `Enterprise managed settings` with one of the following labels:
   * **File build:** `(drop-ins)` or `(file + drop-ins)`.
   * **MDM build:** `(plist)` on macOS, `(HKLM)` on Windows, or a `, merged` list starting with `plist` or `HKLM`.

   Together with the build ID from `kong-harnesses doctor`, this confirms that {{ site.claude_code }} applies your fleet build.
1. Send a short prompt such as `Say hello` and confirm you receive a reply without errors.
   Open the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) in {{ site.ai_cost_management }} and verify the test user's usage event appears under your profile's gateway control plane.
   With the setup guide's OIDC strategy, filter by **User** `oidc/SUB` (where `SUB` is the test user's `sub` claim), or configure [subject attribution](/ai-cost-management/attribution/#set-up-subject-attribution).
   Also confirm your policies don't set `disableAllHooks` to `true`, because the test prompt doesn't verify hooks.
1. If your profile defines gateway MCP servers, run `/mcp` inside {{ site.claude_code }} and confirm every server shows as connected.

### Troubleshoot gateway MCP connections

If a gateway MCP server isn't connected or doesn't appear in `/mcp`, check these causes:

* **Key server without a saved key:** Run `kong-harnesses login --profile work` once to save each key.
* **Rejected key on a key server:** Run `kong-harnesses logout --profile work` and then `kong-harnesses login --profile work`.
  `logout` asks you to type the profile name, signs out of the profile, and removes both the saved sign-in and every saved gateway MCP key of the profile.
  Have all server keys ready before running `logout`.
* **Server with its own OAuth sign-in:** Sign in from `/mcp`.
* **Gateway-authenticated server failed at startup:** If a server [fails during the initial browser sign-in](https://code.claude.com/docs/en/mcp#failed-first-connections), reconnect it from `/mcp` after signing in.
* **Missing servers:** Check `kong-harnesses doctor` output, remove `--strict-mcp-config` from startup commands, and check `deniedMcpServers` across all settings scopes (user, project, local, `--settings`, and every administrator source).
  `doctor` reads only one administrator source and skips `deniedMcpServers` when `managed-mcp.json` is present.

### Troubleshoot status labels

If `/status` shows an unexpected `Setting sources` label, check the `Skipped sources` line and run `claude doctor` to list [dropped invalid managed settings fields](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped).
See [How {{ site.claude_code }} combines managed sources](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources) for all source labels, and use the following fleet-specific fixes:

{% table %}
columns:
  - title: Observed label
    key: label
  - title: Cause and fix
    key: fix
rows:
  - label: "Missing `Enterprise managed settings`, `(file)`, or `(HKCU)`"
    fix: |
      Build files or MDM policy didn't reach the computer, or the policy sets only control keys.
      Verify the files at their target paths and redeploy.
  - label: "`(drop-ins)` or `(file + drop-ins)` on an MDM build"
    fix: |
      The MDM policy didn't reach the computer or sets only control keys such as `managedSourcesBehavior`.
      Check `Skipped sources`, verify the deployed MDM policy, and redeploy.
  - label: "`(plist)`, `(HKLM)`, or a merged list starting with `plist` or `HKLM` on a file build"
    fix: |
      An MDM policy outranks `managed-settings.d/` (even when merged, `apiKeyHelper` comes from the MDM policy).
      Rebuild with `--delivery mdm --policy`.
  - label: "`(remote)` or a merged list starting with `remote`"
    fix: |
      Server-managed settings outrank the build.
      Remove every credential loading the conflicting policy, including an organization claude.ai sign-in, `CLAUDE_CODE_OAUTH_TOKEN`, or a direct API key ([Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)).
      Cached remote settings can persist for up to 24 hours.
      Remove server-managed settings from their source only after the build is on every computer they cover.
  - label: "`(helper)`"
    fix: |
      `policyHelper` or `policyHelpers` in the MDM policy, `managed-settings.json`, or `managed-settings.d/` overrides managed settings.
      Remove it from all managed sources.
  - label: "`(parent process)`"
    fix: |
      Only host-app settings loaded.
      Start `claude` from a terminal to confirm, then redeploy the build.
{% endtable %}

### Check host apps and WSL

Validate host apps and WSL separately when your fleet build uses `--host-settings merge` or `--wsl inherit`:

* **Host apps (`--host-settings merge` or `parentSettingsBehavior` set to `merge`):** Start a session from each supported host app, such as the {{ site.claude_code }} extension for VS Code, and run `/status`, `/mcp`, and a test prompt.
  Terminal sessions and `kong-harnesses doctor` don't see host-passed settings.
  Exclude Claude Desktop, because it doesn't use the build's `apiKeyHelper` or gateway route.
* **WSL (`--wsl inherit`):** In each WSL distribution, start `claude` and run `/status` before sending a prompt.
  Confirm `Setting sources` shows `Enterprise managed settings` with a label matching the Windows build's delivery: `(drop-ins)` or `(file + drop-ins)` for a file build, or `(HKLM)` or a merged list starting with `HKLM` for an MDM build.
  A generic `Enterprise managed settings` label alone can indicate a WSL-local `/etc/claude-code` policy instead of the Windows build.
  Send a short test prompt and confirm the WSL usage event appears in the Events debugger (`doctor` and gateway MCP servers don't run in WSL).
  If you hit a TLS error, confirm the private CA is trusted inside WSL and inspect [`claude --debug`](https://code.claude.com/docs/en/network-config#verify-your-configuration) logs under `~/.claude/debug/`.
* **Windows without `--wsl inherit`:** Confirm that `HKLM\SOFTWARE\Policies\ClaudeCode`, `C:\Program Files\ClaudeCode\managed-settings.json`, and every file in `C:\Program Files\ClaudeCode\managed-settings.d/` omit `wslInheritsWindowsSettings` or set it to `null`, `false`, or `"false"`.

After validation passes on each test computer, roll out the deployment to the rest of that group.
To pin {{ site.claude_code }} versions or move your fleet to a new model later, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
