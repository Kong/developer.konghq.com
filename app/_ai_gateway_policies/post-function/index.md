---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: Pre-Function Policy
    url: /ai-gateway/policies/pre-function/
  - text: Serverless Policies
    url: /ai-gateway/policies/?category=serverless
---

The {{ page.name }} Policy lets you dynamically run Lua code from {{site.ai_gateway}} after other Policies run in each phase.

This Policy is part of a pair of serverless Policies.
If you need to run Lua code before other Policies in each phase, see the [Pre-Function Policy](/ai-gateway/policies/pre-function/).

{% include md/ai-gateway/v2/policies/untrusted-lua.md %}

## Phases

{% include md/ai-gateway/v2/policies/phases.md name=page.name %}

## Passing Lua code to the Policy

{% include md/ai-gateway/v2/policies/passing-lua-code.md name=page.name slug=page.slug %}

## Upvalues

{% include md/ai-gateway/v2/policies/upvalues.md %}

## Sandboxing

The provided Lua environment is sandboxed.

{% include md/ai-gateway/v2/policies/sandbox.md %}
