---
title: Global plugins and workspace scope
content_type: support
description: A global plugin runs on every request within its own workspace only, so it cannot be applied automatically across all workspaces.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Can a \"global\" plugin be applied to all workspaces"
related_resources: []
---

## Global plugins and workspace scope

A plugin which is not associated with any service, route, or consumer is considered global and will be run on every request, within that workspace.

Therefore, it is not possible to set up a plugin that would automatically be applied to all workspaces.
