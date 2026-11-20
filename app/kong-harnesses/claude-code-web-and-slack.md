---
title: "{{ site.claude_code }} on the web and Claude in Slack"
description: "Explains why {{ site.claude_code }} on the web, Claude Tag and {{ site.claude_code }} in Slack don't use a {{site.kong_harnesses}} profile or {{site.ai_gateway}}, and how to turn off each of them."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - cli
  - anthropic

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: "{{ site.claude_code }} traffic outside {{site.ai_gateway}}"
    url: /kong-harnesses/claude-code-outside-traffic/
  - text: "Set up {{ site.claude_code }} with {{site.kong_harnesses}}"
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

{{ site.claude_code }} on the web, Claude Tag and the earlier {{ site.claude_code }} in Slack run sessions outside the developer's computer.
Those sessions don't use the {{site.kong_harnesses}} profile, and their model requests don't go through its gateway.
If all model traffic must pass through the gateway, turn off each of these products.

## {{ site.claude_code }} on the web

{{ site.claude_code }} on the web runs cloud sessions on Anthropic's infrastructure, or in your organization's [self-hosted environment](https://code.claude.com/docs/en/self-hosted-environments) when you route them there.
In a self-hosted environment, the conversation still goes to `api.anthropic.com`, and model inference uses the Anthropic API unless you configure the runner to send model requests to Amazon Bedrock or Google Vertex AI.
A developer who signs in with a claude.ai account can also start cloud sessions from the terminal, for example with `claude --cloud "<task>"`, and those sessions don't use the gateway either.
`--cloud` isn't available when {{ site.claude_code }} uses a third-party provider mode, such as Amazon Bedrock.
A profile in the Anthropic API provider mode doesn't count as a third-party provider for this check, so a developer who signs in with `claude auth login` can still use `--cloud`.
When the session also has another credential, {{ site.claude_code }} can check the cloud session policy of that credential's organization, as [Cloud sessions use your claude.ai login](https://code.claude.com/docs/en/errors#cloud-sessions-use-your-claude-ai-login) explains.
The organization setting in the following steps turns these sessions off too.
To turn off cloud sessions for a Team or Enterprise organization:

1. Sign in to claude.ai as an Owner of your organization.
1. Open [**Organization settings** > **Claude Code**](https://claude.ai/admin-settings/claude-code).
1. Turn off cloud sessions, which sets the `allow_remote_sessions` policy to off.

If your Enterprise organization uses custom roles, you can also remove the cloud sessions permission from each role in [**Organization settings** > **Roles**](https://claude.ai/admin-settings/roles).
The cloud sessions permission controls only the sessions on Anthropic's infrastructure, not the sessions in a self-hosted environment.
The organization setting applies only to the accounts of your organization.
[{{ site.claude_code }} on the web](https://code.claude.com/docs/en/claude-code-on-the-web) explains cloud sessions.

## Claude Tag

Claude Tag is the Claude app in Slack for Team and Enterprise organizations.
To turn off Claude Tag for the whole organization, open the [Claude Tag admin settings](https://claude.ai/admin-settings/claude-tag) as an Owner and disable **Enable Claude Tag in Slack**.
The switch also turns off direct messages to Claude.

## {{ site.claude_code }} in Slack

The earlier {{ site.claude_code }} in Slack answers only Pro, Max and Ultra accounts, in a Slack workspace that no organization connected to Claude Tag.
Your organization's Claude settings don't control these personal accounts.
To block the app, a Slack administrator removes the Claude app and stops new installs.

{:.warning}
> Do these steps only when no workspace that they reach is connected to Claude Tag, because Claude Tag uses the same Claude app.
> Removing the app from a connected workspace [deletes that workspace's Claude Tag data](https://claude.com/docs/claude-tag/concepts/data-lifecycle#delete-data-or-request-deletion), and the Enterprise Grid restriction and uninstall change every workspace in the organization.

To see which workspaces are connected, an Owner of your Claude organization opens **Connected workspaces** in [**Claude's access** > **Channels** > **Slack**](https://claude.ai/admin-settings/claude-tag/channels/slack).
An **Enterprise Grid** row with the status **Active** connects every workspace in that Grid, also the workspaces that no one paired on their own.

The administrator can use these steps:

* A Workspace Owner or app manager [removes the Claude app](https://slack.com/help/articles/360003125231-Remove-apps-and-custom-integrations-from-your-workspace) from the workspace.
  Every user in that workspace loses access at once.
* A Workspace Owner [turns on app approval](https://slack.com/help/articles/222386767-Manage-app-approval-for-your-workspace) and restricts the Claude app, so that members can't install it again:
  1. Click **Admin** in the Slack sidebar.
  1. Select **Apps and workflows** to open the Slack Marketplace.
  1. Click **App Management Settings**.
  1. Click **Edit** next to **Require approved apps**.
  1. Select the **Only allow pre-approved apps** checkbox.
  1. Click **Save**.
  1. Click **Browse**.
  1. Search for the Claude app and open its page.
  1. Click **Restrict**.
* On Enterprise Grid, an Org Owner or Org Admin [restricts the Claude app for the organization](https://slack.com/help/articles/360000281563-Manage-apps-in-an-Enterprise-organization) in **Organization settings** > **Integrations** > **Manage Apps** > **Restrict an app**.
  Restricting the app doesn't remove existing installations, so also remove it from each workspace.
* On Enterprise Grid, when the Claude app is installed for the whole organization and some workspaces keep Claude Tag, an Org Owner or Org Admin [removes it from the other workspaces](https://slack.com/help/articles/360000281563-Manage-apps-in-an-Enterprise-organization) with **Remove from a workspace** in **Organization settings** > **Integrations** > **Installed Apps**.
  The app stays in the workspaces that the administrator doesn't select.
* On Enterprise Grid, when the Claude app is installed for the whole organization and no workspace keeps Claude Tag, an Org Owner or Org Admin [uninstalls it from the organization](https://slack.com/help/articles/360000281563-Manage-apps-in-an-Enterprise-organization) in **Organization settings** > **Integrations** > **Installed Apps**.
  That removes the app from all workspaces.

[{{ site.claude_code }} in Slack](https://code.claude.com/docs/en/slack) has the details.
