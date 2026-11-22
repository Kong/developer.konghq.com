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
        Install [kong-harnesses](/kong-harnesses/install/) on a build desktop that meets the requirement for its operating system.
        Each operating system also needs a tool that deploys to its managed computers:

        {% table %}
        columns:
          - title: Operating system
            key: os
          - title: Build desktop requirement
            key: requirement
          - title: Deployment tool
            key: tool
        rows:
          - os: macOS
            requirement: None
            tool: An MDM tool, such as Jamf Pro or Microsoft Intune
          - os: Linux
            requirement: Secret Service, such as GNOME Keyring or KWallet, outside WSL, a container, or an SSH session
            tool: Configuration management
          - os: Windows
            requirement: Windows 11
            tool: An MDM tool, such as Microsoft Intune
        {% endtable %}

        Create and install an HTTPS OIDC profile named `work` ([setup guide](/ai-gateway/set-up-claude-code-with-kong-harnesses/)), replacing `work` with your profile name.
        `fleet build` refuses `http://` origins and Claude subscription profiles.
        For the Anthropic API provider, your build computer must reach the gateway and trust any private gateway CA.
    - title: "{{ site.claude_code }} and test access"
      content: |
        You need administrator access on one test computer per platform and policy group, and [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) access ([required role](/ai-cost-management/analytics-and-debugging/#how-the-views-relate)).
        Target computers need {{ site.claude_code }} `2.1.285` or later to enforce `allowedProviders` ([Version range checks](/kong-harnesses/fleet-build-options/#version-range-checks)).

tldr:
  q: How do I roll out {{ site.claude_code }} to managed computers with kong-harnesses?
  a: |
    Sign in to your HTTPS profile for Anthropic API discovery, then run `kong-harnesses fleet build` per platform and policy group.
    Deploy {{ site.claude_code }}, kong-harnesses, any private CA, and build files to a test computer, validate, then roll out.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        To unassign the deployment, run `kong-harnesses fleet remove`, and delete build files, see [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/).

faqs:
  - q: Why does a fleet get its {{ site.claude_code }} settings through MDM instead of {{ site.ai_gateway }}?
    a: |
      {{ site.claude_code }} needs managed settings before its first request to set the {{ site.ai_gateway }} address and credential helper.
      Anthropic's [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability) need a direct `api.anthropic.com` connection and eligible credential, which a fleet helper key doesn't trigger.
      MDM sets the policy before first use so developers can't override it.
---

`kong-harnesses fleet build` creates a machine-wide profile and [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) locking managed macOS, Linux, and Windows computers to {{ site.ai_gateway }}.
Developers don't import profiles.
Each developer signs in through the browser on first use, and kong-harnesses renews the token automatically.
By default, {{ site.claude_code }} in Windows Subsystem for Linux (WSL) reads only its own managed settings unless you pass `--wsl inherit`.

## Sign in to the profile

For the Anthropic API provider, `kong-harnesses fleet build` uses your sign-in to read the gateway's model list (other Claude providers, such as Amazon Bedrock, use the profile or `--model` without signing in).
Run [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

kong-harnesses opens your browser to sign in.

## Review the existing policy

Build once per group sharing platform, delivery, policy, and `managed-mcp.json` (`exclusive`), and deploy only to that group.

{:.warning}
> **Keep secrets out of managed files:** Every account can read managed settings and `managed-mcp.json`.
> Remove secrets from `--policy` and `--mcp-config` before building ([fleet build options](/kong-harnesses/fleet-build-options/)).

Confirm these choices before building:

* [Delivery method and existing policy](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy): export MDM policy or `managed-settings.json` and clear policy, drop-in, header, and remote conflicts.
* [MCP server modes and exceptions](/kong-harnesses/fleet-build-options/#mcp-server-modes-and-exceptions): pick `--mcp-servers`, prepare `managed-mcp.json` or allowlists, and check `deniedMcpServers` and plugin blockers.
* [Host apps, WSL, and executable path](/kong-harnesses/fleet-build-options/#host-apps-wsl-and-executable-path): confirm `--host-settings`, `--wsl`, `--executable`, version bounds, and `--model`.

## Build the managed settings

Run `kong-harnesses fleet build` per group (`--platform` builds for any OS from one computer), keeping quotes and adding mode-specific MCP flags from [fleet build options](/kong-harnesses/fleet-build-options/) (see [Allowlist values and quoting](/kong-harnesses/fleet-build-options/#allowlist-values-and-quoting) for each shell).
Replace `POLICY_FILE` (or `--no-policy`), `MCP_MODE`, and `GROUP` without spaces (new or empty `--output-dir`).

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

Replace `DELIVERY` with `file` or `mdm`.

```sh
kong-harnesses fleet build --profile work --platform macos --delivery DELIVERY --executable /usr/local/bin/kong-harnesses --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-macos-GROUP
```

{% endnavtab %}
{% navtab "Linux" %}

Linux supports only `file` delivery, the default.

```sh
kong-harnesses fleet build --profile work --platform linux --executable /usr/bin/kong-harnesses --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-linux-GROUP
```

{% endnavtab %}
{% navtab "Windows" %}

Replace `DELIVERY` with `file` or `mdm`.

```powershell
kong-harnesses fleet build --profile work --platform windows --delivery DELIVERY --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-windows-GROUP
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes `--output-dir` and prints files, target paths, policy changes, build ID, record path, install command, and the helper, model, MCP, and version choices.

## Check the build output

`fleet build` writes files under `root/` at these target paths, and other files outside `root/`:

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

`--output-dir` also holds the build record `kong-harnesses-fleet-BUILD_ID.json`.
Keep it with your policy for `--record` updates and `fleet remove`.

Confirm before deploying:

* **Policy changes:** Review modified keys and inspect `modelPicker` if changed, because it replaces the whole `modelPicker` (including `replaceBuiltInOptions`) when a model isn't auto-discovered.
* **Secrets and helpers:** Confirm settings and `managed-mcp.json` don't contain secrets, the helper runs `kong-harnesses credential --profile work` at `--executable`, and hooks report blocked MCP servers and skipped web searches (models without WebSearch).
* **Build ID:** Save the build ID (`env.KONG_HARNESSES_FLEET_BUILD`) to match in `kong-harnesses doctor`.

kong-harnesses prefers the machine-wide profile over a same-named user profile and refuses it unless only administrators can modify the file and its parent folders.
The deploy step for your platform says which owners and writers it accepts.

## Deploy to managed computers

Deploy to one test computer per platform and policy group first, and roll out after [Validate](#validate) passes.
Install in this order through your MDM tool or configuration management.
`fleet build` doesn't install CAs, {{ site.claude_code }}, or kong-harnesses.

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

1. Install {{ site.claude_code }} `2.1.285` or later ([Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup), [version pinning](/kong-harnesses/maintain-a-claude-code-fleet/)).
   Run the native installer in each developer's user context, not as `root`, so it installs `~/.local/bin/claude`.
1. Install [kong-harnesses](/kong-harnesses/install/) system-wide at `--executable`.
   Don't use Homebrew on managed Macs, because it shares `/usr/local/bin` on Intel Macs.
1. If you use a private gateway CA, trust it in the macOS system trust store.
1. Copy `--output-dir` to a Mac preserving permissions (`ditto` or `rsync -a`).
1. Inside that folder, build `kong-harnesses-fleet.pkg` with the printed `pkgbuild` command (sets `root` ownership, 755/644 modes, and `scripts/preinstall`), replacing `PACKAGE_IDENTIFIER` and `PACKAGE_VERSION`:

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

1. If your MDM requires a signed distribution package ([Apple MDM](https://support.apple.com/guide/deployment/distribute-packages-to-mac-computers-dep873c25ac4/web), Jamf Pro [PreStage enrollment](https://learn.jamf.com/r/en-US/jamf-pro-documentation-current/Computer_PreStage_Enrollment_Payload_Reference)), sign it with your Keychain installer certificate:

   ```sh
   productbuild --sign 'INSTALLER_IDENTITY' \
     --package kong-harnesses-fleet.pkg \
     kong-harnesses-fleet-signed.pkg
   ```

1. Deploy the package through MDM.
   In Microsoft Intune, add it as a [macOS app (PKG)](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos), not a line-of-business app, because without an `/Applications` `.app` bundle Intune may not detect it.
   `root` must own the machine-wide profile and its parent folders, without group or world write permissions.
1. If you migrate from a file build to an MDM build, unassign the old package or script before you change the policy (for an Intune macOS PKG, remove its **Required** and **Available** assignments).
1. For an MDM build, upload `mdm/com.anthropic.claudecode.plist` as Custom Settings for `com.anthropic.claudecode`, replacing the existing policy.
1. If you migrate from a file build, wait until `/status` on the computer shows the MDM build label from [Validate](#validate).
   Then delete `/Library/Application Support/ClaudeCode/managed-settings.d/kong-harnesses.json`, so {{ site.claude_code }} stops reading its `env` and MCP lock.

The preinstall script checks the targets and their parent folders before it writes.
If it prints `Not installed:`, fix the cause (symlink, extra hard link, unexpected owner, or writable permissions or ACLs) and retry.
Delete an unexpected file or link only at a build file's exact path, never system folders such as `/Library`.

{% endnavtab %}
{% navtab "Linux" %}

1. Install {{ site.claude_code }} `2.1.285` or later ([Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup), [version pinning](/kong-harnesses/maintain-a-claude-code-fleet/)).
   Run the native installer in each developer's user context, not as `root`, so it installs `~/.local/bin/claude`.
   Or install from the [`apt`, `dnf`, or `apk` repositories](https://code.claude.com/docs/en/setup#install-with-linux-package-managers).
1. Install [kong-harnesses](/kong-harnesses/install/) system-wide at `--executable`.
1. If you use a private gateway CA, trust it in the system trust store.
1. Confirm `acl` (`getfacl`) is installed on each managed computer.
1. Copy `root/` to the target computer and run the printed `sudo sh -c` command inside `root/`.

   The command checks ownership, permissions, links, and ACLs, copies under `/`, and sets `root:root` with 755 folders and 644 files.
   `root` must own the machine-wide profile and its parent folders, without group or world write permissions.

If the command prints `Not installed:`, fix the cause (symlink, extra hard link, unexpected owner, writable permissions or ACLs, or missing `getfacl`) and retry.
If it prints `could not be written in full; fix the cause and run the step again`, the write was partial: fix the cause and run the command again.
Delete an unexpected file or link only at a build file's exact path, never system folders such as `/etc`.

{% endnavtab %}
{% navtab "Windows" %}

1. Install {{ site.claude_code }} `2.1.285` or later ([Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup), [version pinning](/kong-harnesses/maintain-a-claude-code-fleet/)).
   Run the native installer in each developer's user context, not as SYSTEM, so it installs `%USERPROFILE%\.local\bin\claude.exe`.
1. Install [kong-harnesses](/kong-harnesses/install/) system-wide at `--executable`.
1. If you use a private gateway CA, trust it in the Windows certificate store, and for `--wsl inherit` in each WSL distribution.
1. Confirm `C:\Program Files` allows only `Administrators`, `SYSTEM`, `TrustedInstaller`, or `CREATOR OWNER` to modify files, and existing folders (for example, `C:\Program Files\ClaudeCode`) can lose explicit ACLs.
1. Copy `root/` to the target computer and run the printed command from elevated Windows PowerShell inside `root/`.

   The command checks targets for unexpected owners, writable ACLs, symlinks, junctions, and extra hard links, copies under `C:\`, sets `Administrators` ownership, and runs `icacls /reset` on written paths (including existing folders) to inherit `C:\Program Files` ACLs.
   Only `Administrators`, `SYSTEM`, or `TrustedInstaller` may own and write the machine-wide profile and its folders up to `C:\Program Files`, without symlinks or junctions.
1. If you migrate from a file build to an MDM build, unassign the old package or script before you change the policy.
1. For an MDM build, set the `REG_SZ` value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode` to the single-line JSON in `mdm/Settings.json`, replacing the existing value.
1. If you migrate from a file build, wait until `/status` on the computer shows the MDM build label from [Validate](#validate).
   Then delete `C:\Program Files\ClaudeCode\managed-settings.d\kong-harnesses.json`, so {{ site.claude_code }} stops reading its `env` and MCP lock.

If the command prints `Not installed:`, fix the cause (symlink, junction, extra hard link, unexpected owner, or writable ACLs) and retry.
If it prints `could not be written in full; fix the cause and run the step again`, the write was partial: fix the cause and run the command again.
Delete an unexpected file or link only at a build file's exact path, never system folders such as `C:\Program Files`.

{% endnavtab %}
{% endnavtabs %}

## Validate

Sign in to each test computer as a standard developer without a saved sign-in, and verify before sending a prompt:

1. For `--mcp-servers allowlist` or `any` with gateway MCP servers, run [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

   ```sh
   kong-harnesses profile activate work --client claude-code
   ```

   If activation fails because user `settings.json` sets `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, remove them from `env` and retry.
1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/):

   ```sh
   kong-harnesses doctor --profile work --client claude-code
   ```

   Confirm `doctor` reports your organization's managed settings configure {{ site.claude_code }} and prints the `fleet build` ID (a browser sign-in note is expected without a saved sign-in).
   Fix any errors before continuing.
1. Start {{ site.claude_code }} (`claude`) and sign in when the browser opens on startup (Anthropic API discovery) or first request.

Check the settings source on each test computer:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

Run `/status` and confirm that `Setting sources` shows `Enterprise managed settings` with the label of your build:

* File build: `(drop-ins)` or `(file + drop-ins)`
* MDM build: `(plist)`, or a `, merged` list starting with `plist`

{% endnavtab %}
{% navtab "Linux" %}

Run `/status` and confirm that `Setting sources` shows `Enterprise managed settings` with `(drop-ins)` or `(file + drop-ins)`.
Linux supports only file builds.

{% endnavtab %}
{% navtab "Windows" %}

1. Run `/status` and confirm that `Setting sources` shows `Enterprise managed settings` with the label of your build:

   * File build: `(drop-ins)` or `(file + drop-ins)`
   * MDM build: `(HKLM)`, or a `, merged` list starting with `HKLM`
1. Verify that WSL inheritance matches `--wsl`, using [WSL on Windows](/kong-harnesses/troubleshooting/claude-code-fleet/#wsl-on-windows).

{% endnavtab %}
{% endnavtabs %}

Then finish the check on every platform:

1. Send `Say hello`, confirm a reply, and verify the event under your control plane in the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) (filter by **User** `oidc/SUB`, where `SUB` is the test user's `sub` claim, or configure [subject attribution](/ai-cost-management/attribution/#set-up-subject-attribution)).
   Confirm policies don't set `disableAllHooks` to `true`, because the test prompt doesn't verify hooks.
1. For profiles with gateway MCP servers, run `/mcp` and confirm every server connects.
1. Before full rollout, test supported embedding host apps (not Claude Desktop) when `--host-settings merge` or `parentSettingsBehavior: "merge"` is active, using [Host apps and WSL](/kong-harnesses/troubleshooting/claude-code-fleet/#host-apps-and-wsl).

If any check fails, see [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/).

After every test computer passes, roll out to the group, and see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/) to pin versions or change models.
