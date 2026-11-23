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
  - text: Troubleshoot a {{ site.claude_code }} fleet
    url: /kong-harnesses/troubleshooting/claude-code-fleet/
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
        Keep the command that made that build, its record file (`kong-harnesses-fleet-BUILD_ID.json`), and its package or files.
        For an MDM build, keep the MDM policy that your computers get now.
        For a file build, keep the current `managed-settings.json` if your computers have one.
        For an `exclusive` MCP build, keep the current `managed-mcp.json`.
        If the profile uses the Anthropic API provider, sign in with `kong-harnesses login --profile` and the profile name that the record file names, so `fleet build` can read the gateway's model list.

tldr:
  q: How do I keep a managed {{ site.claude_code }} fleet on tested versions and move it to a new model?
  a: |
    Run `kong-harnesses fleet build` with `--record` set to the record file of the build that your computers have now.
    Set new version bounds, add `--model` for each family that you move, or do both, and keep the other choices of the earlier build.
    Test the new build on one computer in each policy group before you deploy it to the rest.
    Keep the earlier AI Model on {{ site.ai_gateway }} until every policy group has the new build and no client sends requests to the earlier model.
---

A [kong-harnesses](/kong-harnesses/) fleet build sets the {{ site.claude_code }} managed settings on your managed computers (see [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/)).
To change those settings, rebuild with `--record` set to the record file of the build that your computers have now.
For `--delivery mdm`, `fleet build` uses the record to remove the values that the earlier build added to the MDM policy and to restore the values that it replaced.
It keeps each value that an administrator changed to a different value after the earlier build, unless the new build sets that value too.
For `--delivery file`, the new managed settings file (`managed-settings.d/kong-harnesses.json`) replaces the file of the earlier build.

## Choose the change

Each rebuild can pin a version range, move to a new model, or do both.
Prepare the change that you need.

### Pin a version range

{:.warning}
> **Check the current range before you install a release:** {{ site.claude_code }} refuses to start when its release is outside the range that applies.
> If the range in the current policy does not permit a release in the new range, install that release on each computer in the same maintenance window as the new build.

Choose `OLDEST_VERSION` and `NEWEST_VERSION` from the {{ site.claude_code }} releases that you tested through {{ site.ai_gateway }}:

* Use `2.1.285` or later for both bounds, in the three-number form that `claude --version` prints.
  A release earlier than `2.1.163` ignores version bounds, and a release earlier than `2.1.285` does not keep every session on the gateway.
* {{ site.claude_code }} can update to any release inside the range, so test the releases between the bounds too.
  To pin one release, use the same version for both bounds.
