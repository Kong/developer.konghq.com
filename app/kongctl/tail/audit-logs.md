---
title: kongctl tail audit-logs
description: Follow organization audit logs.
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/tail/

related_resources:
  - text: kongctl tail commands
    url: /kongctl/tail/
  - text: Manage audit logs with kongctl
    url: /kongctl/audit-logs/
---

Follow organization audit logs. To stream events from a webhook listener, use
`kongctl tail audit-logs listener`.


## Command usage

{% include_cached /kongctl/help/tail/audit-logs/index.md %}

### kongctl tail audit-logs listener

Run the original webhook-based tail flow: create a destination,
configure the regional webhook, and stream records received by a local listener.

{% include_cached /kongctl/help/tail/audit-logs/listener.md %}