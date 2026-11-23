---
title: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
content_type: how_to
permalink: /kong-harnesses/maintain-a-claude-code-fleet/
breadcrumbs:
  - /kong-harnesses/

description: Pin managed {{ site.claude_code }} computers to a tested version range and move a fleet to a new model version without interrupting active sessions.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

automated_tests: false

min_version:
  ai-gateway: '2.4'

entities:
  - ai-model

tags:
  - ai
  - anthropic

related_resources:
  - text: Roll out {{ site.claude_code }} through MDM
    url: /kong-harnesses/roll-out-claude-code-through-mdm/
  - text: "{{ site.claude_code }} fleet build options"
    url: /kong-harnesses/fleet-build-options/
  - text: Remove a {{ site.claude_code }} fleet build
    url: /kong-harnesses/remove-a-claude-code-fleet-build/
  - text: Proxy AI CLI tools through {{ site.ai_gateway }}
    url: /ai-gateway/ai-clis/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: A fleet build
      content: |
        Roll out {{ site.claude_code }} with `kong-harnesses fleet build`, as described in [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).
        Run every `fleet build` command on the computer where you made that build.
        Keep that build's record file (`kong-harnesses-fleet-BUILD_ID.json`).
        For an MDM build, keep the MDM policy that your computers get now.
        For a file build, keep the current `managed-settings.json` if your computers have one.
        For an `exclusive` MCP build, keep the current `managed-mcp.json`.
        For an Anthropic API profile, sign in with `kong-harnesses login --profile PROFILE_NAME` (matching the build record) so `fleet build` can read the gateway's model list.

tldr:
  q: How do I keep a managed {{ site.claude_code }} fleet on tested versions and move it to a new model?
  a: |
    Run `kong-harnesses fleet build` with `--record` set to the record file of the build that your computers have now, and pass every flag of that build again.
    Add `--claude-code-minimum` and `--claude-code-maximum` to pin a version range, or `--model` to move to a new model.
    Test the new build on one computer per platform and policy group before you deploy it to the rest.
    Keep the earlier AI Model on {{ site.ai_gateway }} until every active session moves over or ends.
---

A [kong-harnesses](/kong-harnesses/) fleet build sets the {{ site.claude_code }} managed settings on your managed computers (see [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/)).
To change those settings, rebuild with `--record` set to the record file of the build that your computers have now.
For `--delivery mdm`, `fleet build` uses the record to remove the values that the earlier build added to the MDM policy and to restore the values that it replaced.
It keeps each value that an administrator changed after the earlier build, then adds the new settings.
For `--delivery file`, the new managed settings file (`managed-settings.d/kong-harnesses.json`) replaces the file of the earlier build.

## Prepare the rebuild

Rebuild each platform and policy group separately, from the build that its computers have now.
The commands in this guide use these placeholders:

* **Profile (`PROFILE_NAME`):** The profile name that the record file records.
  `fleet build` refuses a record whose profile or platform differs from the rebuild.
