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

Managed computers configured with `kong-harnesses fleet build` can fail validation when another managed settings source outranks the build, an MCP policy blocks gateway servers, or a host app or WSL distribution reads different settings.
For general `kong-harnesses doctor` checks, see [Troubleshoot kong-harnesses](/kong-harnesses/troubleshooting/).
For deployment steps, see [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).
Replace `PROFILE_NAME` with your profile name in each command.

## Status labels

When `/status` shows an unexpected `Setting sources` label, check the `Skipped sources` line and run `claude doctor` to list [dropped invalid managed settings fields](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped).
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
      Build files or the MDM policy didn't reach the computer, or the policy sets no key that [counts as a policy value](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy).
      Verify the files at their [target paths](/kong-harnesses/roll-out-claude-code-through-mdm/#check-the-build-output) and redeploy.
  - label: "`(drop-ins)` or `(file + drop-ins)` on an MDM build"
    fix: |
      The MDM policy didn't reach the computer or sets no key that [counts as a policy value](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy).
      Check `Skipped sources`, verify the deployed MDM policy, and redeploy.
  - label: "`(plist)`, `(HKLM)`, or a merged list starting with `plist` or `HKLM` on a file build"
    fix: |
      An MDM policy on the computer outranks the file build ([Delivery method and existing policy](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy)).
      Rebuild with `--delivery mdm --policy`.
  - label: "`(remote)` or a merged list starting with `remote`"
    fix: |
      Server-managed settings outrank the build, and cached remote settings can persist for up to 24 hours.
      Remove conflicting credentials and follow the remote settings rules in [Delivery method and existing policy](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy).
  - label: "`(helper)`"
    fix: |
      `policyHelper` or `policyHelpers` in the MDM policy, `managed-settings.json`, or `managed-settings.d/` overrides managed settings.
      Remove it from all managed sources.
  - label: "`(parent process)`"
    fix: |
      Only host-app settings loaded.
      Start `claude` from a terminal to confirm, then redeploy the build.
{% endtable %}

## Gateway MCP connections

When a gateway MCP server isn't connected or doesn't appear in `/mcp`, check these causes:

* **Key server without a saved key:** Run `kong-harnesses login --profile PROFILE_NAME` once to save each key.
* **Rejected key on a key server:** Run `kong-harnesses logout --profile PROFILE_NAME` and then `kong-harnesses login --profile PROFILE_NAME`.
  When a saved sign-in exists, `logout` asks you to type the profile name, signs out of the profile, and removes both the saved sign-in and every saved gateway MCP key of the profile.
  When only saved gateway MCP keys remain without a saved sign-in, `logout` deletes those keys without a prompt.
  Have all server keys ready before running `logout`.
* **Server with its own OAuth sign-in:** Sign in from `/mcp`.
* **Gateway-authenticated server failed at startup:** If a server [fails during the initial browser sign-in](https://code.claude.com/docs/en/mcp#failed-first-connections), reconnect it from `/mcp` after signing in.
* **Missing servers:** Run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` and `claude doctor` to find dropped invalid entries.
  For `--mcp-servers allowlist` or `any`, `profile activate` installs the gateway MCP plugin in `.claude/skills` under the developer's home folder, or in `skills` inside `CLAUDE_CONFIG_DIR` when it's set.
  Remove `--strict-mcp-config` from startup commands, and check both `allowedMcpServers` and `deniedMcpServers` across all settings scopes:
  * User settings
  * Project settings
  * Local settings
  * `--settings`
  * Every administrator source, including remote server-managed settings

  `kong-harnesses doctor` reads local administrator sources (not remote server-managed settings).
  As {{ site.claude_code }} does, `doctor` reads each `allowedMcpServers` and `deniedMcpServers` entry on its own and keeps the valid ones, ignores keys whose case doesn't match, checks `deniedMcpServers` even when `managed-mcp.json` exists, treats a `strictPluginOnlyCustomization` value that isn't a boolean, a list or `null` (strings included) as `true`, and treats `null` as no lock because it removes the key.
  For plugin blockers (a `managed-mcp.json` file, a `managedMcpServers` entry at a gateway server's URL, `strictPluginOnlyCustomization`, and marketplace lists), see [MCP server modes and exceptions](/kong-harnesses/fleet-build-options/#mcp-server-modes-and-exceptions).

## Host apps and WSL

Validate embedding host apps and WSL separately when your fleet build uses `--host-settings merge` or `--wsl inherit`.

For host apps (`--host-settings merge` or `parentSettingsBehavior` set to `merge`), start a session from each supported host app, such as the {{ site.claude_code }} extension for VS Code, and run `/status`, `/mcp`, and a test prompt.
Terminal sessions and `kong-harnesses doctor` don't read host-passed settings.
Exclude Claude Desktop ([Host settings](/kong-harnesses/fleet-build-options/#host-settings)).

### WSL on Windows

Check WSL on each Windows test computer:

* **WSL (`--wsl inherit`):** In each WSL distribution, start `claude` and run `/status` before sending a prompt.
  Confirm `Setting sources` shows `Enterprise managed settings` with a label matching the Windows build's delivery: `(drop-ins)` or `(file + drop-ins)` for a file build, or `(HKLM)` or a merged list starting with `HKLM` for an MDM build.
  A generic `Enterprise managed settings` label alone can indicate a WSL-local `/etc/claude-code` policy instead of the Windows build.
  Send a short test prompt and verify the WSL usage event appears in the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) (`doctor` and gateway MCP servers don't run in WSL).
  If you hit a TLS error, confirm the private CA is trusted inside WSL and inspect [`claude --debug`](https://code.claude.com/docs/en/network-config#verify-your-configuration) logs under `~/.claude/debug/`.
  If the credential helper exits with status `126`, enable Windows interop in that WSL distribution.
* **Without `--wsl inherit`:** If WSL inherits Windows settings unexpectedly, verify the Windows administrator sources omit `wslInheritsWindowsSettings` or set a disabled value as described in [WSL on Windows](/kong-harnesses/fleet-build-options/#wsl-on-windows).