* For how each install method updates inside the range, and the extra steps for Homebrew and Claude Desktop, see [How version bounds behave](/kong-harnesses/fleet-build-options/#how-version-bounds-behave).

### Move to a new model

{:.warning}
> **Keep the earlier AI Model active:** Do not remove the earlier AI Model until every policy group has the new build and no client sends requests to the earlier model.
> A {{ site.claude_code }} session fails when {{ site.ai_gateway }} does not serve its model.

Prepare the new model:

1. Add the new model version to {{ site.ai_gateway }} as a separate [AI Model](/ai-gateway/entities/ai-model/), with the same `formats` and `capabilities` as the earlier AI Model.
1. Give the new AI Model the same `access` settings as the earlier AI Model, including its `access.auth_strategies` and `access.acls`.
1. Attach the same [AI Policies](/ai-gateway/entities/ai-model/#attach-ai-policies) as the earlier AI Model, such as guardrails and rate limits.
1. Set `NEW_MODEL_ID` to the name of the new AI Model.
   If the new AI Model has a [routing rule](/ai-gateway/entities/ai-model/#request-routing-rules) (`config.route.model`), use `body_param: model` and set `NEW_MODEL_ID` to the value that the rule accepts.
1. If your managed policy sets `availableModels` or `deniedModels`, confirm that those settings permit both models until the move is complete.
1. Check the earliest {{ site.claude_code }} release that supports the new model in [Model configuration](https://code.claude.com/docs/en/model-config).
   If the computers can run an earlier release, also [pin a version range](#pin-a-version-range) whose `OLDEST_VERSION` is that release or later, in the same rebuild.

## Build the managed settings

Rebuild each policy group separately, from the build that its computers have now.
A policy group is a set of computers with the same platform, delivery, deployed build, and policy.
For an `exclusive` MCP build, the computers in a policy group also have the same `managed-mcp.json`.

The commands use these placeholders:

* **Record (`RECORD_FILE`):** The record file of the build that the computers have now.
* **Profile (`PROFILE_NAME`):** The `name` value in `RECORD_FILE`.
  `fleet build` reads this profile as the build computer holds it now, not as the earlier build held it, so check the profile before you rebuild.
  `fleet build` refuses a record whose profile or platform differs from the rebuild.
* **MCP mode (`MCP_MODE`):** The `mcp_mode` value in `RECORD_FILE`: `allowlist`, `any`, or `exclusive`.
* **Change (`CHANGE_FLAGS`):** The change that you prepared:
  * To pin a version range, `--claude-code-minimum OLDEST_VERSION --claude-code-maximum NEWEST_VERSION`.
  * To move to a new model, `--model 'FAMILY=NEW_MODEL_ID'` for each family that you move, where `FAMILY` is `opus`, `sonnet`, `haiku`, or `fable`.
    Always name the family, because `fleet build` otherwise guesses it from the letters in `NEW_MODEL_ID`.
    For how `--model` updates model roles and `/cost` rates, see [Model overrides](/kong-harnesses/fleet-build-options/#model-overrides).
  * To do both, both sets of flags.
* **Kept flags (`KEPT_FLAGS`):** The choices of the earlier build that you keep, copied from the command that made that build:
  * The earlier `--claude-code-minimum` and `--claude-code-maximum`, if `CHANGE_FLAGS` doesn't set new bounds.
  * For each family in the `models` value of `RECORD_FILE` that `CHANGE_FLAGS` doesn't move, `--model 'FAMILY=MODEL_ID'` with that family and its model ID.
  * `--host-settings merge`, `--mcp-url`, and `--mcp-command`, if the earlier build used them.
    For quotes in `--mcp-url` and `--mcp-command` values, see [Allowlist values and quoting](/kong-harnesses/fleet-build-options/#allowlist-values-and-quoting).
  * For `exclusive`, `--mcp-config 'MCP_CONFIG_FILE'`, also when the earlier build didn't use `--mcp-config`.

  Don't copy a revert flag (`--claude-code-any-version`, `--profile-models`, or `--gateway-mcp-only`) from the earlier command.
  If you leave out a kept choice, `fleet build` refuses the rebuild and names the flag.
  To drop a choice instead, pass its revert flag from [Keep or revert recorded flags](/kong-harnesses/fleet-build-options/#keep-or-revert-recorded-flags).
  If no kept flags remain, delete the `KEPT_FLAGS` line.
* **Output folder (`NEW_FOLDER`):** A new or empty folder for the new build, without spaces in its name.

Each tab is for the platform of the managed computers.
Use the line break syntax of the shell on the build computer.

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

Set the values for macOS:

* **Executable:** The command passes `/usr/local/bin/kong-harnesses`, where the installer package installs kong-harnesses.
  If the earlier build used another `--executable` path, copy that argument with its quotes.
* **Delivery (`DELIVERY`):** The `delivery` value in `RECORD_FILE`, `file` or `mdm`.
* **Policy (`POLICY_FILE`):** The policy that your computers get now:
  * For an MDM build, the MDM policy (`com.anthropic.claudecode.plist`).
  * For a file build, `/Library/Application Support/ClaudeCode/managed-settings.json` from a managed computer.
    If the computers don't have that file (also when they have only `managed-settings.d/` files), replace `--policy 'POLICY_FILE'` with `--no-policy`.
* **MCP configuration (`MCP_CONFIG_FILE`):** For an `exclusive` build, `/Library/Application Support/ClaudeCode/managed-mcp.json` from a managed computer.
  Pass it in `KEPT_FLAGS` as `--mcp-config 'MCP_CONFIG_FILE'`.

```sh
kong-harnesses fleet build \
  --profile PROFILE_NAME \
  --platform macos \
  --delivery DELIVERY \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  CHANGE_FLAGS \
  KEPT_FLAGS \
  --output-dir NEW_FOLDER
```

When you build the package from `NEW_FOLDER`, keep the package identifier of the installed fleet package and set a later package version.

{% endnavtab %}
{% navtab "Linux" %}

Set the values for Linux:

* **Executable:** The command passes `/usr/bin/kong-harnesses`, where the Linux packages install kong-harnesses.
  If the earlier build used another `--executable` path, copy that argument with its quotes.
* **Delivery:** Linux builds use file delivery, so the command omits `--delivery`.
* **Policy (`POLICY_FILE`):** `/etc/claude-code/managed-settings.json` from a managed computer.
  If the computers don't have that file (also when they have only `managed-settings.d/` files), replace `--policy 'POLICY_FILE'` with `--no-policy`.
* **MCP configuration (`MCP_CONFIG_FILE`):** For an `exclusive` build, `/etc/claude-code/managed-mcp.json` from a managed computer.
  Pass it in `KEPT_FLAGS` as `--mcp-config 'MCP_CONFIG_FILE'`.

```sh
kong-harnesses fleet build \
  --profile PROFILE_NAME \
  --platform linux \
  --executable /usr/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  CHANGE_FLAGS \
  KEPT_FLAGS \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Windows" %}

Set the values for Windows:

* **Executable:** The command passes `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`, where the MSI installer installs kong-harnesses.
  If the earlier build used another `--executable` path, copy that argument with its quotes.
* **Delivery (`DELIVERY`):** The `delivery` value in `RECORD_FILE`, `file` or `mdm`.
* **Policy (`POLICY_FILE`):** The policy that your computers get now:
  * For an MDM build, the MDM policy (`Settings.json`).
  * For a file build, `C:\Program Files\ClaudeCode\managed-settings.json` from a managed computer.
    If the computers don't have that file (also when they have only `managed-settings.d\` files), replace `--policy 'POLICY_FILE'` with `--no-policy`.
* **MCP configuration (`MCP_CONFIG_FILE`):** For an `exclusive` build, `C:\Program Files\ClaudeCode\managed-mcp.json` from a managed computer.
  Pass it in `KEPT_FLAGS` as `--mcp-config 'MCP_CONFIG_FILE'`.
* **WSL:** If the earlier build used `--wsl inherit`, add it to `KEPT_FLAGS`.

```powershell
kong-harnesses fleet build `
  --profile PROFILE_NAME `
  --platform windows `
  --delivery DELIVERY `
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' `
  --policy 'POLICY_FILE' `
  --record 'RECORD_FILE' `
  --mcp-servers MCP_MODE `
  CHANGE_FLAGS `
  KEPT_FLAGS `
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build to `NEW_FOLDER` and prints the build ID and the record path.
If it refuses the version range, see [Version range checks](/kong-harnesses/fleet-build-options/#version-range-checks).

For an MDM build, the `Earlier build` line of the output names each setting that `fleet build` removed from the MDM policy or restored.
If you set one of those settings yourself to the same value as the earlier build, and the new build doesn't set it, set it again in the new MDM policy in `NEW_FOLDER` before you test the build.

## Test the build on one computer per policy group

Test the new build on one managed computer in each policy group:

1. Run `claude --version` and note the {{ site.claude_code }} release, so you can put it back if a test fails.
1. If you move a model, start a session with `claude -n TEST_SESSION`, where `TEST_SESSION` is a name that you haven't used on this computer.
   Run `/model FAMILY` for one family that you move, such as `/model sonnet`, and run `/status` to confirm that it shows the earlier model.
   Send a prompt, and leave the session open.
1. If you pin a version range, install a release from `OLDEST_VERSION` to `NEWEST_VERSION`, and run `claude --version` to confirm it.
1. Deploy only the build in `NEW_FOLDER` to the test computer: the package or files and, for an MDM build, the MDM policy.
   Use the steps for your platform in [Deploy to managed computers](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
   For an MDM build, assign the new MDM policy only to the test computer, and keep the earlier policy on the other computers.
1. Run the `doctor` command from [Validate](#validate) and confirm the new build ID.
1. If you move a model, send another prompt in the open session and confirm that {{ site.claude_code }} replies.
   Exit the session, resume it with `claude --resume TEST_SESSION`, and run `/status` to confirm that it no longer shows the earlier model.
   Send a prompt and confirm that {{ site.claude_code }} replies.
1. Start a new {{ site.claude_code }} session with `claude`, send a prompt, and confirm that {{ site.claude_code }} replies.
1. If you move a model, for each family that you moved, run `/model FAMILY`.
   Send a prompt, confirm that {{ site.claude_code }} replies, and run `/status` to confirm that it shows `NEW_MODEL_ID`.
   In the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger), filter by **Model** and confirm that the new upstream model served the request.

If a test fails, put the test computer back on the earlier build:

1. Deploy the package or files of the earlier build and, for an MDM build, the earlier MDM policy.
1. If you installed a different {{ site.claude_code }} release, install the release that you noted again.
1. Fix the cause with [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/), then rebuild into another new folder with the same `RECORD_FILE`, `POLICY_FILE`, and, for `exclusive`, `MCP_CONFIG_FILE`.
   Don't copy these files from the test computer, because it had the failed build.
1. Test the new build, then delete the folder of the failed build, which holds its record file.

## Deploy the build to the other computers

After every test passes:

1. Deploy the same package or files and, for an MDM build, the same MDM policy to the other computers in the group, as described in [Deploy to managed computers](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
   If you pin a version range, install a release from `OLDEST_VERSION` to `NEWEST_VERSION` on each computer whose release is outside that range, in the same maintenance window as the deploy to that computer.
1. Keep the new record file with the policy, and keep the command that made this build.
   For the next rebuild, the new record file is `RECORD_FILE`, this command gives `KEPT_FLAGS`, and the policy that the computers then get is `POLICY_FILE`.
1. When your MDM or install tool confirms the new build on every computer, ask developers to finish their current task and restart {{ site.claude_code }}.
   A running session keeps its release and model until the developer restarts it.
   New sessions and sessions that developers resume with `claude --resume` use the model that the build sets.
1. If you move a model, ask developers to run `/status` after they restart.
   If it shows the earlier model, ask them to run `/model FAMILY` with the family of that model, such as `/model sonnet`.
1. If you move a model, wait until every policy group has the new build.
   Remove the earlier AI Model from {{ site.ai_gateway }} only when the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger), filtered by **Model**, shows no new requests for the earlier model.

## Validate

On a managed computer after you deploy a build, run [`kong-harnesses doctor`](/kong-harnesses/doctor/):

{% validation custom-command %}
command: kong-harnesses doctor --profile PROFILE_NAME --client claude-code
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Confirm that the command exits with code `0`.
Confirm that the output says that your organization's managed settings configure {{ site.claude_code }}, with the build ID of the build that you deployed to this computer.
