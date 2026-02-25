---
title: Creating resources using kongctl
short_title: kongctl create overview
description: Create resources using kongctl.

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

kongctl provides the following tools for creating resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl create gateway](/kongctl/create/gateway/)
    description: "Create a gateway."
  - command: |
      [kongctl create konnect](/kongctl/create/konnect/)
    description: "Create resources in {{site.konnect_short_name}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/create/index.md %}
