---
title: kongctl install
description: "Install local assets that help coding agents work with {{site.konnect_short_name}} using kongctl."

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

Install local assets that help coding agents work with {{site.konnect_short_name}} using kongctl.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl install skills](/kongctl/install/skills/)
    description: "Install kongctl agent skills."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/install/index.md %}
