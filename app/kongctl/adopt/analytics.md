---
title: kongctl adopt analytics
description: "The analytics command adopts {{site.konnect_short_name}} {{site.observability}} resources into namespace management."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/adopt/

related_resources:
  - text: kongctl adopt commands
    url: /kongctl/adopt/
---

The `analytics` command adopts [{{site.konnect_short_name}} {{site.observability}}](/observability/) resources into namespace management.

## Command usage

{% include_cached /kongctl/help/adopt/analytics/index.md %}

### kongctl adopt analytics dashboard

Apply the `KONGCTL-namespace` label to an existing {{site.konnect_short_name}} dashboard that is not currently managed by kongctl.

{% include_cached /kongctl/help/adopt/analytics/dashboard.md %}
