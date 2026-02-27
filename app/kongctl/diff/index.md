---
title: Comparing configurations using kongctl
short_title: kongctl diff overview
description: Compare configurations using kongctl.

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

kongctl provides the following tools for viewing diffs:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl diff konnect](/kongctl/diff/konnect/)
    description: "Show {{site.konnect_short_name}} configuration diffs."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/diff/index.md %}
