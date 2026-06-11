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
  a: |
    No. A plugin that isn't associated with any Service, Route, or Consumer is considered global
    and runs on every request, but only within its own workspace. There is no way to set up a
    plugin that's automatically applied to all workspaces.
related_resources: []
---

## Global plugins and workspace scope

A plugin that is not associated with any Service, Route, or Consumer is considered global and runs on every request, within that workspace.

Therefore, you cannot set up a plugin that automatically applies to all workspaces.
