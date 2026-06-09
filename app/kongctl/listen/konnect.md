---
title: kongctl listen konnect
description: "Listen to {{site.konnect_short_name}} events."
content_type: reference
layout: reference


works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/listen/

related_resources:
  - text: kongctl listen commands
    url: /kongctl/listen/
---

Listen to {{site.konnect_short_name}} events.

## Command usage

{% include_cached /kongctl/help/listen/konnect/index.md %}

### kongctl listen konnect audit-logs

Listen to {{site.konnect_short_name}} audit log stream.

{% include_cached /kongctl/help/listen/konnect/audit-logs.md %}
