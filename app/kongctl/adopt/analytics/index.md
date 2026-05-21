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
  - /kongctl/adopt/analytics/

related_resources:
  - text: kongctl adopt commands
    url: /kongctl/adopt/
---

The `analytics` command adopts [{{site.konnect_short_name}} {{site.observability}}](/observability/) resources into namespace management.

kongctl provides the following tools for adopting {{site.konnect_short_name}} {{site.observability}} resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl adopt analytics dashboard](/kongctl/adopt/analytics/dashboard/)
    description: "Adopt an existing {{site.konnect_short_name}} dashboard into namespace management."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/adopt/analytics/index.md %}
