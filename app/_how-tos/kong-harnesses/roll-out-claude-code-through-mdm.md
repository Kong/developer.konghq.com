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
        This guide uses [kong-harnesses](/kong-harnesses/) to build the managed settings. Install a kong-harnesses release that includes `fleet build` and `fleet remove` on the computer where you build the managed settings.

        {:.info}
        > **Supported computers:** kong-harnesses runs on macOS, on Windows 11, and on Linux desktops with Secret Service, such as Ubuntu 26.04, 24.04, and 22.04, and Red Hat Enterprise Linux 9, on amd64 and arm64. Set it up on the desktop you work on, not in WSL, a container, or an SSH session.

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

        Run `kong-harnesses fleet build --help` to confirm your release includes the fleet commands. If the shell can't find `kong-harnesses`, open a new terminal.
    - title: A kong-harnesses profile
      content: |
        Create an OIDC kong-harnesses profile using [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/), replacing the local `http://` address with the `https://` origin of your deployed gateway. Install the profile on your build computer. This guide names the profile `work`; replace `work` with your profile name in every command and path.

        The gateway origin must use `https://`. `kong-harnesses fleet build` refuses a plain `http://` origin and refuses a Claude subscription sign-in profile. If the gateway certificate comes from a private CA, add that CA to the build computer's system trust store.
    - title: An MDM tool and test access
      content: |
        You need a mobile device management (MDM) tool that deploys packages and configuration profiles or policies, such as Jamf Pro on macOS or Microsoft Intune on Windows, or a configuration management tool on Linux.

        You also need administrator rights on one test computer for each platform and policy group, plus access to the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) in {{ site.ai_cost_management }} to confirm gateway routing.

tldr:
  q: How do I roll out {{ site.claude_code }} to managed computers with kong-harnesses?
  a: |
    Sign in to your HTTPS kong-harnesses profile if it uses the Anthropic API, then run `kong-harnesses fleet build` for each platform and policy group. Deploy {{ site.claude_code }}, kong-harnesses, any private gateway CA, and the build files through your MDM tool to a test computer first, then validate with `kong-harnesses doctor` and `/status`. Each developer signs in through the browser on first use.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        1. For a build with `--mcp-servers allowlist` or `any`, ask developers who ran `profile activate` to remove their user-level settings before you uninstall kong-harnesses (add `--dry-run` to preview changes):

           ```sh
           kong-harnesses profile cleanup --client claude-code
           ```

           [`profile cleanup`](/kong-harnesses/profile/cleanup/) removes the active kong-harnesses setup from the developer's own {{ site.claude_code }} settings.
        1. Unassign the build package or script in your MDM tool so it doesn't reinstall after deletion. For an Intune macOS app (PKG), remove groups from both its Required and Available assignments.
        1. Run `kong-harnesses fleet remove` with the build's record file (`kong-harnesses-fleet-BUILD_ID.json`). Pass `--policy` for an MDM build, `--mcp-config` for an `exclusive` build, and `--output-dir` (a new or empty folder) whenever policy keys or your own MCP servers remain:

           ```sh
           # File build (add --mcp-config 'MCP_CONFIG_FILE' --output-dir fleet-removed-BUILD_ID for exclusive MCP builds)
           kong-harnesses fleet remove --record 'BUILD_RECORD'
           ```

           ```sh
           # MDM build (add --mcp-config 'MCP_CONFIG_FILE' for exclusive MCP builds)
           kong-harnesses fleet remove --record 'BUILD_RECORD' --policy 'POLICY_FILE' --output-dir fleet-removed-BUILD_ID
           ```

        1. Follow the instructions that `fleet remove` prints:
           * If policy keys remain under `mdm/`, review the listed removed and restored values and deploy the updated policy in place of the existing one (or remove the policy if none remain).
           * If your own MCP servers remain under `root/`, remove any kept gateway server definitions that were edited after the build and deploy the updated `managed-mcp.json`.
           * Delete every file path listed under `Remove` from each managed computer as an administrator.
        1. On macOS, forget the package receipt on each computer so your MDM tool can install a future package with the same identifier and version:

           ```sh
           sudo pkgutil --forget PACKAGE_IDENTIFIER
           ```
