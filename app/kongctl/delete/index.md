---
title: Deleting resources using kongctl
short_title: kongctl delete overview
description: Delete resources using kongctl.

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

kongctl provides the following tools for deleting resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl delete gateway](/kongctl/delete/gateway/)
    description: "Delete a gateway."
  - command: |
      [kongctl delete konnect](/kongctl/delete/konnect/)
    description: "Delete resources from {{site.konnect_short_name}}."
  - command: |
      [kongctl delete portal](/kongctl/delete/portal/)
    description: "Delete Portal configuration."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/delete/index.md %}
