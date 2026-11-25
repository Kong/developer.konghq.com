---
title: "Roll out a {{ site.claude_code }} fleet build with kong-harnesses"
description: Build {{ site.claude_code }} managed settings from a kong-harnesses profile, deploy them to managed computers, validate a test computer, and diagnose a failed rollout.
permalink: /kong-harnesses/roll-out-claude-code-through-mdm/

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
  - ai
  - anthropic

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: Plan a {{ site.claude_code }} fleet build with kong-harnesses
    url: /kong-harnesses/fleet-build-options/
  # TODO: restore when the maintain page is published
  # - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
  #   url: /kong-harnesses/maintain-a-claude-code-fleet/
  - text: Remove a {{ site.claude_code }} fleet build with kong-harnesses
    url: /kong-harnesses/remove-a-claude-code-fleet-build/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: "{{ site.claude_code }} managed settings"
    url: https://code.claude.com/docs/en/managed-settings
---

`kong-harnesses fleet build` locks managed macOS, Linux, and Windows computers to {{ site.ai_gateway }}.
It writes a machine-wide kong-harnesses profile and [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings).
Developers don't import a profile.
Each developer signs in through the browser on first use, and kong-harnesses renews the token automatically.

{{ site.claude_code }} needs the {{ site.ai_gateway }} address and the credential helper before its first request, so both must come from managed settings that are already on the computer.
An MDM tool or configuration management puts them there, and developers can't override them.

{:.info}
> The following steps are a guideline.
> The exact execution varies with your MDM tool, your configuration management, and your existing policy.

## Before you start

Install kong-harnesses on a build computer, and check the requirements for your platforms:

{% table %}
columns:
  - title: Operating system
    key: os
  - title: Build computer requirement
    key: requirement
  - title: Deployment tool
    key: tool
rows:
  - os: macOS
    requirement: None
    tool: An MDM tool, such as Jamf Pro or Microsoft Intune
  - os: Linux
    requirement: |
      A Linux desktop session with Secret Service, such as GNOME Keyring or KWallet.
      Run the build outside WSL, containers, and SSH sessions.
    tool: Configuration management
  - os: Windows
    requirement: Windows 11
    tool: An MDM tool, such as Microsoft Intune
{% endtable %}

Create and install an OIDC profile with an HTTPS gateway URL, as described in [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).
This page uses the profile name `work`.
Replace `work` with your profile name in each command.
`fleet build` refuses `http://` origins, Claude subscription profiles, and a gateway on the host of a Claude provider, such as an Amazon Bedrock runtime host.
If the profile uses the Anthropic API provider, the build computer must reach the gateway and trust any private gateway CA.

You also need:

