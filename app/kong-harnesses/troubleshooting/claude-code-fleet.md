---
title: Troubleshoot a {{ site.claude_code }} fleet
description: Diagnose managed settings status labels, gateway MCP connections, embedding host apps, and WSL inheritance for kong-harnesses fleet builds.

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
  - troubleshooting

breadcrumbs:
  - /kong-harnesses/
  - url: /kong-harnesses/troubleshooting/
    title: Troubleshoot kong-harnesses

related_resources:
  - text: Troubleshoot kong-harnesses
    url: /kong-harnesses/troubleshooting/
  - text: Roll out {{ site.claude_code }} through MDM
    url: /kong-harnesses/roll-out-claude-code-through-mdm/
  - text: "{{ site.claude_code }} fleet build options"
    url: /kong-harnesses/fleet-build-options/
  - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
    url: /kong-harnesses/maintain-a-claude-code-fleet/
  - text: Remove a {{ site.claude_code }} fleet build
    url: /kong-harnesses/remove-a-claude-code-fleet-build/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
  - text: kong-harnesses errors and exit codes
    url: /kong-harnesses/errors/
---

A computer with a `kong-harnesses fleet build` can fail validation for these reasons:

* Another managed settings source outranks the build.
* An MCP policy blocks the gateway servers.
* A host app or a WSL distribution reads different settings.

For general `kong-harnesses doctor` checks, see [Troubleshoot kong-harnesses](/kong-harnesses/troubleshooting/).
For the deployment steps, see [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).
In each command, replace `PROFILE_NAME` with your profile name.

## Status labels

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
      The build files or the MDM policy didn't reach the computer.
      Or the policy doesn't set a [policy value](/kong-harnesses/fleet-build-options/#how-managed-sources-rank), for example when it sets only `managedSourcesBehavior` or `wslInheritsWindowsSettings`.
      Check the files at their [target paths](/kong-harnesses/roll-out-claude-code-through-mdm/#check-the-build-output), and deploy again.
  - label: "`(drop-ins)` or `(file + drop-ins)` on an MDM build"
    fix: |
      The MDM policy didn't reach the computer.
      Or the policy doesn't set a [policy value](/kong-harnesses/fleet-build-options/#how-managed-sources-rank), for example when it sets only `managedSourcesBehavior`, `wslInheritsWindowsSettings`, or empty objects.
      Check `Skipped sources` and the deployed MDM policy, and deploy again.
  - label: "`(plist)`, `(HKLM)`, or a merged list starting with `plist` or `HKLM` on a file build"
    fix: |
      An MDM policy on the computer outranks the file build.
      For details, see [Delivery method and existing policy](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy).
      Build again with `--delivery mdm --policy`.
  - label: "`(remote)` or a merged list starting with `remote`"
    fix: |
      Server-managed settings outrank the build.
      Cached remote settings can stay for up to 24 hours.
      Remove the conflicting credentials, and follow the remote settings rules in [Check the existing policy](/kong-harnesses/fleet-build-options/#check-the-existing-policy).
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

## Gateway MCP connections

When a gateway MCP server doesn't connect or doesn't show in `/mcp`, check these causes:

* **Key server without a saved key:** Run `kong-harnesses login --profile PROFILE_NAME` once to save each key.
* **Rejected key on a key server:** Have all server keys ready.
  Then run `kong-harnesses logout --profile PROFILE_NAME` and `kong-harnesses login --profile PROFILE_NAME`.
  When a saved sign-in exists, `logout` asks you to type the profile name.
  It signs out of the profile and removes the saved sign-in and every saved gateway MCP key of the profile.
  When only saved gateway MCP keys remain, `logout` deletes them without a prompt.
* **Server with its own OAuth sign-in:** Sign in from `/mcp`.
* **Gateway-authenticated server failed at startup:** A server can [fail during the first browser sign-in](https://code.claude.com/docs/en/mcp#failed-first-connections).
  After you sign in, reconnect it from `/mcp`.
* **Missing servers:** To find invalid entries that {{ site.claude_code }} dropped, run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` and `claude doctor`.
  For `--mcp-servers allowlist` or `any`, `profile activate` installs the gateway MCP plugin in `.claude/skills` in the developer's home folder.
  When `CLAUDE_CONFIG_DIR` is set, it installs the plugin in `skills` in that folder.
  Remove `--strict-mcp-config` from startup commands.
  Check `allowedMcpServers` and `deniedMcpServers` in all settings scopes:
  * User settings
  * Project settings
  * Local settings
  * `--settings`
  * Every administrator source, including remote server-managed settings

  `kong-harnesses doctor` reads the local administrator sources, but not remote server-managed settings.
  It reads them as {{ site.claude_code }} does:
  * It reads each `allowedMcpServers` and `deniedMcpServers` entry on its own, and keeps the valid ones.
  * It ignores keys whose letter case doesn't match.
  * It checks `deniedMcpServers` also when `managed-mcp.json` exists.
  * It treats a `strictPluginOnlyCustomization` value that isn't a boolean, a list, or `null`, such as a string, as `true`.
  * It treats a `null` `strictPluginOnlyCustomization` as no lock, because `null` removes the key.

  For the plugin blockers, see [Plugin blockers](/kong-harnesses/fleet-build-options/#plugin-blockers).

## Host apps and WSL

When the fleet build uses `--host-settings merge` or `--wsl inherit`, check the embedding host apps and WSL separately.

For host apps, the check applies when `--host-settings merge` is used or `parentSettingsBehavior` is `merge`.
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

  WSL reads a WSL-local policy under `/etc/claude-code` only when no Windows administrator document is present.
  Such a policy can show the same labels as a file build.
  So also confirm that the Windows build files are at their [target paths](/kong-harnesses/roll-out-claude-code-through-mdm/#check-the-build-output).
  The `Enterprise managed settings` label without one of these labels can also mean a WSL-local policy instead of the Windows build.
  Send a short test prompt, and confirm that the WSL usage event shows in the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger).
  `doctor` and gateway MCP servers don't run in WSL.
  If you get a TLS error, confirm that the private CA is trusted in WSL, and read the [`claude --debug`](https://code.claude.com/docs/en/network-config#verify-your-configuration) logs in `~/.claude/debug/`.
  If the credential helper exits with status `126`, turn on Windows interop in that WSL distribution.
* **Without `--wsl inherit`:** If WSL inherits the Windows settings, confirm that the Windows administrator sources leave out `wslInheritsWindowsSettings` or set it to a value that turns it off.
  For the values, see [WSL on Windows](/kong-harnesses/fleet-build-options/#wsl-on-windows).
