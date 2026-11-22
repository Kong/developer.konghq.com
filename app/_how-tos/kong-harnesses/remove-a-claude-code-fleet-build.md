---
title: Remove a {{ site.claude_code }} fleet build
content_type: how_to
permalink: /kong-harnesses/remove-a-claude-code-fleet-build/
breadcrumbs:
  - /kong-harnesses/

description: Unassign a kong-harnesses fleet deployment, revert its managed settings and MCP config with fleet remove, and delete build files from managed computers.

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
  - text: Roll out {{ site.claude_code }} through MDM
    url: /kong-harnesses/roll-out-claude-code-through-mdm/
  - text: "{{ site.claude_code }} fleet build options"
    url: /kong-harnesses/fleet-build-options/
  - text: Remove kong-harnesses
    url: /kong-harnesses/remove-kong-harnesses/
  - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
    url: /kong-harnesses/maintain-a-claude-code-fleet/
  - text: Troubleshoot a {{ site.claude_code }} fleet
    url: /kong-harnesses/troubleshooting/claude-code-fleet/

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: kong-harnesses and the build record
      content: |
        Install [kong-harnesses](/kong-harnesses/install/) on your administration computer and have the deployed build's record file (`kong-harnesses-fleet-BUILD_ID.json`) ready.
        For an MDM build, export the MDM policy file that managed computers receive now.
        For an `exclusive` MCP build, copy the `managed-mcp.json` file that managed computers have now.
    - title: MDM and administrator access
      content: |
        You need access to your MDM tool to unassign packages and update or remove policies, and administrator rights on managed computers to delete build files and validate removal on a test computer.

tldr:
  q: How do I remove a kong-harnesses {{ site.claude_code }} fleet build from managed computers?
  a: |
    Have developers with user-level activations clean up their user settings before uninstalling kong-harnesses, then unassign the deployment in your MDM tool.
    Run `kong-harnesses fleet remove --record` (with the current `--policy` for MDM builds and `--mcp-config` for `exclusive` builds), apply or remove the printed policy and `managed-mcp.json`, delete the listed files as an administrator, and forget the package receipt on macOS.
---

Removing a kong-harnesses fleet build reverses the managed settings, machine-wide profile, and `managed-mcp.json` deployed by [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).
Follow these steps in order so MDM doesn't reinstall files and developers don't lose access to cleanup commands.

## Clean up developer user settings

Before uninstalling kong-harnesses from managed computers, have every developer with a user-level activation clean up user-level {{ site.claude_code }} settings with `kong-harnesses profile cleanup --client claude-code` as described in [Clean up agent CLI settings](/kong-harnesses/remove-kong-harnesses/#clean-up-agent-cli-settings).

## Unassign the deployment in your MDM tool

Unassign the fleet build package or deployment script in your MDM tool so it doesn't reinstall build files after you delete them.
For a Microsoft Intune macOS app (PKG), remove assigned groups from both its **Required** and **Available** assignments.

## Generate the removal plan

Run `kong-harnesses fleet remove` on your administration computer, replacing `BUILD_RECORD`, `POLICY_FILE`, `MCP_CONFIG_FILE`, and `BUILD_ID`.
Pass a new or empty folder with `--output-dir` whenever policy keys or your own MCP servers remain.

To remove a file build, run `fleet remove` with `--record` (for an `exclusive` MCP build, add `--mcp-config 'MCP_CONFIG_FILE' --output-dir fleet-removed-BUILD_ID` using the `managed-mcp.json` that computers have now):

```sh
kong-harnesses fleet remove --record 'BUILD_RECORD'
```

To remove an MDM build, pass both `--record` and the MDM policy file that computers receive now with `--policy` so later changes aren't lost (add `--mcp-config 'MCP_CONFIG_FILE'` for an `exclusive` MCP build):

```sh
kong-harnesses fleet remove \
  --record 'BUILD_RECORD' \
  --policy 'POLICY_FILE' \
  --output-dir fleet-removed-BUILD_ID
```

For an MDM build, `fleet remove` prints the removed or restored policy keys under `Taken out` and the MDM policy action.
For every build, it prints any updated `managed-mcp.json` file it wrote and every file path to delete under `Remove`.

## Apply the removal output

Apply each instruction that `kong-harnesses fleet remove` prints:

1. For an MDM build, review the `Taken out` list and re-add any key that you set yourself after the build to the same value the build wrote.
   `fleet remove` reverts or removes values matching what the build wrote because it can't distinguish them from administrator edits made after the build.
1. Update or remove the MDM policy:
   * If `fleet remove` writes a policy under `mdm/`, deploy that policy in place of the existing {{ site.claude_code }} MDM policy.
   * If `fleet remove` prints `Remove the Claude Code policy from your MDM`, remove the {{ site.claude_code }} policy from your MDM tool even when `fleet remove` doesn't write an `mdm/` folder.
1. If `fleet remove` writes `managed-mcp.json` under `root/`, inspect any kept server definitions that changed after the build, remove any that still point to the gateway, and deploy the updated file in place of the existing `managed-mcp.json`.
1. Delete every file path listed under `Remove` from each managed computer as an administrator.
1. On macOS, forget the package receipt on each managed computer so your MDM tool can install a future package with the same identifier and version:

   ```sh
   sudo pkgutil --forget PACKAGE_IDENTIFIER
   ```

## Validate

Confirm the removal on a test computer before closing out the rollout:

1. Verify that none of the exact file paths listed under `Remove` remain on the test computer (see [Check the build output](/kong-harnesses/roll-out-claude-code-through-mdm/#check-the-build-output) for target paths).
1. Start {{ site.claude_code }} and run `/status` to check `Setting sources` only for a source that this removal deleted:
   * **File build:** When no other `managed-settings.d/` drop-ins remain, confirm `(drop-ins)` and `(file + drop-ins)` no longer appear.
   * **MDM build:** When you removed the {{ site.claude_code }} policy from your MDM tool, confirm `(plist)` (macOS) or `(HKLM)` (Windows) no longer appears.

   Unrelated source labels, remaining drop-ins, and a kept MDM policy stay in `/status`.
   Confirm removal by the exact deleted file paths and the build ID check in the next step.
1. If kong-harnesses is still installed on the test computer, run [`kong-harnesses doctor`](/kong-harnesses/doctor/), replacing `PROFILE_NAME` with your profile name:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client claude-code
   ```

   Confirm `doctor` no longer reports the removed fleet build ID.
