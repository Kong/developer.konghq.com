---
title: kongctl get analytics
description: "The analytics command allows you to work with {{site.konnect_short_name}} {{site.observability}} resources."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/
  - /kongctl/get/analytics/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
---

The `analytics` command allows you to work with [{{site.konnect_short_name}} {{site.observability}}](/observability/) resources.

kongctl provides the following tools for retrieving {{site.konnect_short_name}} {{site.observability}} resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get analytics dashboard](/kongctl/get/analytics/dashboard/)
    description: "Use the `dashboard` command to list or get {{site.konnect_short_name}} {{site.observability}} dashboards."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/analytics/index.md %}
