---
title: kongctl get audit-logs
description: "Pull organization audit logs and inspect audit-log configuration."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
  - text: Manage audit logs with kongctl
    url: /kongctl/audit-logs/
---

Pull organization audit logs or inspect webhook destinations and configuration.

## Command usage

{% include_cached /kongctl/help/get/audit-logs/index.md %}

### kongctl get audit-logs destination

Get audit log destination.

{% include_cached /kongctl/help/get/audit-logs/destination.md %}

### kongctl get audit-logs destinations

Get audit log destinations.

{% include_cached /kongctl/help/get/audit-logs/destinations.md %}

### kongctl get audit-logs webhook

Get audit log webhook.

{% include_cached /kongctl/help/get/audit-logs/webhook.md %}
