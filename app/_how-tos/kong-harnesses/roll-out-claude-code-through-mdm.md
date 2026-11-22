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
    - title: kong-harnesses preview build
      content: |
        Install a [kong-harnesses](/kong-harnesses/) `preview` build (compiled with `-tags preview`) on your build computer, because release builds without `-tags preview` don't compile gated features (see [Install kong-harnesses for every user of a computer](/kong-harnesses/install/) for standard installation).
        Set `KONG_HARNESSES_FEATURES=fleet` in your shell (`export KONG_HARNESSES_FEATURES=fleet` on macOS and Linux, or `$env:KONG_HARNESSES_FEATURES = 'fleet'` in PowerShell) to enable `fleet build` and `fleet remove`.

        {:.info}
        > **Supported computers:** kong-harnesses runs on macOS, Windows 11, and Linux desktops with Secret Service, such as Ubuntu 26.04, 24.04, and 22.04, and Red Hat Enterprise Linux 9, on amd64 and arm64.
        > Set it up on your desktop, not in WSL, a container, or an SSH session.

        Run `kong-harnesses fleet build --help` to confirm the `fleet` commands are enabled (open a new terminal if the shell can't find `kong-harnesses`).
    - title: A kong-harnesses profile
      content: |
        Create and install an OIDC profile on your build computer using [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/) with your deployed gateway's `https://` origin.
        This guide names the profile `work`.
        Replace `work` with your profile name in every command and path.

        `fleet build` refuses plain `http://` origins and Claude subscription sign-in profiles.
        For the Anthropic API provider, your build computer must reach the gateway and trust any private gateway CA in its system trust store.
    - title: An MDM tool and test access
      content: |
        You need an MDM tool deploying packages and configuration profiles or policies, such as Jamf Pro on macOS or Microsoft Intune on Windows, or configuration management on Linux.
        You also need administrator rights on one test computer per platform and policy group, and access to the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) in {{ site.ai_cost_management }} (see [How the views relate](/ai-cost-management/analytics-and-debugging/#how-the-views-relate) for the required role).

tldr:
  q: How do I roll out {{ site.claude_code }} to managed computers with kong-harnesses?
  a: |
    Sign in to your HTTPS kong-harnesses profile if it uses the Anthropic API, then run `kong-harnesses fleet build` for each platform and policy group.
    Deploy {{ site.claude_code }}, a kong-harnesses preview build, any private gateway CA, and the build files through your MDM tool to a test computer first.
    Validate with `kong-harnesses doctor`, `/status`, and a test prompt before rolling out to the rest of the group.
    Each developer signs in through the browser on first use.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        To unassign the deployment, revert managed settings and `managed-mcp.json` with `kong-harnesses fleet remove`, and delete build files from managed computers, see [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/).

faqs:
  - q: Why does a fleet get its {{ site.claude_code }} settings through MDM instead of {{ site.ai_gateway }}?
    a: |
      {{ site.claude_code }} needs managed settings before its first request, because they set the {{ site.ai_gateway }} address and credential helper.
      {{ site.ai_gateway }} can't send settings to a client that doesn't know the gateway yet.
      Anthropic's [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability) need a direct connection to `api.anthropic.com` and an eligible credential, such as a claude.ai login.
      A key from the fleet's credential helper doesn't trigger that fetch.
      MDM or your install tool places managed settings before the first session, so developers can't override the gateway address or credential helper.
---

`kong-harnesses fleet build` generates a machine-wide profile and [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) locking {{ site.claude_code }} on managed macOS, Linux, and Windows computers to {{ site.ai_gateway }}.
By default, {{ site.claude_code }} in Windows Subsystem for Linux (WSL) reads only its own managed settings unless you pass `--wsl inherit`.

## Sign in to the profile

When your profile uses the Anthropic API provider, `kong-harnesses fleet build` fetches the gateway's model list with your sign-in.
Sign in to `work` with [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

kong-harnesses opens your browser so you can sign in to your identity provider.
For other Claude providers, such as Amazon Bedrock, `fleet build` uses the profile or `--model` flags and doesn't need a sign-in.

## Review the existing policy

Run `kong-harnesses fleet build` once per computer group sharing a platform, delivery method, existing policy, and `managed-mcp.json` (`exclusive` mode), and deploy each build only to its matching group.

{:.warning}
> **Keep secrets out of managed files:** Every account can read managed settings and `managed-mcp.json`.
> Remove all secrets from `--policy` and `--mcp-config` inputs, such as API keys in `env`, `ANTHROPIC_CUSTOM_HEADERS`, or MCP definitions, and use [per-user credentials](https://code.claude.com/docs/en/managed-mcp#authenticate-with-per-user-credentials).

Confirm these choices using [{{ site.claude_code }} fleet build options](/kong-harnesses/fleet-build-options/):

* **Delivery and current policy:** Choose `--delivery file` (default) or `--delivery mdm` (macOS and Windows).
  Export the group's current MDM policy or `managed-settings.json` for `--policy`, and use `--no-policy` only when the group doesn't have one.
* **Policy conflicts:** Remove incompatible keys from your policy and `managed-settings.d/` drop-ins, migrate or scope server-managed settings, and move required non-secret `ANTHROPIC_CUSTOM_HEADERS` into `--policy`.
* **MCP server mode:** Choose `--mcp-servers` (`exclusive`, `allowlist`, or `any`), migrate displaced MDM allowlists or `serverName` entries, and verify no setting blocks the gateway MCP plugin.
* **Optional flags:** Decide whether the group needs `--host-settings merge`, `--wsl inherit`, `--model`, or version bounds (`--claude-code-minimum` and `--claude-code-maximum`).

## Build the managed settings

Run `kong-harnesses fleet build` for each target group (set `--platform` to build for any platform from one computer).
Replace these placeholders and keep the quotes:

* `DELIVERY`: `file` or `mdm` (macOS and Windows only; Linux supports only `file`).
* `POLICY_FILE`: Exported MDM policy or `managed-settings.json` copy (use `--no-policy` instead only when none exists).
* `MCP_MODE`: `exclusive`, `allowlist`, or `any` (add `--mcp-config 'MCP_CONFIG_FILE'` for `exclusive`, or `--mcp-url` and `--mcp-command` for `allowlist`).
* `GROUP`: Short group name without spaces (`--output-dir` must be new or empty).

Set `--executable` to the absolute path of `kong-harnesses` (or `kong-harnesses.exe` with drive letter and backslashes on Windows).
See [Executable path restrictions](/kong-harnesses/fleet-build-options/#executable-path-restrictions) for forbidden characters.

Build the managed settings for your target platform:

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

Quote `--mcp-url` and `--mcp-command` so PowerShell preserves `*` wildcards and JSON quotes.
In Windows PowerShell 5.1, escape inner double quotes with `\` (for example, `--mcp-command '[\"npx\",\"-y\",\"PACKAGE\"]'`), or use PowerShell 7.3 or later.

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build into `--output-dir` and prints target paths, modified policy keys, build ID, record file path, and the install command.

## Check the build output

Inspect `--output-dir` with the `fleet build` summary:

* `root/`: Files to install at the paths `fleet build` printed.
* `scripts/preinstall` (macOS): Preinstall safety check script.
* `mdm/com.anthropic.claudecode.plist` (macOS MDM) or `mdm/Settings.json` (Windows MDM): Policy payload or `Settings` registry line.
* `kong-harnesses-fleet-BUILD_ID.json`: Build record outside `root/`.

{:.info}
> **Back up the build record:** Keep `kong-harnesses-fleet-BUILD_ID.json` with your policy because updates (`--record`) and removals (`fleet remove`) require it.

Confirm three checks before deploying:

* **Modified keys and `modelPicker`:** Review every listed change.
  If `modelPicker` changed, inspect it because it replaces your whole `modelPicker` (including `replaceBuiltInOptions`) when a model ID isn't auto-discovered.
* **No secrets and expected helpers:** Confirm settings and `managed-mcp.json` don't contain secrets.
  The helper runs `kong-harnesses credential --profile work` from `--executable`, and hooks report blocked MCP servers and (when a model can't run WebSearch) skipped web searches.
* **Build ID:** Record `env.KONG_HARNESSES_FLEET_BUILD` to verify in `doctor`.

On managed computers, kong-harnesses reads the machine-wide profile ahead of any same-named user profile and refuses it if non-administrators can modify it.
Do not change the owner or permissions that the install step sets.

## Deploy to managed computers

Deploy to one test computer per platform and policy group first, and roll out to the rest only after [Validate](#validate) passes.

Install these components through your MDM tool:

1. **{{ site.claude_code }}:** Install `2.1.285` or later to enforce `allowedProviders` ([Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup), [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/)).
   Run the native installer in each developer's user context, not as `root` or SYSTEM, so it installs in `~/.local/bin/claude` or `%USERPROFILE%\.local\bin\claude.exe`.
1. **kong-harnesses:** Install a `preview` build (`-tags preview`) at `--executable` ([Install kong-harnesses for every user of a computer](/kong-harnesses/install/)).
   Preview builds read machine-wide profiles and run the MCP policy hook without `KONG_HARNESSES_FEATURES` set.
   Don't use Homebrew on managed Macs, because Homebrew shares `/usr/local/bin` on Intel Macs.
1. **Private gateway CA (if used):** Add it to the OS system trust store, and to each WSL distribution when using `--wsl inherit` (`fleet build` doesn't install CAs).
1. **Build files under `root/`:** Install as an administrator using [Package or copy the build files](#package-or-copy-the-build-files).
1. **MDM policy (MDM builds only):**
   * **macOS:** Upload `mdm/com.anthropic.claudecode.plist` as a Custom Settings payload for `com.anthropic.claudecode`, replacing any existing policy.
   * **Windows:** Set `REG_SZ` value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode` to the line in `mdm/Settings.json`, replacing any existing value.
   * **Migrating from a file build:** Unassign the old package or script first (Intune macOS PKG: remove **Required** and **Available** group assignments) and delete `managed-settings.d/kong-harnesses.json` so {{ site.claude_code }} stops reading its `env` and MCP lock.

### Package or copy the build files

{% navtabs "deploy-fleet-files" %}
{% navtab "macOS" %}

1. Copy `--output-dir` to a Mac while preserving permissions (`ditto` or `rsync -a`).
1. In that folder, build `kong-harnesses-fleet.pkg` using the `pkgbuild` command `fleet build` printed, replacing `PACKAGE_IDENTIFIER` and `PACKAGE_VERSION`:

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

   `pkgbuild` sets `root` ownership, 755/644 permissions, and `scripts/preinstall`.
1. If your MDM requires a signed distribution package, such as [Apple MDM](https://support.apple.com/guide/deployment/distribute-packages-to-mac-computers-dep873c25ac4/web) or Jamf Pro [PreStage enrollment](https://learn.jamf.com/r/en-US/jamf-pro-documentation-current/Computer_PreStage_Enrollment_Payload_Reference), sign it with your Keychain installer certificate:

   ```sh
   productbuild --sign 'INSTALLER_IDENTITY' \
     --package kong-harnesses-fleet.pkg \
     kong-harnesses-fleet-signed.pkg
   ```

1. Deploy the package through your MDM tool.
   In Microsoft Intune, add it as a [macOS app (PKG)](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos), not a line-of-business app, because it doesn't install a `.app` bundle under `/Applications` (Intune may not report detection).

{% endnavtab %}
{% navtab "Linux" %}

1. Confirm `acl` (providing `getfacl`) is installed on each managed computer.
1. Copy `root/` to the target computer.
1. Inside `root/`, run the `sudo sh -c` copy command `fleet build` printed.

The command checks ownership, permissions, links, and ACLs, copies files under `/`, and sets `root:root` ownership with 755 folders and 644 files.

{% endnavtab %}
{% navtab "Windows" %}

1. Verify `C:\Program Files` allows only these accounts to modify files, and confirm existing destination folders (for example, `C:\Program Files\ClaudeCode`) can lose explicit ACL rules:
   * `Administrators`
   * `SYSTEM`
   * `TrustedInstaller`
   * `CREATOR OWNER`
1. Copy `root/` to the target computer.
1. In an elevated Windows PowerShell inside `root/`, run the copy command `fleet build` printed.

Before copying under `C:\`, the command validates targets for:

* Unexpected owners
* Writable ACLs
* Symbolic links, junctions, and extra hard links

It then sets `Administrators` ownership and runs `icacls /reset` on every written path (including existing folders) to inherit `C:\Program Files` ACLs.

{% endnavtab %}
{% endnavtabs %}

{:.info}
> **Preinstall safety checks:** Before writing files, the macOS preinstall script and Linux and Windows copy commands inspect existing targets and parent folders.
> * If installation stops with `Not installed:`, fix the reported condition (symlink, extra hard link, unexpected owner, writable permissions or ACLs, or missing `getfacl` on Linux) and retry.
> * Remove an unexpected file or link only at a build file's exact path, and never remove system folders such as `/etc`, `/Library`, or `C:\Program Files`.
> * On Linux and Windows, `could not be written in full; fix the cause and run the step again` means the build can be partly written.
>   Fix the reported cause and run again.

## Validate

Sign in to each test computer as a standard developer account without a saved sign-in, and verify the build before sending a prompt:

1. For `--mcp-servers allowlist` or `any` with gateway MCP servers, activate the gateway MCP plugin with [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/):

   ```sh
   kong-harnesses profile activate work --client claude-code
   ```

   If activation fails because user `settings.json` sets `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, remove them from `env` and retry.
1. Set `KONG_HARNESSES_FEATURES=fleet` to include the `mcp` check, then run [`kong-harnesses doctor`](/kong-harnesses/doctor/):

   ```sh
   kong-harnesses doctor --profile work --client claude-code
   ```

   Confirm `doctor` reports your organization's managed settings configure {{ site.claude_code }} and the build ID matches `fleet build` (a browser sign-in note is expected without a saved sign-in).
   Fix any errors before continuing.
1. Start {{ site.claude_code }} to test first-use browser sign-in:

   ```sh
   claude
   ```

   Sign in with the test developer's identity provider account when kong-harnesses opens the browser on startup (Anthropic API discovery) or first request.
1. Run `/status` before sending a prompt and confirm `Setting sources` shows `Enterprise managed settings` with:
   * **File build:** `(drop-ins)` or `(file + drop-ins)`.
   * **MDM build:** `(plist)` on macOS, `(HKLM)` on Windows, or a `, merged` list starting with `plist` or `HKLM`.

   Combined with the `doctor` build ID, this confirms {{ site.claude_code }} applies your fleet build.
1. Send `Say hello` and confirm a reply without errors.
   In the {{ site.ai_cost_management }} [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger), verify the test user's event appears under your gateway control plane (filter by **User** `oidc/SUB` for the test user's `sub` claim, or configure [subject attribution](/ai-cost-management/attribution/#set-up-subject-attribution)).
1. If your profile defines gateway MCP servers, run `/mcp` and confirm every server shows as connected.

For unexpected `/status` labels, gateway MCP issues, or host app and WSL checks, see [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/).

After validation passes on each test computer, roll out to the rest of the group.
To pin {{ site.claude_code }} versions or move your fleet to a new model, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
