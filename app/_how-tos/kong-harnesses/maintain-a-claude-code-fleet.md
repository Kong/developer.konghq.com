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
  inline:
    - title: A fleet build
      content: |
        Roll out {{ site.claude_code }} with `kong-harnesses fleet build`, as [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/) describes.
        Keep the record file of that build, `kong-harnesses-fleet-<build>.json`, and the MDM policy that the computers get now.
        Run the commands on this page on the computer where you made the build, signed in with the same profile.

tldr:
  q: How do I keep a managed {{ site.claude_code }} fleet on tested versions and move it to a new model?
  a: |
    Run `kong-harnesses fleet build` again with `--record` set to the record of the current build and `--policy` set to the current MDM policy.
    Add `--claude-code-minimum` and `--claude-code-maximum` to hold the computers to a version range, or `--model` to move them to a new model.
    Keep the earlier model on {{site.ai_gateway}} until every computer has the new build.

faqs:
  - q: Why does a fleet get its {{ site.claude_code }} settings through MDM and not from {{site.ai_gateway}}?
    a: |
      {{ site.claude_code }} needs its settings before it sends its first request, because the settings name the gateway address and the credential helper.
      {{site.ai_gateway}} can't send settings to a client that doesn't know the gateway yet.
      {{ site.claude_code }} also doesn't fetch [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability) from Anthropic in a gateway session, because the fetch needs a direct connection to Anthropic, and a key from a credential helper doesn't start it.
      MDM puts the managed settings on each computer before the first session, and a developer can't change them.
---

A fleet build holds the {{ site.claude_code }} settings that MDM gives every managed computer of your organization.
To change those settings, you make a new build from the record of the build that the computers hold now.
The new build takes the settings of the earlier build out of your policy before it adds its own, so a value that the new settings drop doesn't stay on the computers.

Keep every other flag of the earlier build in each new build.
A flag that you leave out removes its setting from the computers.

## Hold the fleet to a range of {{ site.claude_code }} versions

Pick the oldest and the newest {{ site.claude_code }} versions that you tested through your gateway, in the [provider modes that Kong tests](/ai-gateway/ai-clis/#claude-code-provider-modes).

Build new managed settings that hold every computer to that range, from the record and the policy of the current build.
The output folder must be new or empty:

```sh
kong-harnesses fleet build --profile work \
  --platform macos --delivery mdm \
  --executable /usr/local/bin/kong-harnesses \
  --policy com.anthropic.claudecode.plist \
  --record fleet/kong-harnesses-fleet-<build>.json \
  --claude-code-minimum <oldest-version> \
  --claude-code-maximum <newest-version> \
  --output-dir fleet-2
```

{{ site.claude_code }} then refuses to start outside the range, with a message that names your organization's range, and its updates skip any version above the newest one.
The oldest version also stops an update on the stable channel from installing an older version.

`fleet build` refuses a range that can't hold a computer to it:

* An oldest version from before the first {{ site.claude_code }} release that reads the range.
* A newest version from before the first {{ site.claude_code }} release that keeps every session on the gateway.
* A range that the range in your current policy makes impossible to meet.

Give the new policy and the files in `fleet-2` to MDM, the same way as for the first build.
Keep the new record from `fleet-2` with the policy, because the next build needs it.

## Move the fleet to a new model

A session fails when its model leaves {{site.ai_gateway}}, so the gateway serves both model versions while the computers move.

1. Add the new model version to {{site.ai_gateway}} as an [AI Model](/ai-gateway/entities/ai-model/), and keep the AI Model of the earlier version.
1. Build new managed settings from the record and the policy of the current build.

   In a provider mode other than the Anthropic API, name the new model ID with `--model`, and keep the other flags of the earlier build, such as a version range:

   ```sh
   kong-harnesses fleet build --profile work \
     --platform macos --delivery mdm \
     --executable /usr/local/bin/kong-harnesses \
     --policy com.anthropic.claudecode.plist \
     --record fleet-2/kong-harnesses-fleet-<build>.json \
     --model <new-model-id> \
     --output-dir fleet-3
   ```

   `fleet build` finds the Claude family, `opus`, `sonnet`, `haiku` or `fable`, in the model ID.
   When the ID doesn't name a family, name the family before it, such as `--model sonnet=<new-model-id>`.
   The new ID replaces the model of that family in every role that used it, such as subagents, in the managed settings and in the profile that the computers install.
   The profile on your computer stays as it is.

   In the Anthropic API mode, build again without `--model`.
   `fleet build` reads the models from the gateway's model list, and refuses `--model` in this mode.
1. Give the new policy and the files to MDM.
1. When every computer has the new build, remove the AI Model of the earlier version from {{site.ai_gateway}}.

## Validate

On a managed computer, after MDM delivers the new build, check the {{ site.claude_code }} setup:

```sh
kong-harnesses doctor --profile work --client claude-code
```

The report says that your organization's managed settings configure {{ site.claude_code }}, and names the fleet build.
Check that it names the build ID that the last `fleet build` printed.

{% validation custom-command %}
command: kong-harnesses doctor --profile work --client claude-code
expected:
  return_code: 0
render_output: false
{% endvalidation %}