---

Use `kong-harnesses fleet build` to turn a kong-harnesses profile into a machine-wide profile and [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) that lock every managed computer to {{ site.ai_gateway }}. Developers don't import profiles manually: each developer signs in as themselves in the browser the first time {{ site.claude_code }} requests a credential, and kong-harnesses renews the token automatically.

In this guide, you sign in to your profile, choose delivery and MCP server options, build the managed settings for each computer group, check the generated files, deploy to a test computer through MDM, and validate the setup before rolling it out broadly.

## Sign in to the profile

If your profile uses the Anthropic API provider, `fleet build` fetches the gateway's model list with your sign-in. Your build computer must reach the gateway and trust its CA. Sign in to the profile with [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

kong-harnesses opens your browser so you can sign in to your identity provider.

If your profile uses another Claude provider, such as Amazon Bedrock, `fleet build` uses the models defined in the profile or `--model` flags and doesn't need a sign-in.

## Choose build options

Run `fleet build` once for each group of managed computers that share the same platform, delivery method, existing {{ site.claude_code }} policy, and (for `exclusive` MCP mode) `managed-mcp.json`. Deploy each build only to its matching group.

{:.warning}
> **Keep secrets out of managed files:** Every account on a managed computer can read managed settings and `managed-mcp.json`. Before building, remove all secrets, such as API keys in `env`, `ANTHROPIC_CUSTOM_HEADERS`, or MCP server definitions, from any file you pass to `--policy` or `--mcp-config`. Use [per-user credentials](https://code.claude.com/docs/en/managed-mcp#authenticate-with-per-user-credentials) for MCP servers that need keys.

### Delivery method and existing policy

{{ site.claude_code }} evaluates managed sources in precedence order: remote settings (claude.ai admin console or Claude apps gateway), MDM policy (`com.anthropic.claudecode` on macOS or `HKLM\SOFTWARE\Policies\ClaudeCode` `Settings` on Windows), and managed settings files (`managed-settings.json` and `managed-settings.d/`). By default, {{ site.claude_code }} takes most keys, including `apiKeyHelper`, only from the highest active source.

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
    when: Computers don't receive a {{ site.claude_code }} MDM policy. Writes a drop-in file at `managed-settings.d/kong-harnesses.json`.
    policy: Pass `--policy <managed-settings.json>` if computers have a `managed-settings.json` so `fleet build` checks it and keeps its `ANTHROPIC_CUSTOM_HEADERS`. Pass `--no-policy` if they don't, even if they have other files in `managed-settings.d/`.
  - delivery: "`--delivery mdm`"
    platforms: macOS, Windows
    when: Computers already receive a {{ site.claude_code }} MDM policy (an MDM policy outranks `managed-settings.d/`, even with `managedSourcesBehavior` set to `merge`), or you prefer MDM policy delivery.
    policy: Pass your existing XML property list (`com.anthropic.claudecode.plist` on macOS) or single-line JSON (`Settings.json` on Windows) with `--policy`, or pass `--no-policy` if you don't have one yet.
{% endtable %}

Review your existing policy before building:

* **Remote settings:** Migrate policy from the claude.ai admin console or a Claude apps gateway into your MDM policy or `managed-settings.json`, and ensure managed computers don't keep an organization claude.ai login that fetches remote settings above the build. Keep server-managed settings only if developers also run Anthropic-hosted cloud sessions.
* **Conflicting keys:** Remove `forceLoginMethod`, `forceLoginGatewayUrl`, `policyHelper`, `policyHelpers`, any `allowedProviders` entry other than `customEndpoint`, and `Authorization`, `Proxy-Authorization`, `X-Api-Key`, or `Host` headers in `ANTHROPIC_CUSTOM_HEADERS` (`fleet build` rejects them). Also remove `forceLoginOrgUUID` (blocks `apiKeyHelper` at startup) and `enforceAnthropicSignIn`, make sure `disableAllHooks` isn't `true`, and verify `availableModels` and `deniedModels` permit every model in the build.
* **Drop-in files (file builds):** `--policy` inspects only `managed-settings.json`. Ensure no file in `managed-settings.d/` sorting alphabetically after `kong-harnesses.json` overrides keys the build sets, for example `apiKeyHelper` or `env`, and move any custom headers from earlier drop-in files into `managed-settings.json` so the build preserves them.
* **Merged managed sources:** If your organization sets `managedSourcesBehavior` to `merge` with an MDM build, include `managedSourcesBehavior` in the `--policy` file, and verify your `managed-settings.json` and `managed-settings.d/` files don't add conflicting keys or list entries.

### MCP server mode

The `--mcp-servers` flag controls which MCP servers {{ site.claude_code }} loads. It defaults to `allowlist` only when the profile doesn't define gateway MCP servers; when the profile defines gateway MCP servers, you must specify `--mcp-servers` explicitly.

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
    behavior: Writes `managed-mcp.json` under `root/` (requires at least one gateway MCP server). {{ site.claude_code }} loads only servers in that file and built-in or host exceptions, blocking developer, project, and plugin servers.
    gateway: Deployed automatically on every computer in `managed-mcp.json`.
    flags: Pass existing `managed-mcp.json` with `--mcp-config` (rename any server that collides with a gateway MCP server). Incompatible with `--mcp-url`, `--mcp-command`, and `--wsl inherit`.
  - mode: "`allowlist`"
    behavior: Sets `allowManagedMcpServersOnly` to `true` and allows only your managed servers, the profile's gateway MCP servers, and servers you list via flags.
    gateway: Each developer runs `kong-harnesses profile activate work --client claude-code` to install the gateway MCP plugin.
    flags: Repeat `--mcp-url '<pattern>'` (remote server using `http`, `https`, or `*` scheme) or `--mcp-command '<JSON array>'` (exact stdio command and arguments).
  - mode: "`any`"
    behavior: Doesn't add an MCP lock and leaves MCP server choices to developers (any lock in your own policy still applies).
    gateway: Each developer runs `kong-harnesses profile activate work --client claude-code` to install the gateway MCP plugin.
    flags: Incompatible with `--mcp-url`, `--mcp-command`, and `--mcp-config`.
{% endtable %}

Keep the following MCP rules in mind when choosing a mode:

* **No variable references in allowlists:** Write literal URLs and commands without `${...}` references. `fleet build` rejects `${...}` in `--mcp-url` and `--mcp-command`, and {{ site.claude_code }} expands `${...}` in policy entries from each developer's shell environment. Quote values so your shell preserves wildcards and JSON quotes; in Windows PowerShell 5.1, escape inner double quotes with `\` (for example, `--mcp-command '[\"npx\",\"-y\",\"PACKAGE\"]'`), or use PowerShell 7.3 or later.
* **Replace matching `serverName` entries:** With `allowlist`, the build adds `serverUrl` and `serverCommand` entries, which cause `serverName` entries of the same server kind to stop matching in {{ site.claude_code }}. Replace matching `serverName` entries in your existing `allowedMcpServers` with `--mcp-url` or `--mcp-command`.
* **Settings that block the gateway MCP plugin:** With `allowlist` or `any`, {{ site.claude_code }} won't load the plugin that `profile activate` installs if the computer has `managed-mcp.json` or if managed settings set `strictPluginOnlyCustomization`, omit `{"source": "skills-dir"}` from `strictKnownMarketplaces` (or `allowedMarketplaces`), or list `{"source": "skills-dir"}` in `blockedMarketplaces`. Use `exclusive` or update those settings. Also avoid a `managedMcpServers` entry at the same URL as a gateway MCP server, and verify `deniedMcpServers` doesn't block a gateway MCP server.
* **Conflicting CLI startup flags:** Remove `--mcp-config` and `--strict-mcp-config` from wrapper scripts, aliases, and IDE launch settings. When `managed-mcp.json` is present, {{ site.claude_code }} exits on startup if either flag is passed; with `allowlist` or `any`, `--strict-mcp-config` skips plugin MCP servers.

### Optional flags

Add these flags to `fleet build` when your deployment needs them:

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Purpose and requirements
    key: purpose
rows:
  - flag: "`--host-settings merge`"
    purpose: Sets `parentSettingsBehavior` to `merge` so {{ site.claude_code }} keeps restrictive settings from host apps such as IDE extensions or Agent SDK apps. The default (`ignore`) writes nothing and preserves any `parentSettingsBehavior` in your policy. Note that Claude Desktop doesn't call `apiKeyHelper` and requires its own third-party gateway configuration.
  - flag: "`--wsl inherit`"
    purpose: Windows only. Sets `wslInheritsWindowsSettings` to `true` and writes helper commands that run Windows `kong-harnesses.exe` through WSL interop. Requires a supported Linux {{ site.claude_code }} install and any private gateway CA inside each WSL distribution. Incompatible with `--mcp-servers exclusive`, an `--executable` path containing `'`, and `--policy` files setting `NODE_EXTRA_CA_CERTS`, `CLAUDE_CODE_CLIENT_CERT`, or `CLAUDE_CODE_CLIENT_KEY` in `env`. Gateway MCP servers don't load in WSL. Without this flag, ensure no Windows admin source sets `wslInheritsWindowsSettings` to anything other than `false` or `null`.
  - flag: "`--model [<family>=]<id>`"
    purpose: Overrides the default model for a Claude family (for example, `--model opus=MODEL_ID`). See [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
  - flag: "`--claude-code-minimum`, `--claude-code-maximum`"
    purpose: Pins managed computers to a tested range of {{ site.claude_code }} versions (`--claude-code-maximum` must be `2.1.285` or later). See [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
{% endtable %}

## Build the managed settings

Run `fleet build` for each target group. You can build for any platform from one computer by setting `--platform`.

Before running the command, replace the placeholders and keep the quotes:

* `POLICY_FILE`: Path to your copy of `managed-settings.json` (file build) or your MDM policy file (MDM build). Replace `--policy 'POLICY_FILE'` with `--no-policy` if the group doesn't have an existing policy file.
* `MCP_MODE`: `exclusive`, `allowlist`, or `any`. Add `--mcp-config 'MCP_CONFIG_FILE'` with `exclusive` if merging an existing `managed-mcp.json`, or `--mcp-url` / `--mcp-command` with `allowlist`.
* `GROUP`: A short name without spaces for the computer group. Each `--output-dir` must be a new or empty folder.
* `--executable`: The exact absolute path where the system-wide kong-harnesses package installs the binary on managed computers (`kong-harnesses` on macOS/Linux, `kong-harnesses.exe` with a drive letter and backslashes on Windows).

### File build

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
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
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' `
  --policy 'POLICY_FILE' `
  --mcp-servers MCP_MODE `
  --output-dir fleet-windows-GROUP
```

{% endnavtab %}
{% endnavtabs %}

### MDM build

{% navtabs "fleet-build-mdm" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --delivery mdm \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --mcp-servers MCP_MODE \
  --output-dir fleet-macos-mdm-GROUP
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build `
  --profile work `
  --platform windows `
  --delivery mdm `
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' `
  --policy 'POLICY_FILE' `
  --mcp-servers MCP_MODE `
  --output-dir fleet-windows-mdm-GROUP
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build files into the output folder and prints a summary showing the settings, any modified keys from your `--policy`, the build ID, the record file path, and the platform install command.

## Check the build output

Verify the generated output folder before deploying. `fleet build` writes the files to install on each computer under `root/` at their target paths:

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
> **Keep a backup of the build record:** `kong-harnesses-fleet-BUILD_ID.json` stores your build choices, original `--policy`, and gateway MCP definitions. Keep it with your policy: you need it to update the build with `--record` or remove it with `fleet remove`.

Confirm that the managed settings match your expectations:

* **Credential helper:** Runs `kong-harnesses credential --profile work` from `--executable` (through WSL interop with `--wsl inherit`) without storing developer credentials.
* **Gateway lock:** Sets `allowedProviders` to `["customEndpoint"]` (enforced by {{ site.claude_code }} 2.1.285 and later) and clears competing provider, credential, and custom-header overrides in `env`, preserving only profile attribution headers and headers from `--policy`.
* **Models and pricing:** Configures default Claude family models and gateway `/cost` pricing when available. With the Anthropic API provider, {{ site.claude_code }} also discovers new Claude or Anthropic models from the gateway on restart unless restricted by `availableModels` or `modelPicker.replaceBuiltInOptions`. If `fleet build` reports changing `modelPicker`, review it before deploying.
* **Disabled features and hooks:** Disables {{ site.claude_code }} features that bypass the gateway (run `kong-harnesses profile get work` to inspect them) and adds hooks that report blocked user, local, or project MCP servers and non-WebSearch models.
* **Build ID:** Sets `env.KONG_HARNESSES_FLEET_BUILD` so `kong-harnesses doctor` and support reports identify the installed build.

On managed computers, kong-harnesses reads the machine-wide profile ahead of any user profile of the same name and refuses the file unless only administrators can modify it and its parent folders (`root`-owned without group or world write on macOS and Linux; owned and writable only by Administrators, SYSTEM, or TrustedInstaller up to `C:\Program Files` without links on Windows).

## Deploy to managed computers

Deploy to **one test computer for each platform and policy group** first. Roll out to the rest of the group only after [Validate](#validate) passes.

Install the following components on each target computer through your MDM tool:

1. **{{ site.claude_code }}:** Install a supported version that enforces `allowedProviders` (2.1.285 or later). See [Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup) and [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/). Because the native installer writes to the running user's home folder (`~/.local/bin/claude` or `%USERPROFILE%\.local\bin\claude.exe`), run it in each developer's user context rather than as root or SYSTEM, or use the Linux `apt`, `dnf`, or `apk` repositories.
1. **kong-harnesses:** Install the system-wide package at the exact `--executable` path. See [Install kong-harnesses for every user of a computer](/kong-harnesses/install/). Don't install kong-harnesses with Homebrew on managed Macs, because Homebrew shares `/usr/local/bin` on Intel Macs.
1. **Private gateway CA (if used):** Add your gateway's CA certificate to the OS system trust store (and to each WSL distribution if using `--wsl inherit`). `fleet build` doesn't install CA certificates.
1. **Build files under `root/`:** Install the files with administrator privileges using the following platform steps.
1. **MDM policy (MDM builds only):** On macOS, upload `mdm/com.anthropic.claudecode.plist` as a Custom Settings payload for `com.anthropic.claudecode` in place of any existing policy. On Windows, set the `REG_SZ` value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode` to the single line in `mdm/Settings.json` in place of any existing value. If migrating from a file build, unassign the old file-build deployment and delete `managed-settings.d/kong-harnesses.json` so {{ site.claude_code }} doesn't still read its `env` or MCP lock.

### Package or copy the build files

{% navtabs "deploy-fleet-files" %}
{% navtab "macOS" %}

1. Copy the entire output folder to a Mac using a tool that preserves permissions, such as `ditto` or `rsync -a`.
1. Open a terminal in the copied output folder and run the `pkgbuild` command that `fleet build` printed, replacing `PACKAGE_IDENTIFIER` and `PACKAGE_VERSION`:

   ```sh
   find root scripts -type d -exec chmod 755 {} + && find root -type f -exec chmod 644 {} + && chmod 755 scripts/preinstall && pkgbuild --root root --scripts scripts --install-location / --identifier PACKAGE_IDENTIFIER --version PACKAGE_VERSION kong-harnesses-fleet.pkg
   ```

   `pkgbuild` creates an unsigned component package (`kong-harnesses-fleet.pkg`) with `root` ownership, 755/644 permissions, and the preinstall safety check script.
1. If your MDM path requires a signed distribution package, for example [Apple MDM](https://support.apple.com/guide/deployment/distribute-packages-to-mac-computers-dep873c25ac4/web) or a Jamf Pro [PreStage enrollment package](https://learn.jamf.com/r/en-US/jamf-pro-documentation-current/Computer_PreStage_Enrollment_Payload_Reference), wrap and sign it with your Keychain installer certificate:

   ```sh
   productbuild --sign 'INSTALLER_IDENTITY' --package kong-harnesses-fleet.pkg kong-harnesses-fleet-signed.pkg
   ```

1. Deploy the signed package (or unsigned `kong-harnesses-fleet.pkg` where supported) through your MDM tool. For Microsoft Intune, add it as a [macOS app (PKG)](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos) rather than a line-of-business app, because this package doesn't install a `.app` bundle under `/Applications` (Intune may not report install detection).

{% endnavtab %}
{% navtab "Linux" %}

1. Confirm the `acl` package (which provides `getfacl`) is installed on each managed computer.
1. Copy the `root/` folder from the output folder to the target computer.
1. From inside the copied `root/` folder, run the `sudo sh -c` copy command that `fleet build` printed.

The command checks target ownership, permissions, links, and ACLs, copies the files under `/`, and sets `root:root` ownership with mode 755 on folders and 644 on files.

{% endnavtab %}
{% navtab "Windows" %}

1. Copy the `root/` folder from the output folder to the target computer.
1. Open Windows PowerShell as an administrator inside the copied `root/` folder and run the PowerShell copy command that `fleet build` printed.

The command checks target ownership, ACLs, links, and hard links, copies the files under `C:\`, and sets Administrators ownership with ACLs inherited from `C:\Program Files`.

{% endnavtab %}
{% endnavtabs %}

{:.info}
> **Preinstall safety checks:** Before writing any file, the macOS preinstall script and Linux/Windows copy commands inspect existing target files and parent folders. If installation stops with `Not installed:` (for example, because of a symlink, extra hard link, unexpected owner, writable permissions or ACLs, or missing `getfacl` on Linux), fix the reported condition on the named path and run the install again. Remove an unexpected file or link only at a build file's exact path; never remove system folders such as `/etc`, `/Library`, or `C:\Program Files`.

## Validate

Sign in to each test computer as a standard developer account and verify the setup **before sending a prompt**.

1. If you built with `--mcp-servers allowlist` or `any` and the profile defines gateway MCP servers, activate the gateway MCP plugin as the developer with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

   ```sh
   kong-harnesses profile activate work --client claude-code
   ```

   kong-harnesses installs the gateway MCP plugin in `~/.claude/skills` (`%USERPROFILE%\.claude\skills` on Windows, or `skills` inside `CLAUDE_CONFIG_DIR`). If this fails because the developer's `settings.json` sets `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, remove those variables from `env` and run the command again.
1. Check the setup with [`kong-harnesses doctor`](/kong-harnesses/doctor/):

   ```sh
   kong-harnesses doctor --profile work --client claude-code
   ```

   `doctor` reports that your organization's managed settings configure {{ site.claude_code }} and prints the fleet build ID. Confirm the build ID matches what `fleet build` printed. If the test account doesn't have a saved sign-in yet, `doctor` notes that the first request will open the browser, which is expected. Fix any reported errors before continuing.
1. Start {{ site.claude_code }} and sign in:

   ```sh
   claude
   ```

   Without a saved sign-in, kong-harnesses opens the browser on startup (for Anthropic API model discovery) or on the first request. Sign in with the developer's identity provider account. For gateway MCP servers that use a fixed key, also run `kong-harnesses login --profile work` once to save each key; for servers with their own OAuth sign-in, sign in from `/mcp`.
1. Run `/status` inside {{ site.claude_code }} before sending a prompt and inspect the `Setting sources` line. Expect `Enterprise managed settings` with `(drop-ins)` or `(file + drop-ins)` for a file build, or `(plist)` (macOS), `(HKLM)` (Windows), or a `, merged` list starting with `plist` or `HKLM` for an MDM build. Together with the build ID from `kong-harnesses doctor`, this confirms that {{ site.claude_code }} applies your fleet build.
1. Send a short prompt such as `Say hello` and confirm you receive a reply without errors. Open the {{ site.ai_cost_management }} [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) and verify the usage event appears under your profile's gateway control plane (with the setup guide's OIDC strategy, filter by **User** `oidc/SUB`, where `SUB` is the test user's `sub` claim, or configure [subject attribution](/ai-cost-management/attribution/#set-up-subject-attribution)).
1. If your profile defines gateway MCP servers, run `/mcp` inside {{ site.claude_code }} and confirm every server shows as connected. If a gateway-authenticated server failed during initial browser sign-in, reconnect it from `/mcp`. If a key server doesn't have a saved key, run `kong-harnesses login --profile work`; to replace a rejected key, run `kong-harnesses logout --profile work` and then `kong-harnesses login --profile work`. If a server is missing, check `kong-harnesses doctor` output, `deniedMcpServers` across all settings scopes, and startup flags such as `--strict-mcp-config`.

### Troubleshoot status labels

If `/status` shows an unexpected `Setting sources` label, check the `Skipped sources` line, run `claude doctor` to list any invalid managed settings fields that {{ site.claude_code }} dropped, and use the following table to resolve it:

{% table %}
columns:
  - title: Observed label
    key: label
  - title: Cause and fix
    key: fix
rows:
  - label: "Missing `Enterprise managed settings`, `(file)`, or `(HKCU)`"
    fix: Build files or MDM policy didn't reach the computer, or the policy holds only control keys. Verify the files at their target paths and redeploy.
  - label: "`(plist)` or `(HKLM)` on a file build"
    fix: An MDM policy outranks `managed-settings.d/` (even when merged, `apiKeyHelper` comes from the MDM policy). Rebuild with `--delivery mdm --policy`.
  - label: "`(remote)` or merged list starting with `remote`"
    fix: Server-managed settings outrank the build. Remove any organization claude.ai login from the computer (cached remote settings can persist for up to 24 hours).
  - label: "`(helper)`"
    fix: "`policyHelper` or `policyHelpers` is overriding managed settings. Remove it from your policy."
  - label: "`(parent process)`"
    fix: Only host-app settings loaded. Start `claude` from a terminal to confirm, then redeploy the build.
{% endtable %}

### Check host apps and WSL

* **Host apps (`--host-settings merge`):** Run `/status`, `/mcp`, and a test prompt from each supported host app, for example the VS Code extension, because terminal sessions and `doctor` don't see host-passed settings.
* **WSL (`--wsl inherit`):** In each WSL distribution, start `claude`, verify `/status` shows `Enterprise managed settings`, and send a test prompt (`doctor` and gateway MCP servers don't run in WSL). If you hit a TLS error, confirm the private CA is trusted inside WSL and inspect `claude --debug` logs under `~/.claude/debug/`.

After validation passes on each test computer, roll out the deployment to the rest of that group. To pin {{ site.claude_code }} versions or move your fleet to a new model later, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
