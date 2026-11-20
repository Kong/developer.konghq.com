---
title: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
content_type: how_to
permalink: /kong-harnesses/maintain-a-claude-code-fleet/
breadcrumbs:
  - /kong-harnesses/

description: Hold every managed computer to a range of {{ site.claude_code }} versions, and move the fleet to a new model version without a failed session.

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
  - text: Proxy AI CLI tools through {{site.ai_gateway}}
    url: /ai-gateway/ai-clis/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/

prereqs:
  skip_product: true
  inline:
    - title: A fleet build
      content: |
        Roll out {{ site.claude_code }} with `kong-harnesses fleet build`, as [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/) describes.
        Keep the record file of that build, `kong-harnesses-fleet-BUILD_ID.json`.
        For a build with `--delivery mdm`, also keep the MDM policy that the computers get now.
        Run the `fleet build` commands on this page on the computer where you made the earlier build.
        Sign in to the same profile with `kong-harnesses login --profile work`, because `fleet build` reads the gateway's model list with your sign-in.

tldr:
  q: How do I keep a managed {{ site.claude_code }} fleet on tested versions and move it to a new model?
  a: |
    Run `kong-harnesses fleet build` again with `--record` set to the record of the current build, with `--policy` set to the current MDM policy for an MDM build, and with every other flag of the earlier build that you keep.
    Add `--claude-code-minimum` and `--claude-code-maximum` to hold the computers to a version range.
    In a provider mode other than the Anthropic API, add `--model` to move the computers to a new model.
    Keep the earlier model on {{site.ai_gateway}} until every session uses the new model.

faqs:
  - q: Why does a fleet get its {{ site.claude_code }} settings through MDM and not from {{site.ai_gateway}}?
    a: |
      {{ site.claude_code }} needs its settings before it sends its first request, because the settings name the gateway address and the credential helper.
      {{site.ai_gateway}} can't send settings to a client that doesn't know the gateway yet.
      The [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability) of Anthropic don't apply to a fleet that kong-harnesses sets up, because the fetch needs a direct connection to Anthropic, and the key from the fleet's credential helper doesn't start it.
      MDM or your install tool puts the managed settings on each computer before the first session, so a developer can't replace the gateway address or the credential helper in their own settings.
---

A fleet build contains the {{ site.claude_code }} settings that every managed computer of your organization gets.
To change those settings, you make a new build with `--record` set to the record of the build that the computers have now.
For a build with `--delivery mdm`, the new build takes the settings of the earlier build out of the policy that you pass with `--policy` before it adds its own, so a value that the new settings drop doesn't stay on the computers.
For a file build, the new drop-in replaces the earlier one.

Repeat in each new build every flag of the earlier build that you keep.
A flag that you leave out removes its setting from the computers.
For a build with `--mcp-servers exclusive`, also pass the `managed-mcp.json` that the computers have now with `--mcp-config`.

The commands on this page are for macOS.
On Linux or Windows, use the `--platform` and `--executable` values of the earlier build.
On Linux, use the file build, because `fleet build` refuses `--delivery mdm` there.
On Windows, the MDM policy is `Settings.json`.
For a file build on computers that also get a `managed-settings.json` from your organization, add `--policy POLICY_FILE` with that file, so that `fleet build` checks the combined policy.

Replace each placeholder with the value for your deployment.
`RECORD_FILE` is the record of the build that the computers have now.
`POLICY_FILE` is the MDM policy that the computers get now, or their `managed-settings.json` for a file build.

## Hold the fleet to a range of {{ site.claude_code }} versions

