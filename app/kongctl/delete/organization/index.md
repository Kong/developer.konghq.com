---
title: kongctl delete organization
description: "Manage {{site.konnect_short_name}} system account resources."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/delete/
  - /kongctl/delete/organization/

related_resources:
  - text: kongctl delete commands
    url: /kongctl/delete/
---

Manage {{site.konnect_short_name}} system account resources.

kongctl provides the following tools for managing {{site.konnect_short_name}} organization resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl delete organization system-account](/kongctl/delete/organization/system-account/)
    description: "Manage {{site.konnect_short_name}} system account resources."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/delete/organization/index.md %}
