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
        To unassign the deployment, revert managed settings and `managed-mcp.json` with `kong-harnesses fleet remove`, and delete build files from managed computers, see [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/).
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

## Review the existing policy

Run `kong-harnesses fleet build` once for each group of managed computers that share the same platform, delivery method, existing {{ site.claude_code }} policy, and (for `exclusive` MCP mode) `managed-mcp.json`.
Deploy each build only to its matching group.

{:.warning}
> **Keep secrets out of managed files:** Every account on a managed computer can read managed settings and `managed-mcp.json`.
> Before building, remove all secrets from any file you pass to `--policy` or `--mcp-config`, such as API keys in `env`, `ANTHROPIC_CUSTOM_HEADERS`, or MCP server definitions.
> Use [per-user credentials](https://code.claude.com/docs/en/managed-mcp#authenticate-with-per-user-credentials) for MCP servers that require keys.

Before running `fleet build`, confirm these items using [{{ site.claude_code }} fleet build options](/kong-harnesses/fleet-build-options/):

* **Delivery method and current policy:** Choose `--delivery file` (default) when computers don't receive an MDM policy that sets a policy key, or `--delivery mdm` on macOS and Windows when they do (or when you prefer MDM delivery).
  Export the computers' current MDM policy or `managed-settings.json` to pass with `--policy`, and use `--no-policy` only when the group doesn't have one.
* **Policy conflicts and remote settings:** Remove incompatible keys from your policy and any `managed-settings.d/` drop-ins, migrate or scope server-managed settings, and move required non-secret `ANTHROPIC_CUSTOM_HEADERS` into your `--policy` input.
* **MCP server mode:** Choose `--mcp-servers` (`exclusive`, `allowlist`, or `any`; required when your profile defines gateway MCP servers), migrate displaced MDM allowlists or `serverName` entries, and verify no setting blocks the gateway MCP plugin.
* **Optional flags:** Decide whether the group needs `--host-settings merge`, `--wsl inherit` (Windows only), `--model`, or version bounds (`--claude-code-minimum` and `--claude-code-maximum`).

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

For unexpected `/status` labels, gateway MCP connection issues, or host app and WSL validation, see [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/).

After validation passes on each test computer, roll out the deployment to the rest of that group.
To pin {{ site.claude_code }} versions or move your fleet to a new model later, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
