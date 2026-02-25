---
title: Planning changes using kongctl
short_title: kongctl plan overview
description: Plan changes using kongctl.

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

kongctl provides the following tools for planning changes:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl plan konnect](/kongctl/plan/konnect/)
    description: "Plan changes for {{site.konnect_short_name}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/plan/index.md %}
