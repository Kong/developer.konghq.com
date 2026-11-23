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
  - text: "{{ site.claude_code }} fleet build options"
    url: /kong-harnesses/fleet-build-options/
  - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
    url: /kong-harnesses/maintain-a-claude-code-fleet/
  - text: Remove a {{ site.claude_code }} fleet build
    url: /kong-harnesses/remove-a-claude-code-fleet-build/
  - text: Troubleshoot a {{ site.claude_code }} fleet
    url: /kong-harnesses/troubleshooting/claude-code-fleet/
  - text: Install kong-harnesses for every user of a computer
    url: /kong-harnesses/install/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: "{{ site.claude_code }} managed settings"
    url: https://code.claude.com/docs/en/managed-settings

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: kong-harnesses and a profile
      content: |
        Install [kong-harnesses](/kong-harnesses/install/) on a build computer.
        Use the **Build computer requirement** column for the operating system of the build computer.
        Use the **Deployment tool** column for the operating system of the managed computers:

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
        This guide uses the profile name `work`.
        Replace `work` with your profile name in each command.

        `fleet build` refuses `http://` origins and Claude subscription profiles.
        If the profile uses the Anthropic API provider, the build computer must reach the gateway and trust any private gateway CA.
    - title: "{{ site.claude_code }} and test access"
      content: |
        You need:

        * Administrator access to one test computer for each platform and policy group.
        * Access to the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger), with the [required role](/ai-cost-management/analytics-and-debugging/#how-the-views-relate).
        * {{ site.claude_code }} `2.1.285` or later on the target computers.
          Earlier versions don't enforce `allowedProviders`.
          For details, see [Version range checks](/kong-harnesses/fleet-build-options/#version-range-checks).

tldr:
  q: How do I roll out {{ site.claude_code }} to managed computers with kong-harnesses?
  a: |
    If the profile uses the Anthropic API provider, sign in to it first.
    Run `kong-harnesses fleet build` once for each platform and policy group.
    Deploy {{ site.claude_code }}, kong-harnesses, any private CA, and the build files to one test computer.
    Validate the test computer, then roll out to the group.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        To remove the build, first have each developer sign out of the machine-wide profile and remove any user-level activation.
        Then unassign the deployment and run `kong-harnesses fleet remove`.
        Follow its output for the MDM policy and `managed-mcp.json`, and delete the files listed under `Remove`.
        For the steps, see [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/).

faqs:
  - q: Why does a fleet get its {{ site.claude_code }} settings through MDM instead of {{ site.ai_gateway }}?
    a: |
      {{ site.claude_code }} needs the {{ site.ai_gateway }} address and the credential helper before its first request.
      They must come from managed settings that are already on the computer.
      Anthropic's [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability) load only over a direct `api.anthropic.com` connection with an eligible credential, and a fleet helper key isn't an eligible credential.
      MDM puts the policy on the computer before first use, and developers can't override it.
---

`kong-harnesses fleet build` locks managed macOS, Linux, and Windows computers to {{ site.ai_gateway }}.
It writes a machine-wide kong-harnesses profile and [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings).
Developers don't import a profile.
Each developer signs in through the browser on first use, and kong-harnesses renews the token automatically.

## Sign in to the profile

If the profile uses the Anthropic API provider, `fleet build` uses your sign-in to read the gateway's model list.
Other Claude providers, such as Amazon Bedrock, take models from the profile or from `--model`.
For those providers, skip to [Review the existing policy](#review-the-existing-policy).

For the Anthropic API provider, sign in with [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

kong-harnesses opens your browser to sign in.

## Review the existing policy

Each build is for one group of computers.
The computers in a group share the platform, the delivery method, the policy, and, for the `exclusive` MCP mode, the `managed-mcp.json` file.
Deploy each build only to its group.

{:.warning}
> **Keep secrets out of managed files:** Every account on a computer can read managed settings and `managed-mcp.json`.
> Remove secrets from the `--policy` and `--mcp-config` files before you build.
> For details, see [fleet build options](/kong-harnesses/fleet-build-options/).

Before you build, make these choices:

* [Delivery method and existing policy](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy): Choose `file` or `mdm` delivery, and export the current MDM policy or `managed-settings.json`.
  Clear conflicts from other policy sources, drop-ins, custom headers, and remote settings.
* [MCP server modes and exceptions](/kong-harnesses/fleet-build-options/#mcp-server-modes-and-exceptions): Choose an `--mcp-servers` mode, and prepare `managed-mcp.json` or the allowlist entries.
  Check `deniedMcpServers` and the plugin blockers.
* [Host apps, WSL, and executable path](/kong-harnesses/fleet-build-options/#host-apps-wsl-and-executable-path): Choose `--host-settings` and `--executable`.
* [Version bounds](/kong-harnesses/fleet-build-options/#version-bounds): Choose the version bounds.
* [Model overrides](/kong-harnesses/fleet-build-options/#model-overrides): Choose any `--model` overrides.

## Build the managed settings

Run `kong-harnesses fleet build` once for each group.
With `--platform`, you can build for every operating system from one computer.

Replace these placeholders in the command for your platform:

* `POLICY_FILE`: The file that holds the current policy.
  If there isn't a policy, replace `--policy 'POLICY_FILE'` with `--no-policy`.
* `MCP_MODE`: `exclusive`, `allowlist`, or `any`.
  Also add the flags that the mode needs, from [MCP server modes and exceptions](/kong-harnesses/fleet-build-options/#mcp-server-modes-and-exceptions).
* `GROUP`: A name for the group, without spaces, because the command doesn't quote `--output-dir`.

The `--output-dir` folder must be new or empty.

Keep the quotes in the command.
For the quotes that each shell needs, see [Allowlist values and quoting](/kong-harnesses/fleet-build-options/#allowlist-values-and-quoting).

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

Replace `DELIVERY` with `file` or `mdm`.

```sh
kong-harnesses fleet build --profile work --platform macos --delivery DELIVERY --executable /usr/local/bin/kong-harnesses --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-macos-GROUP
```

{% endnavtab %}
{% navtab "Linux" %}

Linux supports only `file` delivery, which is the default.

```sh
kong-harnesses fleet build --profile work --platform linux --executable /usr/bin/kong-harnesses --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-linux-GROUP
```

{% endnavtab %}
{% navtab "Windows" %}

Replace `DELIVERY` with `file` or `mdm`.

By default, {{ site.claude_code }} in Windows Subsystem for Linux (WSL) reads only its own managed settings.
To make it read the Windows managed settings of this build, add `--wsl inherit`.
For details, see [Host apps, WSL, and executable path](/kong-harnesses/fleet-build-options/#host-apps-wsl-and-executable-path).

```powershell
kong-harnesses fleet build --profile work --platform windows --delivery DELIVERY --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-windows-GROUP
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build files to `--output-dir`.
It also prints:

* Each file and its target path
* The policy changes
* The build ID and the build record path
* The install command
* The helper, model, MCP, and version choices

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
* **Secrets:** Confirm that the settings and `managed-mcp.json` don't hold secrets.
* **Credential helper:** Confirm that the helper runs `kong-harnesses credential --profile work` from the `--executable` path.
* **Hooks:** Confirm that the hooks report blocked MCP servers and skipped web searches.
  Models without WebSearch skip web searches.
* **Build ID:** Save the build ID, which is the value of `env.KONG_HARNESSES_FLEET_BUILD`.
  You compare it with the output of `kong-harnesses doctor` in [Validate](#validate).

kong-harnesses uses the machine-wide profile instead of a user profile with the same name.
It refuses the machine-wide profile unless only administrators can change the file and its parent folders.
The deploy steps for each platform list the owners and writers that kong-harnesses accepts.

## Deploy to managed computers

Deploy to one test computer for each platform and policy group first.
Roll out to the rest of the group only after the checks in [Validate](#validate) pass.

Install in the following order with your MDM tool or configuration management.
`fleet build` doesn't install CAs, {{ site.claude_code }}, or kong-harnesses.

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

1. Install {{ site.claude_code }} `2.1.285` or later.
   For the installer, see [Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup).
   To pin the version, see [Keep a {{ site.claude_code }} fleet on tested versions](/kong-harnesses/maintain-a-claude-code-fleet/).
   Run the native installer as each developer, not as `root`, so that it installs `~/.local/bin/claude`.
1. Install [kong-harnesses](/kong-harnesses/install/) system-wide, at the `--executable` path.
   Don't install it with Homebrew on managed Macs, because Homebrew shares `/usr/local/bin` on Intel Macs.
1. If you use a private gateway CA, add it to the macOS system trust store.
1. Copy the `--output-dir` folder to a Mac, and keep the file permissions.
   For example, use `ditto` or `rsync -a`.
1. In that folder, run the `pkgbuild` command that `fleet build` printed.
   Replace these placeholders:
   * `PACKAGE_IDENTIFIER`: A reverse DNS name for the package, such as `com.yourcompany.kong-harnesses-fleet`.
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
1. If you move from a file build to an MDM build, unassign the old package or script before you change the policy.
   For an Intune macOS app (PKG), remove its **Required** and **Available** assignments.
1. For an MDM build, upload `mdm/com.anthropic.claudecode.plist` as Custom Settings for `com.anthropic.claudecode`.
   It replaces the existing policy.
1. If you move from a file build, wait until `/status` on the computer shows the MDM build label from [Validate](#validate).
   Then delete `/Library/Application Support/ClaudeCode/managed-settings.d/kong-harnesses.json`, so that {{ site.claude_code }} stops reading its `env` and MCP lock.

The preinstall script checks the target paths and their parent folders before it writes.
If it prints `Not installed:`, fix the cause and run the install again.
The cause is a symlink, an extra hard link, an unexpected owner, or write permissions or ACLs that are too open.
Delete an unexpected file or link only at the exact path of a build file.
Never delete system folders, such as `/Library`.

{% endnavtab %}
{% navtab "Linux" %}

1. Install {{ site.claude_code }} `2.1.285` or later.
   For the installer, see [Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup).
   To pin the version, see [Keep a {{ site.claude_code }} fleet on tested versions](/kong-harnesses/maintain-a-claude-code-fleet/).
   Run the native installer as each developer, not as `root`, so that it installs `~/.local/bin/claude`.
   You can also install from the [`apt`, `dnf`, or `apk` repositories](https://code.claude.com/docs/en/setup#install-with-linux-package-managers).
1. Install [kong-harnesses](/kong-harnesses/install/) system-wide, at the `--executable` path.
1. If you use a private gateway CA, add it to the system trust store.
1. Confirm that the `acl` package, which provides `getfacl`, is installed on each managed computer.
1. Copy `root/` to the target computer.
   Inside `root/`, run the `sudo sh -c` command that `fleet build` printed.

   The command checks ownership, permissions, links, and ACLs.
   Then it copies the files under `/` and sets `root:root` ownership, 755 for folders, and 644 for files.
   `root` must own the machine-wide profile and its parent folders.
   The group and other users must not have write permission.

If the command prints `Not installed:`, fix the cause and run the command again.
The cause is a symlink, an extra hard link, an unexpected owner, write permissions or ACLs that are too open, or a missing `getfacl`.

If the command prints `could not be written in full; fix the cause and run the step again`, the write was partial.
Fix the cause and run the command again.

Delete an unexpected file or link only at the exact path of a build file.
Never delete system folders, such as `/etc`.

{% endnavtab %}
{% navtab "Windows" %}

1. Install {{ site.claude_code }} `2.1.285` or later.
   For the installer, see [Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup).
   To pin the version, see [Keep a {{ site.claude_code }} fleet on tested versions](/kong-harnesses/maintain-a-claude-code-fleet/).
   Run the native installer as each developer, not as SYSTEM, so that it installs `%USERPROFILE%\.local\bin\claude.exe`.
1. Install [kong-harnesses](/kong-harnesses/install/) system-wide, at the `--executable` path.
1. If you use a private gateway CA, add it to the Windows certificate store.
   With `--wsl inherit`, also add it to each WSL distribution.
1. Confirm that only `Administrators`, `SYSTEM`, `TrustedInstaller`, or `CREATOR OWNER` can modify files in `C:\Program Files`.
   Existing folders, such as `C:\Program Files\ClaudeCode`, can lose their explicit ACLs during the install.
1. Copy `root/` to the target computer.
   Inside `root/`, run the printed command from an elevated Windows PowerShell.

   The command checks the target paths for unexpected owners, writable ACLs, symlinks, junctions, and extra hard links.
   Then it copies the files under `C:\` and sets `Administrators` as the owner.
   It also runs `icacls /reset` on each path that it writes, including existing folders, so that they inherit the `C:\Program Files` ACLs.

   Only `Administrators`, `SYSTEM`, or `TrustedInstaller` may own and write the machine-wide profile and its folders, up to `C:\Program Files`.
   The path must not have symlinks or junctions.
1. If you move from a file build to an MDM build, unassign the old package or script before you change the policy.
1. For an MDM build, set the `REG_SZ` value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode` to the single-line JSON in `mdm/Settings.json`.
   It replaces the existing value.
1. If you move from a file build, wait until `/status` on the computer shows the MDM build label from [Validate](#validate).
   Then delete `C:\Program Files\ClaudeCode\managed-settings.d\kong-harnesses.json`, so that {{ site.claude_code }} stops reading its `env` and MCP lock.

If the command prints `Not installed:`, fix the cause and run the command again.
The cause is a symlink, a junction, an extra hard link, an unexpected owner, or writable ACLs.

If the command prints `could not be written in full; fix the cause and run the step again`, the write was partial.
Fix the cause and run the command again.

Delete an unexpected file or link only at the exact path of a build file.
Never delete system folders, such as `C:\Program Files`.

{% endnavtab %}
{% endnavtabs %}

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
   For the checks, see [WSL on Windows](/kong-harnesses/troubleshooting/claude-code-fleet/#wsl-on-windows).

{% endnavtab %}
{% endnavtabs %}

Then finish the checks on every platform:

1. Send `Say hello` and confirm that {{ site.claude_code }} replies.
1. Find the event under your control plane in the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger).
   Set the **User** filter to the subject of the test user.
   The [AI Auth Strategy](/ai-cost-management/attribution/#set-up-subject-attribution) decides the subject:
   * A principal: `principal/UUID`
   * An AI Consumer: `consumer/UUID`
   * An OpenID Connect claim without a principal: `oidc/CLAIM_VALUE`, where `CLAIM_VALUE` is the value of the claim that `credential_claim` names, `sub` by default
1. Confirm that no policy sets `disableAllHooks` to `true`.
   The test prompt doesn't check the hooks.
1. If the profile has gateway MCP servers, run `/mcp` and confirm that every server connects.
1. If `--host-settings merge` or `parentSettingsBehavior: "merge"` is active, test each supported embedding host app before the full rollout.
   Claude Desktop isn't a supported host app.
   For the checks, see [Host apps and WSL](/kong-harnesses/troubleshooting/claude-code-fleet/#host-apps-and-wsl).

If a check fails, see [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/).

After every test computer passes, roll out to the group.
To pin versions or change models later, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
