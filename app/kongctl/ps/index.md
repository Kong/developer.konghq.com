---
title: Managing processes using kongctl
short_title: kongctl ps overview
description: Manage processes using kongctl.

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

kongctl provides the following tools for managing processes:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl ps stop](/kongctl/ps/stop/)
    description: "Stop Kong processes."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/ps/index.md %}
