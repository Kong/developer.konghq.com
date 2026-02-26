---
title: Listening to events using kongctl
short_title: kongctl listen overview
description: Listen to events using kongctl.

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

kongctl provides the following tools for listening to events:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl listen audit-logs](/kongctl/listen/audit-logs/)
    description: "Listen to audit log stream."
  - command: |
      [kongctl listen konnect](/kongctl/listen/konnect/)
    description: "Listen to {{site.konnect_short_name}} events."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/listen/index.md %}
