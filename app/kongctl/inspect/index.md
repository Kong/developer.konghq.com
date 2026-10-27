---
title: kongctl inspect
description: "Inspect resource relationships, computed configuration, and runtime state."
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

Inspect resource relationships, computed configuration, and runtime state. Currently supports {{site.mesh_product_name}}.

## Examples

```shell
kongctl inspect mesh dataplanes
```

## Subcommands

kongctl provides the following tools for inspecting resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl inspect konnect](/kongctl/inspect/konnect/)
    description: "Inspect {{site.konnect_short_name}} resources."
  - command: |
      [kongctl inspect mesh](/kongctl/inspect/mesh/)
    description: "Inspect what a {{site.mesh_product_name}} control plane computed."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/inspect/index.md %}
