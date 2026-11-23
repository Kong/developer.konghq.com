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
        Install [kong-harnesses](/kong-harnesses/install/) on your administration computer.
        Have the build record of the deployed build ready: `kong-harnesses-fleet-BUILD_ID.json`.
        For an MDM build, export the MDM policy that the managed computers get now.
        For an `exclusive` MCP build, copy the `managed-mcp.json` file that the managed computers have now.
    - title: Deployment tool and administrator access
      content: |
        You need:

        * Access to the tool that deployed the build, to unassign the deployment
        * For an MDM build, access to the MDM policy, to update or remove it
        * Administrator rights on the managed computers, to delete the build files and to validate the removal on a test computer

tldr:
  q: How do I remove a kong-harnesses {{ site.claude_code }} fleet build from managed computers?
  a: |
    Have each developer sign out of the machine-wide profile and clean up any user-level activation.
    Then [unassign the deployment](#unassign-the-deployment) in the tool that deployed it.
    Run [`kong-harnesses fleet remove`](#generate-the-removal-plan) with the build record in `--record`.
    For an MDM build, add the current `--policy`, and for an `exclusive` build, add `--mcp-config`.
    Follow the instruction under `MDM policy` when that section appears.
    Follow the instructions under `MCP config` when that section appears.
    Delete each file listed under `Remove` with the [steps for your platform](#apply-the-removal-output).
---

This guide removes the managed settings, the machine-wide profile, and the `managed-mcp.json` file that you deployed with [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).
Do the steps in order, so that your deployment tool doesn't install the files again and developers can still run the sign-out and cleanup commands.

## Have developers sign out and clean up

Before you unassign the deployment, have every developer on a managed computer do these steps:

1. Sign out of the machine-wide profile, as described in [Sign out of each profile](/kong-harnesses/remove-kong-harnesses/#sign-out-of-each-profile).
   After you remove the build, `logout` can't read the profile to revoke the sign-in.
1. If the developer activated the profile for {{ site.claude_code }} in their user settings, run `kong-harnesses profile cleanup --client claude-code`.
   For details, see [Clean up agent CLI settings](/kong-harnesses/remove-kong-harnesses/#clean-up-agent-cli-settings).

## Unassign the deployment

Unassign the fleet build deployment, so that it doesn't install the build files again after you delete them:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

Unassign the fleet build package in your MDM tool.
For a Microsoft Intune macOS app (PKG), remove assigned groups from both its **Required** and **Available** assignments.

{% endnavtab %}
{% navtab "Linux" %}

Unassign the fleet build deployment script in your configuration management.

{% endnavtab %}
{% navtab "Windows" %}

Unassign the fleet build package or deployment script in your MDM tool.

{% endnavtab %}
{% endnavtabs %}

## Generate the removal plan

Run `kong-harnesses fleet remove` on your administration computer.
Replace these placeholders:

* `BUILD_RECORD`: The path to the build record.
* `POLICY_FILE` (MDM build only): The MDM policy that the computers get now.
  `fleet remove` reads it so that it keeps the changes that you made after the build.
* `MCP_CONFIG_FILE` (`exclusive` build only): The `managed-mcp.json` file that the computers have now.
  `fleet remove` refuses a file that holds none of the gateway servers of the build.
  If you took those servers out of the file, put each one back as the build wrote it.
* `BUILD_ID`: The build ID, used in the name of the output folder.

When policy keys or your own MCP servers remain, pass `--output-dir` with a new or empty folder.

{% navtabs "fleet-remove" %}
{% navtab "File build" %}

```sh
kong-harnesses fleet remove --record 'BUILD_RECORD'
```

For an `exclusive` MCP build, add `--mcp-config 'MCP_CONFIG_FILE' --output-dir fleet-removed-BUILD_ID`.

{% endnavtab %}
{% navtab "MDM build" %}

```sh
kong-harnesses fleet remove --record 'BUILD_RECORD' --policy 'POLICY_FILE' --output-dir fleet-removed-BUILD_ID
```

For an `exclusive` MCP build, add `--mcp-config 'MCP_CONFIG_FILE'`.

{% endnavtab %}
{% endnavtabs %}

`fleet remove` prints:

* For an MDM build, the policy keys that it removed or restored, under `Taken out`, and the action to take on the MDM policy, under `MDM policy`.
* For every build, the updated `managed-mcp.json` file, under `MCP config`, if it wrote one.
* For every build, each file path to delete, under `Remove`.
  A path that ends with `if an earlier build installed it` can be missing on some computers.

## Apply the removal output

Apply each instruction that `kong-harnesses fleet remove` prints:

1. For an MDM build, review the `Taken out` list.
   `fleet remove` reverts or removes each key whose value still matches the value that the build wrote.
   It can't tell whether you set that same value again after the build.
   To keep such a key, add it to the policy again.
1. For an MDM build, update or remove the MDM policy:
   * If `fleet remove` writes a policy under `mdm/`, deploy that policy in place of the existing {{ site.claude_code }} MDM policy.
   * If `fleet remove` prints `Remove the Claude Code policy from your MDM`, remove the {{ site.claude_code }} policy from your MDM tool.
     Remove the policy even when `fleet remove` doesn't write an `mdm/` folder.
1. If `fleet remove` writes `managed-mcp.json` under `root/`, check each kept server definition that changed after the build.
   Remove each one that still points to the gateway.
   Then deploy the updated file in place of the existing `managed-mcp.json`.

Then remove the build files from each managed computer:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

1. Delete every file path listed under `Remove` as an administrator.
   Skip a path that isn't on the computer.
1. Forget the package receipt, so that your MDM tool can install a later package with the same identifier and version.
   Replace `PACKAGE_IDENTIFIER` with the identifier of the package that you deployed:

   ```sh
   sudo pkgutil --forget PACKAGE_IDENTIFIER
   ```

{% endnavtab %}
{% navtab "Linux" %}

Delete every file path listed under `Remove` as an administrator.
Skip a path that isn't on the computer.

{% endnavtab %}
{% navtab "Windows" %}

Delete every file path listed under `Remove` as an administrator.
Skip a path that isn't on the computer.

{% endnavtab %}
{% endnavtabs %}

## Validate

Confirm the removal on a test computer before you finish:

1. Confirm that none of the file paths listed under `Remove` are on the test computer.
   For the target paths, see [Check the build output](/kong-harnesses/roll-out-claude-code-through-mdm/#check-the-build-output).
1. Start {{ site.claude_code }} and run `/status`.
   In `Setting sources`, check only the sources that this removal deleted.
   For the labels of your platform, see [Validate](/kong-harnesses/roll-out-claude-code-through-mdm/#validate).
   * **File build:** If no other `managed-settings.d/` drop-ins remain, confirm that the file build labels are gone.
   * **MDM build:** If you removed the {{ site.claude_code }} policy from your MDM tool, confirm that the MDM build labels are gone.

   Unrelated source labels, remaining drop-ins, and a kept MDM policy still show in `/status`.
   So confirm the removal with the deleted file paths and with the build ID check in the next step.
1. If kong-harnesses is still installed on the test computer, run [`kong-harnesses doctor`](/kong-harnesses/doctor/).
   Replace `PROFILE_NAME` with your profile name:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client claude-code
   ```

   If the profile still exists, confirm that `doctor` doesn't report the removed fleet build ID.
   If `doctor` reports that the profile doesn't exist, rely on the file path and `/status` checks.
