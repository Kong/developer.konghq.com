---
title: Patching resources using kongctl
short_title: kongctl patch overview
description: Patch resources using kongctl.

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

kongctl provides the following tools for patching files:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl patch file](/kongctl/patch/file/)
    description: "Apply patches from file."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/patch/index.md %}
