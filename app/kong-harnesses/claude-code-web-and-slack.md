---
title: "{{ site.claude_code }} on the web and Claude in Slack"
description: "Explains why {{ site.claude_code }} on the web and Claude Tag don't use a {{site.kong_harnesses}} profile or {{site.ai_gateway}}, and how to turn off each of them."
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

{{ site.claude_code }} on the web and Claude Tag (the Claude app in Slack) run sessions outside the developer's computer.
Those sessions don't use the {{site.kong_harnesses}} profile, so their model requests don't go through {{site.ai_gateway}}.
When all model traffic must pass through the gateway, turn off both products.

{% table %}
columns:
  - title: Product
    key: product
  - title: Who turns it off
    key: who
  - title: Where
    key: where
rows:
  - product: "[{{ site.claude_code }} on the web](#claude-code-on-the-web)"
    who: "Claude organization Owner"
    where: "[**Organization settings** > **Claude Code**](https://claude.ai/admin-settings/claude-code)"
  - product: "[Claude Tag](#claude-tag)"
    who: "Claude organization Owner"
    where: "[Claude Tag admin settings](https://claude.ai/admin-settings/claude-tag)"
{% endtable %}

## {{ site.claude_code }} on the web

Cloud sessions run on Anthropic's infrastructure, or in a [self-hosted environment](https://code.claude.com/docs/en/self-hosted-environments), where the conversation still goes to `api.anthropic.com`.
A developer who signs in with a claude.ai account can also start a cloud session from the terminal with `claude --cloud`, also with a profile in the Anthropic API provider mode.

To turn off cloud sessions for a Team or Enterprise organization, an Owner opens [**Organization settings** > **Claude Code**](https://claude.ai/admin-settings/claude-code) and turns off cloud sessions.
The setting (the `allow_remote_sessions` policy) turns off the `--cloud` sessions of the accounts in your organization too.
With custom roles, you can instead remove the cloud sessions permission from each role in [**Organization settings** > **Roles**](https://claude.ai/admin-settings/roles).
The permission covers only the sessions on Anthropic's infrastructure, not the sessions in a self-hosted environment.

[{{ site.claude_code }} on the web](https://code.claude.com/docs/en/claude-code-on-the-web) explains cloud sessions.

## Claude Tag

Claude Tag is the Claude app in Slack for Team and Enterprise organizations.
To turn it off for the whole organization, an Owner disables **Enable Claude Tag in Slack** in the [Claude Tag admin settings](https://claude.ai/admin-settings/claude-tag).
The switch also turns off direct messages to Claude.

## {{ site.claude_code }} in Slack

Anthropic has retired the earlier {{ site.claude_code }} in Slack.
In a workspace that isn't connected to Claude Tag, `@Claude` only replies that the workspace isn't set up for Claude Tag.
Personal Pro, Max and Ultra accounts can't use Claude Tag, so the earlier app has no replacement there.
[{{ site.claude_code }} in Slack](https://code.claude.com/docs/en/slack) has the details.
