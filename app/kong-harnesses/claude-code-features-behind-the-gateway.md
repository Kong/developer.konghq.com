---
title: "{{ site.claude_code }} features behind the gateway"
description: "Lists the {{ site.claude_code }} features that behave differently when a {{site.kong_harnesses}} profile routes the session through {{site.ai_gateway}}, why they change, and what you can do."
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
  - text: "Set up {{ site.claude_code }} with {{site.kong_harnesses}}"
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: "{{ site.claude_code }} traffic outside {{site.ai_gateway}}"
    url: /kong-harnesses/claude-code-outside-traffic/
  - text: "{{site.kong_harnesses}} profile file"
    url: /kong-harnesses/profile-file/
---

Some {{ site.claude_code }} features need a claude.ai or Anthropic Console account, send data to Anthropic, or behave differently with gateway models.
To inspect the {{ site.claude_code }} choices in a profile, run `kong-harnesses profile get PROFILE_NAME`.

## Features that change

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Why it changes
    key: why
  - title: What you can do
    key: recover
rows:
  - feature: Cost warnings
    why: They report Anthropic API spend, and a gateway session doesn't incur Anthropic API spend.
    recover: Nothing to do.
  - feature: "`/cost` prices"
    why: "{{ site.claude_code }} prices each model at Anthropic's prices, not at your gateway's prices."
    recover: >-
      If the profile or the gateway states prices, `profile activate` asks to install them.
      The install needs administrator rights, and works only on macOS and Linux.
      A model without a stated price keeps the price that {{ site.claude_code }} uses by default.
  - feature: WebSearch on some models
    why: >-
      Some models cannot search the web, but answer as if they did.
      When the gateway or the profile names such a model, WebSearch says that no search ran.
    recover: Switch to a Claude model with `/model` when you need a web search.
{% endtable %}

## Features that depend on the profile and route

The profile and the {{site.ai_gateway}} route decide whether the advisor tool and tool search of {{ site.claude_code }} are on.
The Artifact tool works only in the cases that [Artifacts](/kong-harnesses/claude-code-outside-traffic/#artifacts) lists.

## Features that {{ site.claude_code }} hides

{{ site.claude_code }} hides `/usage-credits`, organization memory sync and Remote Control, because they need a claude.ai sign-in or a direct connection to Anthropic.

## Features that contact other hosts

A profile also controls features that contact Anthropic or other hosts outside the gateway, such as claude.ai connectors, fast mode, usage metrics and automatic updates.
[{{ site.claude_code }} traffic outside {{site.ai_gateway}}](/kong-harnesses/claude-code-outside-traffic/) lists them.
[{{ site.claude_code }} on the web and Claude in Slack](/kong-harnesses/claude-code-web-and-slack/) covers the Claude products that run sessions outside the developer's computer.
