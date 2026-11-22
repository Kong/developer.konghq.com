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
        Keep that build's record file (`kong-harnesses-fleet-BUILD_ID.json`) and, for an MDM build, the MDM policy that your computers get now.
        For a file build or an `exclusive` MCP build, keep the current `managed-settings.json` or `managed-mcp.json` file too.
        For an Anthropic API profile, sign in with `kong-harnesses login --profile PROFILE_NAME` (matching the build record) so `fleet build` can read the gateway's model list.

tldr:
  q: How do I keep a managed {{ site.claude_code }} fleet on tested versions and move it to a new model?
  a: |
    Run `kong-harnesses fleet build` with `--record` and every kept flag, passing `--policy` (or `--no-policy` for a file build without `managed-settings.json`).
    Add `--claude-code-minimum` and `--claude-code-maximum` to pin a version range, or `--model` to move to a new model.
    Keep the earlier AI Model on {{ site.ai_gateway }} until every active session moves over or ends.
---

A [kong-harnesses](/kong-harnesses/) fleet build sets {{ site.claude_code }} managed settings before a developer's first session (see [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/)).
To update them, rebuild with `--record` set to the active build's record file.
For `--delivery mdm`, `fleet build` strips the earlier build's keys from `--policy` before adding the new ones so dropped keys don't stay behind.
For `--delivery file`, the new drop-in (`managed-settings.d/kong-harnesses.json`) replaces the earlier one.

## Prepare rebuild flags and placeholders

Rebuild each platform and policy group from its own active build record (`RECORD_FILE`) into a new or empty folder (`NEW_FOLDER`).

Set the placeholders that are the same on every platform:

* **Profile (`PROFILE_NAME`):** Pass the profile name that `RECORD_FILE` records.
  `fleet build` refuses a record whose profile or platform differs from the rebuild.
* **MCP mode (`MCP_MODE`):** Pass your earlier `--mcp-servers` mode:
  * `exclusive` (also pass your current `managed-mcp.json` with `--mcp-config 'MCP_CONFIG_FILE'`)
  * `allowlist`
  * `any`

  `fleet build` refuses to omit `--mcp-servers` when the profile defines gateway MCP servers or when the earlier build recorded `any` or `exclusive`.
* **File build policy (`POLICY_FILE`):** For a file build, pass the `managed-settings.json` that your computers have now, so `fleet build` checks the combined policy and keeps `ANTHROPIC_CUSTOM_HEADERS`.
  If the computers don't have `managed-settings.json` (also when they have only `managed-settings.d/` files), replace `--policy 'POLICY_FILE'` with `--no-policy`.

Set the platform, executable and delivery for the target operating system:

{% navtabs "fleet-rebuild-platform" %}
{% navtab "macOS" %}

* **Platform and executable:** Pass `--platform macos` and your earlier `--executable` path.
  The installer package installs `/usr/local/bin/kong-harnesses`.
* **Delivery (`DELIVERY`):** Set `DELIVERY` to the delivery of the earlier build, `file` or `mdm`.
  For an MDM build, set `POLICY_FILE` to the MDM policy that your computers get now (`com.anthropic.claudecode.plist`).
* **Output folder (`NEW_FOLDER`):** For example, `fleet-macos-mdm-2`.

{% endnavtab %}
{% navtab "Linux" %}

* **Platform and executable:** Pass `--platform linux` and your earlier `--executable` path.
  The Linux packages install `/usr/bin/kong-harnesses`.
* **Delivery:** Linux builds use file delivery, so the Linux commands omit `--delivery`.
  `fleet build` refuses `--delivery mdm` for Linux, because {{ site.claude_code }} on Linux reads its policy only from managed settings files.
* **Output folder (`NEW_FOLDER`):** For example, `fleet-linux-file-2`.

{% endnavtab %}
{% navtab "Windows" %}

* **Platform and executable:** Pass `--platform windows` and your earlier `--executable` path.
  The MSI installer installs `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`.
* **Delivery (`DELIVERY`):** Set `DELIVERY` to the delivery of the earlier build, `file` or `mdm`.
  For an MDM build, set `POLICY_FILE` to the MDM policy that your computers get now (`Settings.json`).
* **Output folder (`NEW_FOLDER`):** For example, `fleet-windows-mdm-2`.

{% endnavtab %}
{% endnavtabs %}

