---
title: kongctl create organization
description: "Manage {{site.konnect_short_name}} system accounts."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/create/
  - /kongctl/create/organization/

related_resources:
  - text: kongctl create commands
    url: /kongctl/create/
---

kongctl provides the following tools for managing {{site.konnect_short_name}} organization resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl create organization system-account](/kongctl/create/organization/system-account/)
    description: "Create {{site.konnect_short_name}} system accounts."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/create/organization/index.md %}
