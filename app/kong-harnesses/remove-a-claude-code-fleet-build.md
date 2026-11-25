---
title: "Remove a {{ site.claude_code }} fleet build with kong-harnesses"
description: Remove a {{ site.claude_code }} fleet build from managed computers by unassigning the deployment, generating a removal plan with kong-harnesses fleet remove, and deleting the build files.
permalink: /kong-harnesses/remove-a-claude-code-fleet-build/

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
  - text: Roll out a {{ site.claude_code }} fleet build with kong-harnesses
    url: /kong-harnesses/roll-out-claude-code-through-mdm/
  - text: Plan a {{ site.claude_code }} fleet build with kong-harnesses
    url: /kong-harnesses/fleet-build-options/
  - text: Troubleshoot a failed rollout
    url: /kong-harnesses/roll-out-claude-code-through-mdm/#troubleshoot-a-failed-rollout
  # TODO: restore when these pages are published
  # - text: Remove kong-harnesses
  #   url: /kong-harnesses/remove-kong-harnesses/
  # - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
  #   url: /kong-harnesses/maintain-a-claude-code-fleet/
---

Removing a {{ site.claude_code }} fleet build takes the managed settings, the machine-wide profile, and the `managed-mcp.json` file that you deployed with [Roll out a {{ site.claude_code }} fleet build with kong-harnesses](/kong-harnesses/roll-out-claude-code-through-mdm/) off your managed computers.
Do the steps in this order, so that your deployment tool doesn't install the files again and developers can still sign out.

## Before you start

You need:

* **kong-harnesses on your administration computer**
  <!-- TODO: link the kong-harnesses install page when it is published (/kong-harnesses/install/). -->
