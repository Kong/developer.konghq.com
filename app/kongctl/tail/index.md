---
title: Tailing logs using kongctl
short_title: kongctl tail overview
description: Tail logs using kongctl.

content_type: reference
layout: reference

works_on:
  - konnect
beta: true
tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Get started with kongctl
    url: /kongctl/get-started/
---

kongctl provides the following tools for tailing logs:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl tail audit-logs](/kongctl/tail/audit-logs/)
    description: "Tail audit logs."
  - command: |
      [kongctl tail konnect](/kongctl/tail/konnect/)
    description: "Tail {{site.konnect_short_name}} events."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/tail/index.md %}
