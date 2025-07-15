---
title: deck gateway reset
description: Delete all entities in {{ site.base_gateway }}.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/gateway/

related_resources:
  - text: About decK
    url: /deck/
  - text: deck gateway commands
    url: /deck/gateway/
---

The `deck gateway reset` command deletes all entities in the target control plane.

{:.danger}
> **The reset command is destructive and cannot be undone.**

## Command Usage

{% include_cached deck/help/gateway/reset.md %}