---
title: kongctl tail audit-logs
description: Tail audit logs.
content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/tail/

related_resources:
  - text: kongctl tail commands
    url: /kongctl/tail/
---

Tail audit logs.


## Command usage

{% include_cached /kongctl/help/tail/audit-logs/index.md %}

### kongctl tail audit-logs listener

Run the original webhook-based tail flow: create a destination,
configure the regional webhook, and stream records received by a local listener.

{% include_cached /kongctl/help/tail/audit-logs/listener.md %}