Omitting an earlier flag can drop its setting or cause `fleet build` to refuse the rebuild.
Repeat every kept flag from the earlier build, or pass its revert flag from [Keep or revert recorded flags](/kong-harnesses/fleet-build-options/#keep-or-revert-recorded-flags).

## Pin the fleet to a range of {{ site.claude_code }} versions

{:.warning}
> **Install a supported version first:** A {{ site.claude_code }} release earlier than `2.1.163` ignores version bounds, and a release earlier than `2.1.285` does not enforce `allowedProviders`.
> Install a tested release of `2.1.285` or later inside your target range on every computer before deploying the build.

Choose `OLDEST_VERSION` and `NEWEST_VERSION` (`2.1.285` or later) from the {{ site.claude_code }} releases that you tested through {{ site.ai_gateway }}, written as three dot-separated numbers like `claude --version`.

Build managed settings that pin the group to that version range:

{% navtabs "fleet-pin-version" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile PROFILE_NAME \
  --platform macos \
  --delivery DELIVERY \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
kong-harnesses fleet build \
  --profile PROFILE_NAME \
  --platform linux \
  --executable /usr/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build `
  --profile PROFILE_NAME `
  --platform windows `
  --delivery DELIVERY `
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' `
  --policy 'POLICY_FILE' `
  --record 'RECORD_FILE' `
  --mcp-servers MCP_MODE `
  --claude-code-minimum OLDEST_VERSION `
  --claude-code-maximum NEWEST_VERSION `
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build to `NEW_FOLDER` and prints the build ID and record path (see [Version range checks](/kong-harnesses/fleet-build-options/#version-range-checks) for rejected ranges).

Deploy `NEW_FOLDER/root` (and `NEW_FOLDER/mdm` for an MDM build) using [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers), and keep the new record file with the policy.

{{ site.claude_code }} enforces the range at startup (a running session continues until the developer restarts it) and on native or npm updates.
For Homebrew and Claude Desktop update controls, see [How version bounds behave](/kong-harnesses/fleet-build-options/#how-version-bounds-behave).

## Move the fleet to a new model

{:.warning}
> **Keep the earlier AI Model active:** A {{ site.claude_code }} session fails when {{ site.ai_gateway }} does not serve its model.
> Do not remove the earlier AI Model until every active session uses the new model or has ended.

### Add the new model and rebuild

Add the new model version to {{ site.ai_gateway }} as an [AI Model](/ai-gateway/entities/ai-model/).
If your managed policy sets `availableModels` or `deniedModels`, verify that those settings permit both models until the move completes.

Build managed settings with `--model NEW_MODEL_ID` and every kept flag from the earlier build, such as your version range:

{% navtabs "fleet-move-model" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile PROFILE_NAME \
  --platform macos \
  --delivery DELIVERY \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  --model NEW_MODEL_ID \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
kong-harnesses fleet build \
  --profile PROFILE_NAME \
  --platform linux \
  --executable /usr/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  --model NEW_MODEL_ID \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build `
  --profile PROFILE_NAME `
  --platform windows `
  --delivery DELIVERY `
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' `
  --policy 'POLICY_FILE' `
  --record 'RECORD_FILE' `
  --mcp-servers MCP_MODE `
  --model NEW_MODEL_ID `
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build to `NEW_FOLDER` and prints the build ID and record path.
Prefix `NEW_MODEL_ID` as `--model FAMILY=NEW_MODEL_ID` if it doesn't name one Claude family, and repeat `--model` for each family.
See [Model overrides](/kong-harnesses/fleet-build-options/#model-overrides) for supported families and how `--model` updates roles and `/cost` rates.

### Pilot on one computer per platform and policy group

Test each platform and policy group's build on one managed computer:

1. Deploy the build to the pilot computer using [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
1. Run `kong-harnesses doctor` and confirm the new build ID, as in [Validate](#validate).
1. Start a new {{ site.claude_code }} session.
1. If the new model isn't selected, select it with `/model` or start with `claude --model NEW_MODEL_ID`.
1. Send a prompt and confirm {{ site.claude_code }} replies.
1. Run `/status` and confirm it shows `NEW_MODEL_ID`.

### Roll out and retire the earlier model

After every pilot passes, finish the rollout:

1. Deploy `NEW_FOLDER/root` (and `NEW_FOLDER/mdm` for an MDM build) to the remaining computers, and keep the new record file with the policy.
1. When your MDM or install tool confirms the new build on every computer, ask developers to restart {{ site.claude_code }}.
1. Tell developers that resuming a saved session can return to its saved model, and ask them to run `claude --resume --model NEW_MODEL_ID` or switch with `/model`.
1. Remove the earlier AI Model from {{ site.ai_gateway }} once every active session uses the new model or has ended.

## Validate

On a managed computer after deploying a build, run [`kong-harnesses doctor`](/kong-harnesses/doctor/):

{% validation custom-command %}
command: kong-harnesses doctor --profile PROFILE_NAME --client claude-code
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Confirm the output reports that your organization's managed settings configure {{ site.claude_code }} and prints the build ID from your last `fleet build` run.