* **Record (`RECORD_FILE`):** The record file of the build that the computers have now.
* **MCP mode (`MCP_MODE`):** The `--mcp-servers` mode of the earlier build: `allowlist`, `any` or `exclusive`.
* **Kept flags (`KEPT_FLAGS`):** Every other flag of the earlier build, such as `--model`, `--claude-code-minimum`, `--claude-code-maximum`, `--host-settings merge`, `--mcp-url`, `--mcp-command`, and `--mcp-config 'MCP_CONFIG_FILE'` for `exclusive`.
  To drop one of these settings, pass its revert flag from [Keep or revert recorded flags](/kong-harnesses/fleet-build-options/#keep-or-revert-recorded-flags) instead.
  If you leave out a kept flag, `fleet build` refuses the rebuild and names the flag.
  For quotes in `--mcp-url` and `--mcp-command` values, see [Allowlist values and quoting](/kong-harnesses/fleet-build-options/#allowlist-values-and-quoting).
* **Output folder (`NEW_FOLDER`):** A new or empty folder for the new build, with no spaces in its name.

To pin the versions and move the model in one update, pass the version bounds and `--model` in one rebuild.
After you deploy a build, its record file and the policy that the computers then get are the `RECORD_FILE` and `POLICY_FILE` for the next rebuild.

Each tab is for the platform of the managed computers.
Set the values for that platform:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

* **Executable:** The commands pass `/usr/local/bin/kong-harnesses`, where the installer package installs kong-harnesses.
  If the earlier build used another `--executable` path, use that path.
* **Delivery (`DELIVERY`):** The delivery of the earlier build, `file` or `mdm`.
* **Policy (`POLICY_FILE`):** The policy that your computers get now:
  * For an MDM build, the MDM policy (`com.anthropic.claudecode.plist`).
  * For a file build, `/Library/Application Support/ClaudeCode/managed-settings.json` from a managed computer.
    If the computers don't have that file (also when they have only `managed-settings.d/` files), replace `--policy 'POLICY_FILE'` with `--no-policy`.

{% endnavtab %}
{% navtab "Linux" %}

* **Executable:** The commands pass `/usr/bin/kong-harnesses`, where the Linux packages install kong-harnesses.
  If the earlier build used another `--executable` path, use that path.
* **Delivery:** Linux builds use file delivery, so the commands omit `--delivery`.
* **Policy (`POLICY_FILE`):** `/etc/claude-code/managed-settings.json` from a managed computer.
  If the computers don't have that file (also when they have only `managed-settings.d/` files), replace `--policy 'POLICY_FILE'` with `--no-policy`.

{% endnavtab %}
{% navtab "Windows" %}

* **Executable:** The commands pass `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`, where the MSI installer installs kong-harnesses.
  If the earlier build used another `--executable` path, use that path.
* **Delivery (`DELIVERY`):** The delivery of the earlier build, `file` or `mdm`.
* **Policy (`POLICY_FILE`):** The policy that your computers get now:
  * For an MDM build, the MDM policy (`Settings.json`).
  * For a file build, `C:\Program Files\ClaudeCode\managed-settings.json` from a managed computer.
    If the computers don't have that file (also when they have only `managed-settings.d\` files), replace `--policy 'POLICY_FILE'` with `--no-policy`.
* **WSL:** If the earlier build used `--wsl inherit`, add it to `KEPT_FLAGS`.

{% endnavtab %}
{% endnavtabs %}

## Pin the fleet to a range of {{ site.claude_code }} versions

{:.warning}
> **Install a supported version first:** A {{ site.claude_code }} release earlier than `2.1.163` ignores version bounds, and a release earlier than `2.1.285` does not keep every session on the gateway.
> Install a tested release of `2.1.285` or later inside your target range on every computer before you deploy the build.

Choose `OLDEST_VERSION` and `NEWEST_VERSION` from the {{ site.claude_code }} releases that you tested through {{ site.ai_gateway }}.
Use `2.1.285` or later for both, in the three-number form that `claude --version` prints.

Build managed settings that pin the group to that version range:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build --profile PROFILE_NAME --platform macos --delivery DELIVERY --executable /usr/local/bin/kong-harnesses --policy 'POLICY_FILE' --record 'RECORD_FILE' --mcp-servers MCP_MODE --claude-code-minimum OLDEST_VERSION --claude-code-maximum NEWEST_VERSION KEPT_FLAGS --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
kong-harnesses fleet build --profile PROFILE_NAME --platform linux --executable /usr/bin/kong-harnesses --policy 'POLICY_FILE' --record 'RECORD_FILE' --mcp-servers MCP_MODE --claude-code-minimum OLDEST_VERSION --claude-code-maximum NEWEST_VERSION KEPT_FLAGS --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build --profile PROFILE_NAME --platform windows --delivery DELIVERY --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy 'POLICY_FILE' --record 'RECORD_FILE' --mcp-servers MCP_MODE --claude-code-minimum OLDEST_VERSION --claude-code-maximum NEWEST_VERSION KEPT_FLAGS --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build to `NEW_FOLDER` and prints the build ID and the record path.
If it refuses the range, see [Version range checks](/kong-harnesses/fleet-build-options/#version-range-checks).

Test the build on one computer per platform and policy group:

1. Deploy the build in `NEW_FOLDER` to the test computer with the steps for your platform in [Deploy to managed computers](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
1. Run `claude --version` and confirm that the version is from `OLDEST_VERSION` to `NEWEST_VERSION`.
1. Run the `doctor` command from [Validate](#validate) and confirm the new build ID.
1. Start a new {{ site.claude_code }} session, send a prompt, and confirm that {{ site.claude_code }} replies.

After each test passes, deploy the same build to the other computers in the group, and keep the new record file with the policy.

{{ site.claude_code }} enforces the range when it starts and when it updates with the native installer or npm.
A running session continues until the developer restarts it.
For Homebrew and Claude Desktop update controls, see [How version bounds behave](/kong-harnesses/fleet-build-options/#how-version-bounds-behave).

## Move the fleet to a new model

{:.warning}
> **Keep the earlier AI Model active:** Do not remove the earlier AI Model until every active session uses the new model or has ended.
> A {{ site.claude_code }} session fails when {{ site.ai_gateway }} does not serve its model.

### Add the new model and rebuild

Add the new model version to {{ site.ai_gateway }} as a separate [AI Model](/ai-gateway/entities/ai-model/).
Set `NEW_MODEL_ID` to the name of the new AI Model, or to the alias that its routing rule accepts.
If the earlier AI Model limits access with `access.acls`, give the new AI Model the same access.
If your managed policy sets `availableModels` or `deniedModels`, confirm that those settings permit both models until the move is complete.

`fleet build` finds the Claude family (`opus`, `sonnet`, `haiku`, or `fable`) from the name in `NEW_MODEL_ID`.
If `NEW_MODEL_ID` doesn't name exactly one family, pass it as `--model FAMILY=NEW_MODEL_ID`, such as `--model sonnet=NEW_MODEL_ID`.
To move more than one family, pass `--model` once for each family.
For how `--model` updates model roles and `/cost` rates, see [Model overrides](/kong-harnesses/fleet-build-options/#model-overrides).

Build managed settings that move the group to `NEW_MODEL_ID`:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build --profile PROFILE_NAME --platform macos --delivery DELIVERY --executable /usr/local/bin/kong-harnesses --policy 'POLICY_FILE' --record 'RECORD_FILE' --mcp-servers MCP_MODE --model NEW_MODEL_ID KEPT_FLAGS --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
kong-harnesses fleet build --profile PROFILE_NAME --platform linux --executable /usr/bin/kong-harnesses --policy 'POLICY_FILE' --record 'RECORD_FILE' --mcp-servers MCP_MODE --model NEW_MODEL_ID KEPT_FLAGS --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build --profile PROFILE_NAME --platform windows --delivery DELIVERY --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy 'POLICY_FILE' --record 'RECORD_FILE' --mcp-servers MCP_MODE --model NEW_MODEL_ID KEPT_FLAGS --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build to `NEW_FOLDER` and prints the build ID and the record path.

### Test the build on one computer per platform and policy group

On one managed computer in each platform and policy group:

1. Deploy the build in `NEW_FOLDER` with the steps for your platform in [Deploy to managed computers](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
1. Run the `doctor` command from [Validate](#validate) and confirm the new build ID.
1. Start a new {{ site.claude_code }} session with `claude`, without `--model`.
1. For each family that you moved, run `/model FAMILY`, such as `/model sonnet`.
   Send a prompt, confirm that {{ site.claude_code }} replies, and run `/status` to confirm that it shows `NEW_MODEL_ID`.

If a test fails, fix the cause and rebuild from the same `RECORD_FILE` and `POLICY_FILE` into another new folder.
Deploy that build to the test computer, and keep only its record file.

### Deploy the build and retire the earlier model

After every test passes, deploy the build to the other computers and retire the earlier AI Model:

1. Deploy the same items that you tested to the other computers, as described in [Deploy to managed computers](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers): the package or files and, for an MDM build, the MDM policy.
   Keep the new record file with the policy.
1. When your MDM or install tool confirms the new build on every computer, ask developers to finish their current task and restart {{ site.claude_code }}.
   New sessions and sessions that they resume with `claude --resume` use the model that the build sets.
1. Ask developers to run `/status` after they restart.
   If it shows the earlier model, ask them to switch with `/model NEW_MODEL_ID`.
1. When every active session uses the new model or has ended, remove the earlier AI Model from {{ site.ai_gateway }}.

## Validate

On a managed computer after you deploy a build, run [`kong-harnesses doctor`](/kong-harnesses/doctor/):

{% validation custom-command %}
command: kong-harnesses doctor --profile PROFILE_NAME --client claude-code
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Confirm that the command exits with code `0`.
Confirm that the output says that your organization's managed settings configure {{ site.claude_code }}, with the build ID that your last `fleet build` printed.
