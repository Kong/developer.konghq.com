---
title: deck file render
description: Render the final configuration sent to the Admin API in a single file.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/file/

related_resources:
  - text: deck file merge
    url: /deck/file/merge/

tags:
  - declarative-config
---

The `deck file render` command combines multiple complete configuration files and renders them as one Kong state file.

This command renders a full {{site.base_gateway}} configuration in JSON or YAML format by assembling multiple files and populating defaults and environment substitutions. This command is useful for observing what configuration would be sent prior to synchronizing to {{site.base_gateway}}.

In comparison to the `deck file merge` command, the render command accepts complete configuration files, while `deck file merge` can operate on partial files.

For example, the following command takes two input files and renders them as one combined JSON file:

```bash
deck file render kong1.yml kong2.yml
```

The `deck file render` command validates the configuration against a schema, and warns if any duplicate entities are detected.

## Command usage

{% include_cached deck/help/file/render.md %}
