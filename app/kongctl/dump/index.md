---
title: kongctl dump
description: Export configurations using kongctl.

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

kongctl provides the following tools for exporting configurations:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl dump declarative](/kongctl/dump/declarative/)
    description: "Export declarative configuration."
  - command: |
      [kongctl dump tf-import](/kongctl/dump/tf-import/)
    description: "Export for Terraform import."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/dump/index.md %}
