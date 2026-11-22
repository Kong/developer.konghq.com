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
        Keep that build's record file (`kong-harnesses-fleet-BUILD_ID.json`) and, for an MDM build, the MDM policy on your computers.
        If your profile uses the Anthropic API provider, sign in with `kong-harnesses login --profile work` so `fleet build` can read the gateway's model list.

tldr:
  q: How do I keep a managed {{ site.claude_code }} fleet on tested versions and move it to a new model?
  a: |
    Run `kong-harnesses fleet build` with `--record`, `--policy` (or `--no-policy`), and every kept flag from the earlier build.
    Add `--claude-code-minimum` and `--claude-code-maximum` to pin a version range, or `--model` to move to a new model.
    Keep the earlier AI Model on {{ site.ai_gateway }} until every active session moves over or ends.
---

A [kong-harnesses](/kong-harnesses/) fleet build sets the {{ site.claude_code }} managed settings that MDM or your install tool deploys before a developer's first session, as described in [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).
To change them, rebuild with `--record` set to the active build's record file.
For `--delivery mdm`, `fleet build` strips the earlier build's keys from `--policy` before adding the new ones so dropped keys don't stay behind.
For `--delivery file`, the new drop-in (`managed-settings.d/kong-harnesses.json`) replaces the earlier one.

## Prepare rebuild flags and placeholders

Rebuild each platform and policy group from its own active build record (`RECORD_FILE`) into a separate new or empty folder (`NEW_FOLDER`, for example, `fleet-macos-mdm-2`).

* **Platform and executable:** The commands in this guide target macOS (`/usr/local/bin/kong-harnesses`).
  On Linux or Windows, pass your earlier build's `--platform` and `--executable`.
  On Linux, use `--delivery file` (default), because `fleet build` refuses `--delivery mdm`.
* **Policy (`POLICY_FILE`):** Pass your current MDM policy (`com.anthropic.claudecode.plist` on macOS or `Settings.json` on Windows) for an MDM build, or `managed-settings.json` for a file build so `fleet build` checks the combined policy and keeps its custom headers (`ANTHROPIC_CUSTOM_HEADERS`).
  If computers don't have your own {{ site.claude_code }} policy, replace `--policy 'POLICY_FILE'` with `--no-policy`.
* **MCP mode (`MCP_MODE`):** Pass your earlier `--mcp-servers` value: `exclusive`, `allowlist`, or `any`.
  `fleet build` refuses a profile with gateway MCP servers if you omit `--mcp-servers`.
  For `exclusive`, also pass your current `managed-mcp.json` with `--mcp-config`.

Omitting an earlier flag can remove its setting or cause `fleet build` to refuse the rebuild.
Repeat every flag you want to keep from the earlier build, or pass its revert flag from [Keep or revert recorded flags](/kong-harnesses/fleet-build-options/#keep-or-revert-recorded-flags).

To remove a fleet build completely, follow the cleanup steps in [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).

## Pin the fleet to a range of {{ site.claude_code }} versions

Pinning a version range keeps managed computers on {{ site.claude_code }} releases tested through {{ site.ai_gateway }}.

{:.warning}
> **Install a supported version first:** A {{ site.claude_code }} release earlier than `2.1.163` ignores version bounds.
> Install a tested release inside your target range on every computer before deploying the build.

Choose the oldest (`OLDEST_VERSION`) and newest (`NEWEST_VERSION`) {{ site.claude_code }} versions tested through {{ site.ai_gateway }} in the [provider modes that Kong tests](/ai-gateway/ai-clis/#claude-code-provider-modes).
Write each version as three dot-separated numbers, as `claude --version` prints it.

Build managed settings that pin the group to that range:

{% navtabs "fleet-range" %}
{% navtab "File build" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "MDM build" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --delivery mdm \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the files to `NEW_FOLDER` and prints the build ID and record path.
For the version checks that `fleet build` runs on your flags and combined policy, see [Version range checks](/kong-harnesses/fleet-build-options/#version-range-checks).

Deploy `NEW_FOLDER/root` (and `NEW_FOLDER/mdm` for an MDM build) using [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
Keep the new build record file in `NEW_FOLDER` with the policy for future rebuilds.

{{ site.claude_code }} enforces the range at startup (a running session continues until the developer restarts it) and during native or npm updates.
For Homebrew and Claude Desktop update controls, see [How version bounds behave](/kong-harnesses/fleet-build-options/#how-version-bounds-behave).

## Move the fleet to a new model

Moving a fleet to a new model requires serving both model versions on {{ site.ai_gateway }} until active sessions finish or switch over.

{:.warning}
> **Keep the earlier AI Model active:** A {{ site.claude_code }} session fails when {{ site.ai_gateway }} does not serve its model.
> Do not remove the earlier AI Model until every active session uses the new model or has ended.

### Add the new model and rebuild

Add the new model version to {{ site.ai_gateway }} as an [AI Model](/ai-gateway/entities/ai-model/), keeping the earlier AI Model active.

Build managed settings with `--model NEW_MODEL_ID` and every kept flag from the earlier build, such as your version range:

{% navtabs "fleet-model" %}
{% navtab "File build" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --model NEW_MODEL_ID \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "MDM build" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --delivery mdm \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  --mcp-servers MCP_MODE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --model NEW_MODEL_ID \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the files to `NEW_FOLDER` and prints the build ID and record path.
If `NEW_MODEL_ID` doesn't name a single Claude family, prefix it as `--model FAMILY=NEW_MODEL_ID`, and repeat `--model` for each family you move.
See [Model overrides](/kong-harnesses/fleet-build-options/#model-overrides) for supported families and how `--model` updates roles and `/cost` rates.

### Pilot on one computer per platform

Test each platform's build on one managed computer before rolling it out:

1. Deploy the platform's build to the pilot computer using [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
1. Run `kong-harnesses doctor` on the pilot computer and confirm the new build ID, as in [Validate](#validate).
1. Start a new {{ site.claude_code }} session.
1. If the new model isn't selected, select it with `/model` or start with `claude --model NEW_MODEL_ID`.
1. Send a prompt and confirm {{ site.claude_code }} replies.
1. Run `/status` and confirm it shows `NEW_MODEL_ID`.

### Roll out and retire the earlier model

After every platform pilot passes, finish the rollout:

1. Deploy `NEW_FOLDER/root` (and `NEW_FOLDER/mdm` for an MDM build) to the remaining computers, and keep the new record file with the policy.
1. When your MDM or install tool confirms the new build on every computer, ask developers to restart {{ site.claude_code }}.
1. Before removing the earlier AI Model, tell developers that resuming a saved session can return to its saved model.
   Ask them to resume saved sessions with `claude --resume --model NEW_MODEL_ID` or switch with `/model` after resuming.
1. Remove the earlier AI Model from {{ site.ai_gateway }} once every active session uses the new model or has ended.

## Validate

On a managed computer after deploying a new build, check the {{ site.claude_code }} setup with [`kong-harnesses doctor`](/kong-harnesses/doctor/):

{% validation custom-command %}
command: kong-harnesses doctor --profile work --client claude-code
expected:
  return_code: 0
render_output: false
{% endvalidation %}

Confirm the output reports that your organization's managed settings configure {{ site.claude_code }} and prints the build ID from your last `fleet build` run.
