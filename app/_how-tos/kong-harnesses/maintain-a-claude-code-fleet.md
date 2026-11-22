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

faqs:
  - q: Why does a fleet get its {{ site.claude_code }} settings through MDM instead of {{ site.ai_gateway }}?
    a: |
      {{ site.claude_code }} needs managed settings before its first request, because they set the {{ site.ai_gateway }} address and credential helper.
      {{ site.ai_gateway }} can't send settings to a client that doesn't know the gateway yet.
      Anthropic's [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability) need a direct connection to `api.anthropic.com` and an eligible credential, such as a claude.ai login.
      A key from the fleet's credential helper doesn't trigger that fetch.
      MDM or your install tool places managed settings before the first session, so developers can't override the gateway address or credential helper.
---

A [kong-harnesses](/kong-harnesses/) fleet build sets the {{ site.claude_code }} managed settings for every managed computer.
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

Repeat every flag from the earlier build that you want to keep.
Omitting a flag can remove its setting from managed computers.
`fleet build` refuses a rebuild that omits a recorded choice from the following table without an explicit keep or revert flag:

{% table %}
columns:
  - title: Earlier flag
    key: earlier
  - title: Keep
    key: keep
  - title: Revert
    key: revert
rows:
  - earlier: "`--model`"
    keep: Pass `--model` for each family again.
    revert: Omit the family's `--model` and pass `--profile-models` to restore the profile's model.
  - earlier: "`--claude-code-minimum` or `--claude-code-maximum`"
    keep: Pass each version bound again, or a new version.
    revert: Pass `--claude-code-any-version` in place of any bound you remove.
  - earlier: "`--host-settings merge`"
    keep: Pass `--host-settings merge`.
    revert: Pass `--host-settings ignore` to drop host-app settings from Claude Desktop or an IDE.
  - earlier: "`--wsl inherit` (Windows)"
    keep: Pass `--wsl inherit`.
    revert: Pass `--wsl ignore` to stop WSL from using Windows managed settings.
  - earlier: "`--mcp-url` or `--mcp-command` (`allowlist`)"
    keep: Pass each server flag again.
    revert: Pass `--gateway-mcp-only` to drop unlisted allowlist entries.
{% endtable %}

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
`fleet build` refuses a version range when any of the following applies:

* `--claude-code-minimum` is earlier than `2.1.163`, the first release that reads version bounds.
* `--claude-code-maximum` is earlier than `2.1.285`, the first release that keeps every session on the gateway, in your flags or in the combined policy with `--policy`.
* The minimum version is later than the maximum version, in your flags or in the combined policy with `--policy`.

Deploy `NEW_FOLDER/root` (and `NEW_FOLDER/mdm` for an MDM build) using [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
Keep the new build record file in `NEW_FOLDER` with the policy for future rebuilds.

### How version bounds behave

Version bounds enforce the range at startup and during updates:

* **Startup check:** {{ site.claude_code }} refuses to start outside the range and tells the developer to install an approved version.
  Running sessions continue until restarted.
* **Native and npm installs:** Background updates and `claude update` skip versions newer than `--claude-code-maximum` and don't install versions older than `--claude-code-minimum`.
* **Homebrew:** Updates run through `brew upgrade`, so pin the version with your install tool.
* **Claude Desktop:** The app updates its own bundled {{ site.claude_code }}.
  Deploy a desktop release whose {{ site.claude_code }} version is in range and [turn off automatic updates](https://code.claude.com/docs/en/desktop#device-management-policies) through MDM to keep its Code tab in range.
  The Microsoft Store still updates a desktop app it installed.

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

`fleet build` writes the files to `NEW_FOLDER` and applies `--model` overrides as follows:

* **Family detection:** `fleet build` detects the Claude family (`opus`, `sonnet`, `haiku`, or `fable`) from `NEW_MODEL_ID`.
  If the ID doesn't name a family or names more than one, prefix it as `--model <family>=NEW_MODEL_ID`, for example, `--model sonnet=NEW_MODEL_ID`.
  Repeat `--model` for each family you move.
* **Settings and rates:** `--model` updates that family in every role that used it, such as subagents, in both the managed settings and the machine-wide profile.
  The settings include `/cost` rates for the new model when the profile or {{ site.ai_gateway }} provides a complete set of rates.
* **Local profile unchanged:** Your build computer's profile stays unchanged, so repeat `--model` in every later rebuild.

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