Pick the oldest and the newest {{ site.claude_code }} versions that you tested through your gateway, in the [provider modes that Kong tests](/ai-gateway/ai-clis/#claude-code-provider-modes).
A {{ site.claude_code }} release from before range support ignores the range, so first install a tested release from the range on every computer.
Give each version as three numbers, as `claude --version` prints them.

Build new managed settings that hold every computer to that range, from the record of the current build.
Set `NEW_FOLDER` to a new or empty folder, such as `fleet-macos-mdm-2` for an MDM build on macOS:

{% navtabs "fleet-range" %}
{% navtab "File build" %}

```sh
kong-harnesses fleet build --profile work \
  --platform macos \
  --executable /usr/local/bin/kong-harnesses \
  --record RECORD_FILE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "MDM build" %}

```sh
kong-harnesses fleet build --profile work \
  --platform macos --delivery mdm \
  --executable /usr/local/bin/kong-harnesses \
  --policy POLICY_FILE \
  --record RECORD_FILE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

{{ site.claude_code }} then refuses to start outside the range, and tells the developer to install a version that your organization approves.
The check runs at startup, so a session that is already running continues until the developer restarts it.
On native and npm installs, background updates and `claude update` skip any version above the newest one, and don't install a version below the oldest one.
A Homebrew install updates through `brew upgrade`, so hold its version with your install tool.

`fleet build` refuses a range that can't hold a computer to it:

* An oldest version from before the first {{ site.claude_code }} release that reads the range.
* A newest version from before the first {{ site.claude_code }} release that keeps every session on the gateway.
* An oldest version later than the newest version.
* A range that no version can meet together with the range in the policy that you pass with `--policy`.
* A newest version in that policy from before the first {{ site.claude_code }} release that keeps every session on the gateway.

Deploy the files in `NEW_FOLDER/root`, and for an MDM build the policy in `NEW_FOLDER/mdm`, the same way as for the first build.
Keep the record in `NEW_FOLDER` with the policy, because the next build needs it.

## Move the fleet to a new model

A session fails when {{site.ai_gateway}} doesn't serve its model, so the gateway serves both model versions until every session uses the new one.

Add the new model version to {{site.ai_gateway}} as an [AI Model](/ai-gateway/entities/ai-model/), and keep the AI Model of the earlier version.

Build new managed settings from the record of the build that the computers have now, into a new or empty `NEW_FOLDER`.
In a provider mode other than the Anthropic API, name the new model ID with `--model`, and repeat the other flags of the earlier build, such as the version range:

{% navtabs "fleet-model" %}
{% navtab "File build" %}

```sh
kong-harnesses fleet build --profile work \
  --platform macos \
  --executable /usr/local/bin/kong-harnesses \
  --record RECORD_FILE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --model NEW_MODEL_ID \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "MDM build" %}

```sh
kong-harnesses fleet build --profile work \
  --platform macos --delivery mdm \
  --executable /usr/local/bin/kong-harnesses \
  --policy POLICY_FILE \
  --record RECORD_FILE \
  --claude-code-minimum OLDEST_VERSION \
  --claude-code-maximum NEWEST_VERSION \
  --model NEW_MODEL_ID \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` finds the Claude family, `opus`, `sonnet`, `haiku` or `fable`, in the model ID.
When the ID names no family or more than one, name the family before it, such as `--model sonnet=NEW_MODEL_ID`.
Repeat `--model` for each family that you move.
The new ID replaces the model of that family in every role that used it, such as subagents, in the managed settings and in the profile that the computers install.
The profile on your computer stays as it is, so repeat `--model` in every later build.
A build without it gives the computers the earlier model again.

In the Anthropic API mode, `fleet build` refuses `--model`, because {{ site.claude_code }} reads the gateway's model list on each computer, and `/model` lists each model in it whose ID contains `claude` or `anthropic`.
Build again without `--model`, so that the managed settings get the gateway's rates for the new model, and a `/model` row for it when its ID contains neither word.

Then finish the move:

1. Deploy the new build to one managed computer first, the same way as for the first build.
   On that computer, check with `kong-harnesses doctor` that it names the new build, as in [Validate](#validate).
   Start a new {{ site.claude_code }} session, choose the new model with `/model` in the Anthropic API mode, and send a prompt.
   Check that the prompt gets an answer, and that `/status` names the new model.
1. Deploy the files in `NEW_FOLDER/root`, and for an MDM build the policy in `NEW_FOLDER/mdm`, to the other computers.
   Keep the record in `NEW_FOLDER` with the policy, because the next build needs it.
1. When your MDM or install tool reports the new build on every computer, ask each developer to restart {{ site.claude_code }}.
   In the Anthropic API mode, also ask them to choose the new model with `/model`.
1. Keep the AI Model of the earlier version until every session that used it has ended, and then remove it from {{site.ai_gateway}}.

## Validate

On a managed computer, after the new build is on it, check the {{ site.claude_code }} setup with `kong-harnesses doctor`:

{% validation custom-command %}
command: kong-harnesses doctor --profile work --client claude-code
expected:
  return_code: 0
render_output: false
{% endvalidation %}

The report says that your organization's managed settings configure {{ site.claude_code }}, and names the fleet build.
Check that it names the build ID that the last `fleet build` printed.
