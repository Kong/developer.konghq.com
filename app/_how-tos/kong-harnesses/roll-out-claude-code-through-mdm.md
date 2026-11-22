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
        Install [kong-harnesses](/kong-harnesses/install/) on your build desktop (macOS, Windows 11, or Linux with Secret Service, not WSL, a container, or SSH).
        Create and install an HTTPS OIDC profile named `work` ([setup guide](/ai-gateway/set-up-claude-code-with-kong-harnesses/)), replacing `work` with your profile name.
        `fleet build` refuses `http://` origins and Claude subscription profiles.
        For the Anthropic API provider, your build computer must reach the gateway and trust any private gateway CA.
    - title: MDM, {{ site.claude_code }}, and test access
      content: |
        You need an MDM tool (for example, Jamf Pro or Microsoft Intune) or Linux configuration management, administrator access on one test computer per platform and policy group, and [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) access ([required role](/ai-cost-management/analytics-and-debugging/#how-the-views-relate)).
        Target computers need {{ site.claude_code }} `2.1.285` or later to enforce `allowedProviders` (Linux also supports the [`apt`, `dnf`, and `apk` repositories](https://code.claude.com/docs/en/setup#install-with-linux-package-managers)).

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

For the Anthropic API provider, `kong-harnesses fleet build` reads the gateway's model list with your sign-in.
Sign in to `work` with [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

kong-harnesses opens your browser to sign in to your identity provider.
Other Claude providers, such as Amazon Bedrock, use the profile or `--model` flags and don't need a sign-in.

## Review the existing policy

Build once per group sharing platform, delivery, policy, and `managed-mcp.json` (`exclusive`), and deploy each build only to its matching group.

{:.warning}
> **Keep secrets out of managed files:** Every account can read managed settings and `managed-mcp.json`, so remove all secrets from `--policy` and `--mcp-config` before building (see [{{ site.claude_code }} fleet build options](/kong-harnesses/fleet-build-options/)).

Confirm these choices before building:

* [Delivery method and existing policy](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy): export the group's MDM policy or `managed-settings.json` and clear policy, drop-in, header, and remote conflicts.
* [MCP server modes and exceptions](/kong-harnesses/fleet-build-options/#mcp-server-modes-and-exceptions): pick `--mcp-servers`, prepare `managed-mcp.json` or allowlist flags, and check `deniedMcpServers` and plugin blockers.
* [Host apps, WSL, and executable path](/kong-harnesses/fleet-build-options/#host-apps-wsl-and-executable-path): confirm `--host-settings`, `--wsl`, `--executable`, version bounds, and model flags.

## Build the managed settings

Run `kong-harnesses fleet build` per group (`--platform` builds for any platform from one computer), keeping quotes and adding any mode-specific MCP flags (including PowerShell quoting) from [{{ site.claude_code }} fleet build options](/kong-harnesses/fleet-build-options/).
Replace `DELIVERY` (`file` or `mdm`, Linux supports only `file`), `POLICY_FILE` (or `--no-policy`), `MCP_MODE`, and `GROUP` without spaces (`--output-dir` must be new or empty).

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

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build to `--output-dir` and prints files, target paths, modified policy keys, build ID, record path, and install command.

## Check the build output

`fleet build` writes files under `root/` at these target paths:

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

`--output-dir` also holds `scripts/preinstall` (macOS), `mdm/com.anthropic.claudecode.plist` (macOS MDM) or `mdm/Settings.json` (Windows MDM), and `kong-harnesses-fleet-BUILD_ID.json` outside `root/`.
Keep `kong-harnesses-fleet-BUILD_ID.json` with your policy because `--record` updates and `fleet remove` require it.

Confirm three checks before deploying:

* **Modified keys and `modelPicker`:** Review policy changes and inspect `modelPicker` if changed, because it replaces your whole `modelPicker` (including `replaceBuiltInOptions`) when a model isn't auto-discovered.
* **Secrets and helpers:** Confirm settings and `managed-mcp.json` don't contain secrets, the helper runs `kong-harnesses credential --profile work` from `--executable`, and hooks report blocked MCP servers and skipped web searches (for models without WebSearch).
* **Build ID:** Record the printed build ID (also written to `env.KONG_HARNESSES_FLEET_BUILD`) to match in `kong-harnesses doctor`.

kong-harnesses reads the machine-wide profile ahead of any same-named user profile and refuses it unless only administrators can modify the file and parent folders.
On macOS and Linux, `root` must own them without group or world write permissions.
On Windows, `Administrators`, `SYSTEM`, or `TrustedInstaller` must own and be the only writers up to `C:\Program Files`, without symbolic links or junctions on the path.

## Deploy to managed computers

Deploy to one test computer per platform and policy group first, and roll out only after [Validate](#validate) passes.

Install these components through your MDM tool:

1. **{{ site.claude_code }}:** Install `2.1.285` or later ([Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup), [version pinning](/kong-harnesses/maintain-a-claude-code-fleet/)).
   Run the native installer in each developer's user context, not as `root` or SYSTEM (`~/.local/bin/claude` or `%USERPROFILE%\.local\bin\claude.exe`).
1. **kong-harnesses:** Install the system-wide package at `--executable` ([system-wide install guide](/kong-harnesses/install/)).
   Don't use Homebrew on managed Macs, because it shares `/usr/local/bin` on Intel Macs.
1. **Private gateway CA (if used):** Trust it in the OS store, and in each WSL distribution for `--wsl inherit` (`fleet build` doesn't install CAs).
1. **Build files (`root/`):** Install as an administrator using [Package or copy the build files](#package-or-copy-the-build-files).
1. **MDM policy (MDM builds only):**
   * **macOS:** Upload `mdm/com.anthropic.claudecode.plist` as Custom Settings for `com.anthropic.claudecode`, replacing any existing policy.
   * **Windows:** Set `REG_SZ` `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode` to `mdm/Settings.json`, replacing any existing value.
   * **Migrating from a file build:** Unassign the old package or script first (Intune macOS PKG: remove **Required** and **Available** assignments) and delete `managed-settings.d/kong-harnesses.json` so {{ site.claude_code }} stops reading its `env` and MCP lock.

### Package or copy the build files

{% navtabs "deploy-fleet-files" %}
{% navtab "macOS" %}

1. Copy `--output-dir` to a Mac preserving permissions (`ditto` or `rsync -a`).
1. Inside that folder, build `kong-harnesses-fleet.pkg` using the printed `pkgbuild` command (sets `root` ownership, 755/644 modes, and `scripts/preinstall`), replacing `PACKAGE_IDENTIFIER` and `PACKAGE_VERSION`:

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

1. Deploy through MDM (in Microsoft Intune, add it as a [macOS app (PKG)](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos), not a line-of-business app, because it doesn't install a `.app` bundle under `/Applications` and Intune may not report detection).

{% endnavtab %}
{% navtab "Linux" %}

1. Confirm `acl` (providing `getfacl`) is installed on each managed computer.
1. Copy `root/` to the target computer and run the printed `sudo sh -c` command inside `root/`.

The command checks ownership, permissions, links, and ACLs, copies under `/`, and sets `root:root` with 755 folders and 644 files.

{% endnavtab %}
{% navtab "Windows" %}

1. Confirm `C:\Program Files` allows only `Administrators`, `SYSTEM`, `TrustedInstaller`, or `CREATOR OWNER` to modify files, and existing destination folders (for example, `C:\Program Files\ClaudeCode`) can lose explicit ACLs.
1. Copy `root/` to the target computer and run the printed command from elevated Windows PowerShell inside `root/`.

The command checks targets for unexpected owners, writable ACLs, symlinks, junctions, and extra hard links, then copies under `C:\`, sets `Administrators` ownership, and runs `icacls /reset` on every written path (including existing folders) to inherit `C:\Program Files` ACLs.

{% endnavtab %}
{% endnavtabs %}

{:.info}
> **Preinstall safety checks:** Before writing, the macOS preinstall script and Linux and Windows commands check targets and parent folders.
> * On `Not installed:`, fix the cause (symlink, extra hard link, unexpected owner, writable permissions or ACLs, or missing `getfacl`) and retry.
> * Remove an unexpected file or link only at a build file's exact path, never system folders such as `/etc`, `/Library`, or `C:\Program Files`.
> * On Linux and Windows, `could not be written in full; fix the cause and run the step again` indicates a partial write.
>   Fix the cause and rerun.

## Validate

Sign in to each test computer as a standard developer account without a saved sign-in, and verify before sending a prompt:

1. For `--mcp-servers allowlist` or `any` with gateway MCP servers, activate the plugin with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

   ```sh
   kong-harnesses profile activate work --client claude-code
   ```

   If activation fails because user `settings.json` sets `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, remove them from `env` and retry.
1. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/):

   ```sh
   kong-harnesses doctor --profile work --client claude-code
   ```

   Confirm `doctor` reports your organization's managed settings configure {{ site.claude_code }} and prints the same build ID as `fleet build` (a browser sign-in note is expected without a saved sign-in).
   Fix any errors before continuing.
1. Start {{ site.claude_code }} (`claude`) and sign in when the browser opens on startup (Anthropic API discovery) or first request.
1. Run `/status` before sending a prompt and confirm `Setting sources` shows `Enterprise managed settings` with `(drop-ins)` or `(file + drop-ins)` (file build), or `(plist)`, `(HKLM)`, or a `, merged` list starting with `plist` or `HKLM` (MDM build).
1. Send `Say hello`, confirm a reply, and verify the event under your control plane in the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) (filter by **User** `oidc/SUB`, or configure [subject attribution](/ai-cost-management/attribution/#set-up-subject-attribution)).
   Confirm your policies don't set `disableAllHooks` to `true`, because the test prompt doesn't verify hooks.
1. If your profile defines gateway MCP servers, run `/mcp` and confirm every server connects.
1. Before full rollout, test supported embedding host apps (excluding Claude Desktop) when `--host-settings merge` or `parentSettingsBehavior: "merge"` is active, and verify Windows WSL inheritance matches `--wsl`, using [Host apps and WSL](/kong-harnesses/troubleshooting/claude-code-fleet/#host-apps-and-wsl).

If any check fails, see [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/).

After every check passes on each test computer, roll out to the rest of the group.
To pin {{ site.claude_code }} versions or move to a new model, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