* Administrator access to one test computer for each platform and policy group.
* Access to the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger), with the [required role](/ai-cost-management/analytics-and-debugging/#how-the-views-relate).
* {{ site.claude_code }} `2.1.285` or later on the target computers.
  Earlier versions don't enforce `allowedProviders`.

## Sign in to the profile

If the profile uses the Anthropic API provider, `fleet build` uses your sign-in to read the gateway's model list.
Sign in with [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

kong-harnesses opens your browser to sign in.

Other Claude providers, such as Amazon Bedrock, take models from the profile or from `--model`, so they don't need this step.

## Plan the build

Each build is for one group of computers.
The computers in a group share the platform, the delivery method, the policy, and, for the `exclusive` MCP mode, the `managed-mcp.json` file.
Deploy each build only to its group.

Make these choices before you build, as described in [Plan a {{ site.claude_code }} fleet build](/kong-harnesses/fleet-build-options/):

* [The delivery method](/kong-harnesses/fleet-build-options/#choose-the-delivery-method), and the policy sources to clear first
* [The MCP server mode](/kong-harnesses/fleet-build-options/#choose-an-mcp-server-mode)
* [Host settings and WSL](/kong-harnesses/fleet-build-options/#choose-host-settings-and-wsl)
* [Version bounds](/kong-harnesses/fleet-build-options/#set-version-bounds) and [model overrides](/kong-harnesses/fleet-build-options/#override-models)

Remove all secrets from the `--policy` and `--mcp-config` files before you build.
Every account on a computer can read managed settings and `managed-mcp.json`.

## Build the managed settings

Run `kong-harnesses fleet build` once for each group.
With `--platform`, you can build for every operating system from one computer.

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

Replace `DELIVERY` with `file` or `mdm`.

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

Linux supports only `file` delivery, which is the default.

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

Replace `DELIVERY` with `file` or `mdm`.

By default, {{ site.claude_code }} in Windows Subsystem for Linux (WSL) reads only its own managed settings.
To make it read the Windows managed settings of this build, add `--wsl inherit`.

```powershell
kong-harnesses fleet build --profile work --platform windows --delivery DELIVERY --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-windows-GROUP
```

{% endnavtab %}
{% endnavtabs %}

Replace these placeholders in the command for your platform:

* `POLICY_FILE`: The file that holds the current policy.
  If there isn't a policy, replace `--policy 'POLICY_FILE'` with `--no-policy`.
* `MCP_MODE`: `exclusive`, `allowlist`, or `any`.
  Also add the flags that the mode needs.
* `GROUP`: A name for the group, without spaces, because the command doesn't quote `--output-dir`.

Keep the quotes in the command.
For the quotes that each shell needs, see [Allowlist values and quoting](/kong-harnesses/fleet-build-options/#allowlist-values-and-quoting).

`fleet build` writes the build files to `--output-dir`, and prints each file and its target path, the policy changes, the build ID and record path, the install command, and the helper, model, MCP, and version choices. 
The `--output-dir` folder must be new or empty.

## Check the build output

`fleet build` puts the files to install under `root/`, at their target paths.
It puts the other files outside `root/`:

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
  - title: "Outside `root/`"
    key: other
rows:
  - platform: macOS
    settings: "`/Library/Application Support/ClaudeCode/managed-settings.d/kong-harnesses.json`"
    profile: "`/Library/Application Support/kong-harnesses/profiles/work.json`"
    servers: "`/Library/Application Support/ClaudeCode/managed-mcp.json`"
    other: "`scripts/preinstall`, and `mdm/com.anthropic.claudecode.plist` for an MDM build"
  - platform: Linux
    settings: "`/etc/claude-code/managed-settings.d/kong-harnesses.json`"
    profile: "`/etc/kong-harnesses/profiles/work.json`"
    servers: "`/etc/claude-code/managed-mcp.json`"
    other: None
  - platform: Windows
    settings: "`C:\\Program Files\\ClaudeCode\\managed-settings.d\\kong-harnesses.json`"
    profile: "`C:\\Program Files\\kong-harnesses\\profiles\\work.json`"
    servers: "`C:\\Program Files\\ClaudeCode\\managed-mcp.json`"
    other: "`mdm/Settings.json` for an MDM build"
{% endtable %}

`--output-dir` also holds the build record, `kong-harnesses-fleet-BUILD_ID.json`.
Keep the build record with your policy.
You need it to update the build with `--record` and to remove the build with `fleet remove`.

Before you deploy, check the output:

* **Policy changes:** Review the changed keys.
  If `modelPicker` changed, inspect it.
  When a model isn't discovered automatically, the build replaces the whole `modelPicker`, including `replaceBuiltInOptions`.
* **Credential helper:** Confirm that the helper runs `kong-harnesses credential --profile work` from the `--executable` path.
* **Hooks:** Confirm that the hooks report blocked MCP servers and skipped web searches.
  Models without WebSearch skip web searches.
* **Build ID:** Save the build ID, which is the value of `env.KONG_HARNESSES_FLEET_BUILD`.
  You compare it with the output of `kong-harnesses doctor` in [Validate](#validate).

kong-harnesses uses the machine-wide profile instead of a user profile with the same name.
It refuses the machine-wide profile unless only administrators can change the file and its parent folders.

## Deploy to managed computers

Deploy to one test computer for each platform and policy group first.
Roll out to the rest of the group only after the checks in [Validate](#validate) pass.

`fleet build` doesn't install CAs, {{ site.claude_code }}, or kong-harnesses.
On every platform, install these first, in this order:

1. Install {{ site.claude_code }} `2.1.285` or later.
   For the installer, see [Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup).
   Run the native installer as each developer, not as `root` or SYSTEM, so that it installs into the developer's home folder.
1. Install kong-harnesses system-wide, at the `--executable` path.
1. If you use a private gateway CA, add it to the system trust store.
   Also add it to each WSL distribution with `--wsl inherit`.

Then install the build files with the steps for your platform.
Every install command checks the target paths before it writes.
If a command prints `Not installed:` or `could not be written in full`, fix the cause that the message names, then run the command again.
The cause is a symlink, a junction, an extra hard link, an unexpected owner, write permissions or ACLs that are too open, or a missing `getfacl` on Linux.
Delete an unexpected file or link only at the exact path of a build file.
Never delete a system folder, such as `/Library`, `/etc`, or `C:\Program Files`.

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

Don't install kong-harnesses with Homebrew on managed Macs, because Homebrew shares `/usr/local/bin` on Intel Macs.

1. Copy the `--output-dir` folder to a Mac, and keep the file permissions.
   For example, use `ditto` or `rsync -a`.
1. In that folder, run the `pkgbuild` command that `fleet build` printed.
   Replace these placeholders:
   * `PACKAGE_IDENTIFIER`: A reverse DNS name for the package, such as `com.example.kong-harnesses-fleet`.
     Use the same identifier for every build of this group.
   * `PACKAGE_VERSION`: A new version for each build, such as `1.0.0`.

   The command sets `root` ownership, 755 and 644 modes, and the `scripts/preinstall` script, and builds `kong-harnesses-fleet.pkg`:

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

1. If your MDM requires a signed distribution package, sign the package with the installer certificate in your keychain.
   For example, [Apple MDM](https://support.apple.com/guide/deployment/distribute-packages-to-mac-computers-dep873c25ac4/web) and Jamf Pro [PreStage enrollment](https://learn.jamf.com/r/en-US/jamf-pro-documentation-current/Computer_PreStage_Enrollment_Payload_Reference) require one.
   Replace `INSTALLER_IDENTITY` with the name of your Developer ID Installer certificate, such as `Developer ID Installer: Your Company (TEAM_ID)`:

   ```sh
   productbuild --sign 'INSTALLER_IDENTITY' \
     --package kong-harnesses-fleet.pkg \
     kong-harnesses-fleet-signed.pkg
   ```

1. Deploy the package through MDM.
   In Microsoft Intune, add it as a [macOS app (PKG)](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos), not as a line-of-business app.
   Intune may not detect a line-of-business app that doesn't have an `.app` bundle in `/Applications`.

   `root` must own the machine-wide profile and its parent folders.
   The group and other users must not have write permission.
1. For an MDM build, upload `mdm/com.anthropic.claudecode.plist` as Custom Settings for `com.anthropic.claudecode`.
   It replaces the existing policy.

{% endnavtab %}
{% navtab "Linux" %}

1. Confirm that each managed computer has the `acl` package, which provides `getfacl`.
1. Copy `root/` to the target computer.
1. Inside `root/`, run the `sudo sh -c` command that `fleet build` printed.

   The command checks ownership, permissions, links, and ACLs.
   Then it copies the files under `/` and sets `root:root` ownership, 755 for folders, and 644 for files.
   `root` must own the machine-wide profile and its parent folders.
   The group and other users must not have write permission.

{% endnavtab %}
{% navtab "Windows" %}

1. Confirm that only `Administrators`, `SYSTEM`, `TrustedInstaller`, or `CREATOR OWNER` can modify files in `C:\Program Files`.
   Existing folders, such as `C:\Program Files\ClaudeCode`, can lose their explicit ACLs during the install.
1. Copy `root/` to the target computer.
1. Inside `root/`, run the printed command from an elevated Windows PowerShell.

   The command checks the target paths for unexpected owners, writable ACLs, symlinks, junctions, and extra hard links.
   Then it copies the files under `C:\` and sets `Administrators` as the owner.
   It also runs `icacls /reset` on each path that it writes, including existing folders, so that they inherit the `C:\Program Files` ACLs.

   Only `Administrators`, `SYSTEM`, or `TrustedInstaller` may own and write the machine-wide profile and its folders, up to `C:\Program Files`.
   The path must not have symlinks or junctions.
1. For an MDM build, set the `REG_SZ` value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode` to the single-line JSON in `mdm/Settings.json`.
   It replaces the existing value.

{% endnavtab %}
{% endnavtabs %}

### Move from a file build to an MDM build

If the computers already have a file build, do these steps in order:

1. Unassign the old package or script before you change the policy.
   For an Intune macOS app (PKG), remove its **Required** and **Available** assignments.
1. Apply the MDM policy, as described in the steps for your platform.
1. Wait until `/status` on the computer shows the MDM build label from [Validate](#validate).
1. Delete the old drop-in, so that {{ site.claude_code }} stops reading its `env` and MCP lock:
   * macOS: `/Library/Application Support/ClaudeCode/managed-settings.d/kong-harnesses.json`
   * Windows: `C:\Program Files\ClaudeCode\managed-settings.d\kong-harnesses.json`

## Validate

Sign in to each test computer as a standard developer who doesn't have a saved kong-harnesses sign-in.
Do these checks before you send a prompt:

1. If you built with `--mcp-servers allowlist` or `any` and the profile has gateway MCP servers, run [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

   ```sh
   kong-harnesses profile activate work --client claude-code
   ```

   If activation fails because the user `settings.json` sets `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, remove them from `env` and run the command again.
1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/):

   ```sh
   kong-harnesses doctor --profile work --client claude-code
   ```

   Confirm that `doctor` reports that your organization's managed settings configure {{ site.claude_code }}, and that it prints the build ID.
   Without a saved sign-in, a note about the browser sign-in is expected.
   Fix any errors before you continue.
1. Start {{ site.claude_code }} with `claude`.
   Sign in when the browser opens.
   It can open at startup, for example for Anthropic API model discovery, or on the first request.

Check the settings source on each test computer:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

Run `/status`.
Confirm that `Setting sources` shows `Enterprise managed settings` with the label of your build:

* File build: `(drop-ins)` or `(file + drop-ins)`
* MDM build: `(plist)`, or a `, merged` list that starts with `plist`

{% endnavtab %}
{% navtab "Linux" %}

Run `/status`.
Confirm that `Setting sources` shows `Enterprise managed settings` with `(drop-ins)` or `(file + drop-ins)`.
Linux supports only file builds.

{% endnavtab %}
{% navtab "Windows" %}

1. Run `/status`.
   Confirm that `Setting sources` shows `Enterprise managed settings` with the label of your build:

   * File build: `(drop-ins)` or `(file + drop-ins)`
   * MDM build: `(HKLM)`, or a `, merged` list that starts with `HKLM`
1. Confirm that WSL inheritance matches your `--wsl` choice.
   For the checks, see [WSL on Windows](#wsl-on-windows).

{% endnavtab %}
{% endnavtabs %}

Then finish the checks on every platform:

1. Send `Say hello` and confirm that {{ site.claude_code }} replies.
1. Find the event under your control plane in the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger).
   Set the **User** filter to the subject of the test user.
   The [AI Auth Strategy](/ai-cost-management/attribution/#set-up-subject-attribution) sets the subject:
   * A principal: `principal/UUID`
   * An AI Consumer: `consumer/UUID`
   * An OpenID Connect claim without a principal: `oidc/CLAIM_VALUE`, where `CLAIM_VALUE` is the value of the claim that `credential_claim` names, `sub` by default
1. Confirm that no policy sets `disableAllHooks` to `true`.
   The test prompt doesn't check the hooks.
1. If the profile has gateway MCP servers, run `/mcp` and confirm that every server connects.
1. If `--host-settings merge` or `parentSettingsBehavior: "merge"` is active, test each supported embedding host app before the full rollout.
   Claude Desktop isn't a supported host app.
   For the checks, see [Host apps](#host-apps).

If a check fails, see [Troubleshoot a failed rollout](#troubleshoot-a-failed-rollout).

After every test computer passes, roll out to the group.

## Troubleshoot a failed rollout

A computer with a fleet build can fail validation for these reasons:

* Another managed settings source outranks the build.
* An MCP policy blocks the gateway servers.
* A host app or a WSL distribution reads different settings.

In each command, replace `PROFILE_NAME` with your profile name.

### Status labels

When `/status` shows an unexpected `Setting sources` label, check the `Skipped sources` line.
Then run `claude doctor` to list the [invalid managed settings fields that {{ site.claude_code }} dropped](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped).
For all source labels, see [How {{ site.claude_code }} combines managed sources](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources).
This table lists the fixes for fleet builds:

{% table %}
columns:
  - title: Observed label
    key: label
  - title: Cause and fix
    key: fix
rows:
  - label: "No `Enterprise managed settings` label, or only `(file)` or `(HKCU)`"
    fix: |
      The build files or the MDM policy didn't reach the computer, or the policy sets nothing besides `managedSourcesBehavior` and `wslInheritsWindowsSettings`.
      Check the files at their [target paths](#check-the-build-output), and deploy again.
  - label: "`(drop-ins)` or `(file + drop-ins)` on an MDM build"
    fix: |
      The MDM policy didn't reach the computer, or it sets nothing besides `managedSourcesBehavior`, `wslInheritsWindowsSettings`, or empty objects.
      Check `Skipped sources` and the deployed MDM policy, and deploy again.
  - label: "`(plist)`, `(HKLM)`, or a merged list starting with `plist` or `HKLM` on a file build"
    fix: |
      An MDM policy on the computer outranks the file build.
      Build again with `--delivery mdm`, and pass the current MDM policy with `--policy 'POLICY_FILE'`.
      For details, see [Choose the delivery method](/kong-harnesses/fleet-build-options/#choose-the-delivery-method).
  - label: "`(remote)` or a merged list starting with `remote`"
    fix: |
      Server-managed settings outrank the build.
      Cached remote settings can stay for up to 24 hours.
      Remove the conflicting credentials, and follow the remote settings rules in [Check your existing policy](/kong-harnesses/fleet-build-options/#check-your-existing-policy).
  - label: "`(helper)`"
    fix: |
      A `policyHelper` or `policyHelpers` key in the MDM policy, `managed-settings.json`, or `managed-settings.d/` overrides the managed settings.
      Remove the key from all managed sources.
  - label: "`(parent process)`"
    fix: |
      Only the settings of a host app loaded.
      To confirm, start `claude` from a terminal.
      Then deploy the build again.
{% endtable %}

### Gateway MCP connections

When a gateway MCP server doesn't connect or doesn't show in `/mcp`, use this table to find the cause and the fix:

{% table %}
columns:
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:
  - cause: Key server without a saved key
    fix: Run `kong-harnesses login --profile PROFILE_NAME` once to save each key.
  - cause: Rejected key on a key server
    fix: |
      Have all server keys ready.
      Then run `kong-harnesses logout --profile PROFILE_NAME` and `kong-harnesses login --profile PROFILE_NAME`.
      When a saved sign-in exists, `logout` asks you to type the profile name.
      It signs out of the profile and removes the saved sign-in and every saved gateway MCP key of the profile.
  - cause: Server with its own OAuth sign-in
    fix: Sign in from `/mcp`.
  - cause: "Server turned off in {{ site.claude_code }}"
    fix: |
      `/mcp disable` and `disabledMcpjsonServers` can turn off a gateway MCP server.
      `kong-harnesses doctor` then fails and names the setting that turned the server off.
      Run `/mcp enable` with the server name in {{ site.claude_code }}, or remove the entry that `doctor` names from `disabledMcpjsonServers`.
  - cause: Gateway-authenticated server failed at startup
    fix: |
      A server can [fail during the first browser sign-in](https://code.claude.com/docs/en/mcp#failed-first-connections).
      After you sign in, reconnect it from `/mcp`.
  - cause: Missing servers
    fix: |
      To find invalid entries that {{ site.claude_code }} dropped, run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` and `claude doctor`.
      Remove `--strict-mcp-config` from startup commands.
      Check `allowedMcpServers` and `deniedMcpServers` in every settings scope: user, project, and local settings, `--settings`, and every administrator source, including remote server-managed settings.
      `kong-harnesses doctor` reads the local administrator sources, but not remote server-managed settings.

      For `--mcp-servers allowlist` or `any`, `profile activate` installs the gateway MCP plugin in `.claude/skills` in the developer's home folder, or in `skills` in the folder that `CLAUDE_CONFIG_DIR` names.
      `doctor` also fails when a setting turns off that plugin:

      * If `enabledPlugins` in a settings file sets the gateway plugin to `false`, remove that entry.
      * If the `plugin.json` manifest of the plugin turns it off, follow the fix that `doctor` prints.
        On a computer with a fleet build, the fix is to run `fleet build` again and deploy the new build.

      For the settings that block the plugin, see [Before you build](/kong-harnesses/fleet-build-options/#before-you-build).
{% endtable %}

### Host apps

Run this check when you build with `--host-settings merge` or when a managed source sets `parentSettingsBehavior` to `merge`.
Start a session from each supported host app, such as the {{ site.claude_code }} extension for VS Code.
Run `/status`, `/mcp`, and a test prompt.
Terminal sessions and `kong-harnesses doctor` don't read the settings that a host app passes.
Don't test Claude Desktop, because it isn't a supported host app.
For details, see [Host settings](/kong-harnesses/fleet-build-options/#host-settings).

### WSL on Windows

Check WSL on each Windows test computer:

* **With `--wsl inherit`:** In each WSL distribution, start `claude` and run `/status` before you send a prompt.
  Confirm that `Setting sources` shows `Enterprise managed settings` with the label for the delivery of the Windows build:
  * File build: `(drop-ins)` or `(file + drop-ins)`
  * MDM build: `(HKLM)`, or a merged list that starts with `HKLM`

  While WSL inherits the Windows settings, it reads a WSL-local policy under `/etc/claude-code` only when [no Windows administrator document is present](https://code.claude.com/docs/en/managed-settings#present-admin-documents).
  A WSL-local policy can show the same labels as a Windows file build, or `Enterprise managed settings` without a delivery label.
  So for a file build, also confirm that the Windows build files are at their [target paths](#check-the-build-output).
  Send a short test prompt, and confirm that the WSL usage event shows in the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger).
  `doctor` and gateway MCP servers don't run in WSL.
  If you get a TLS error, confirm that the private CA is trusted in WSL, and read the [`claude --debug`](https://code.claude.com/docs/en/network-config#verify-your-configuration) logs in `~/.claude/debug/`.
  If the credential helper exits with status `126`, turn on Windows interop in that WSL distribution.
* **Without `--wsl inherit`:** If WSL inherits the Windows settings, confirm that the Windows administrator sources leave out `wslInheritsWindowsSettings` or set it to a value that turns it off.
  For the values, see [WSL on Windows](/kong-harnesses/fleet-build-options/#wsl-on-windows).
