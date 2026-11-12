---
title: kongctl import
description: "Import data into {{site.konnect_short_name}}, such as an organization chart."

content_type: reference
layout: reference

works_on:
  - konnect

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

Import data into {{site.konnect_short_name}}, such as an organization chart.

## Subcommands

kongctl provides the following tools for importing data:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl import identity](/kongctl/import/identity/)
    description: "Import Kong Identity resources."
  - command: |
      [kongctl import konnect](/kongctl/import/konnect/)
    description: "Manage {{site.konnect_short_name}} resources."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/import/index.md %}