* **The build record of the deployed build.** The record is the `kong-harnesses-fleet-BUILD_ID.json` file that the build wrote to its `--output-dir`.
* **The current MDM policy, for an MDM build.** Export the policy that the managed computers get now.
  For where each platform stores it, see [MDM policy location](/kong-harnesses/fleet-build-options/#mdm-policy-location).
* **The current `managed-mcp.json`, for an `exclusive` MCP build.** Copy the file that the managed computers have now.
* **Access to the tool that deployed the build.** This is your MDM tool, such as Jamf Pro or Microsoft Intune, on macOS and Windows, and your configuration management on Linux.
  You use it to unassign the deployment and, for an MDM build, to update or remove the MDM policy.
* **Administrator rights on the managed computers.** You use them to delete the build files and to validate the removal on a test computer.

## Have developers sign out and clean up

Before you unassign the deployment, have every developer on a managed computer do these steps:

1. Sign out of the machine-wide profile with [`kong-harnesses logout --profile PROFILE_NAME`](/kong-harnesses/logout/).
   Replace `PROFILE_NAME` with your profile name.
   After you remove the build, `logout` can't read the profile to revoke the sign-in.
1. If the developer activated the profile for {{ site.claude_code }} in their user settings, run [`kong-harnesses profile cleanup --client claude-code`](/kong-harnesses/profile/cleanup/).
   The [`profile activate`](/kong-harnesses/profile/activate/) command sets up an agent CLI, such as {{ site.claude_code }}, to use a profile, and `profile cleanup` removes the settings that kong-harnesses added.

## Unassign the deployment

Unassign the fleet build deployment, so that your deployment tool doesn't install the build files again after you delete them.
This table shows what to unassign on each platform:

{% table %}
columns:
  - title: Platform
    key: platform
  - title: What to unassign
    key: unassign
rows:
  - platform: macOS
    unassign: |
      The fleet build package in your MDM tool.
      For a Microsoft Intune macOS app (PKG), remove assigned groups from both its **Required** and **Available** assignments.
  - platform: Linux
    unassign: The fleet build deployment script in your configuration management
  - platform: Windows
    unassign: The fleet build package or deployment script in your MDM tool
{% endtable %}

## Generate the removal plan

`kong-harnesses fleet remove` shows you how to remove a fleet build.
It reads the build record and prints a plan.
It doesn't change any computer, so you apply the plan yourself, as described in [Apply the removal output](#apply-the-removal-output).

<!-- TODO: link the generated `kong-harnesses fleet remove` flag reference here when it is published. -->

Run the command on your administration computer.
The flags to pass depend on how you built your fleet:

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Pass it for
    key: when
  - title: What to pass
    key: value
rows:
  - flag: "`--record 'BUILD_RECORD'`"
    when: Every build
    value: The path to the build record.
  - flag: "`--policy 'POLICY_FILE'`"
    when: MDM builds
    value: |
      The MDM policy that the computers get now.
      The build record holds the policy from the day of the build, so `fleet remove` reads the current policy to keep the changes that you made after the build.
      A file build left your policy as it was, so it refuses this flag.
  - flag: "`--mcp-config 'MCP_CONFIG_FILE'`"
    when: Builds with `--mcp-servers exclusive`
    value: |
      The `managed-mcp.json` file that the computers have now.
      `fleet remove` refuses a file that holds none of the gateway servers of the build.
      If you took those servers out of the file, put each one back as the build wrote it.
  - flag: "`--output-dir fleet-removed-BUILD_ID`"
    when: Policy keys or your own MCP servers remain
    value: |
      A new or empty folder, where `fleet remove` writes the remaining policy and `managed-mcp.json`.
      Replace `BUILD_ID` with the build ID.
{% endtable %}

Use the command for the kind of build that you deployed:

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

## Apply the removal output

`fleet remove` prints up to four sections.
Apply each section that appears.
This table shows when each section appears and what to do with it:

{% table %}
columns:
  - title: Section
    key: section
  - title: When it appears
    key: when
  - title: What to do
    key: action
rows:
  - section: "`Taken out`"
    when: MDM builds
    action: |
      Review the policy keys that `fleet remove` reverted or removed.
      It reverts or removes each key whose value still matches the value that the build wrote, and it can't tell whether you set that same value again after the build.
      To keep such a key, add it to the policy again.
  - section: "`MDM policy`"
    when: MDM builds
    action: |
      If `fleet remove` writes a policy under `mdm/`, deploy that policy in place of the existing {{ site.claude_code }} MDM policy.
      If it prints `Remove the Claude Code policy from your MDM`, remove the {{ site.claude_code }} policy from your MDM tool, even when `fleet remove` doesn't write an `mdm/` folder.
  - section: "`MCP config`"
    when: "`fleet remove` writes `managed-mcp.json` under `root/`"
    action: |
      Check each kept server definition that changed after the build, and remove each one that still points to the gateway.
      Then deploy the updated file in place of the existing `managed-mcp.json`.
  - section: "`Remove`"
    when: Every build
    action: |
      Delete each file path that it lists from the managed computers, as described in [Delete the build files](#delete-the-build-files).
      A path that ends with `if an earlier build installed it` can be missing on some computers.
{% endtable %}

### Delete the build files

Delete every file path that `fleet remove` lists under `Remove` from each managed computer, as an administrator.
Skip a path that isn't on the computer.

On macOS, also forget the package receipt, so that your MDM tool can install a later package with the same identifier and version.
Replace `PACKAGE_IDENTIFIER` with the identifier of the package that you deployed:

```sh
sudo pkgutil --forget PACKAGE_IDENTIFIER
```

## Validate

Confirm the removal on a test computer before you finish:

1. Confirm that none of the file paths listed under `Remove` are on the test computer.
   For the target paths, see [Check the build output](/kong-harnesses/roll-out-claude-code-through-mdm/#check-the-build-output).
1. Start {{ site.claude_code }}, run `/status`, and read the `Setting sources` line.
   Check only the sources that this removal deleted.
   For the labels of your platform, see [Validate](/kong-harnesses/roll-out-claude-code-through-mdm/#validate).
   * **File build:** If no other files remain in `managed-settings.d/`, confirm that the file build labels are gone.
   * **MDM build:** If you removed the {{ site.claude_code }} policy from your MDM tool, confirm that the MDM build labels are gone.

   Unrelated source labels, other files in `managed-settings.d/`, and a kept MDM policy still show in `/status`.
   So confirm the removal with the deleted file paths and with the `doctor` check.
1. If kong-harnesses is still installed on the test computer, run [`kong-harnesses doctor`](/kong-harnesses/doctor/).
   Replace `PROFILE_NAME` with your profile name:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --client claude-code
   ```

   If the profile still exists, confirm that `doctor` doesn't report the removed fleet build ID.
   If `doctor` reports that the profile doesn't exist, rely on the file path and `/status` checks.

If a check fails, see [Troubleshoot a failed rollout](/kong-harnesses/roll-out-claude-code-through-mdm/#troubleshoot-a-failed-rollout).
