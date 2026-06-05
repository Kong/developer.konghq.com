---
title: kongctl plan
description: Plan changes using kongctl.

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

Generate a JSON plan file containing the set of changes to apply to your resources.

Plans can run in either `--mode apply` or `--mode sync` (default option):
* Apply mode creates and updates only the configured resources.
* Sync mode creates, updates, and deletes managed resources, but only for resource collections that are explicitly present in the input configuration.

## Examples

Generate an apply plan and output to STDOUT:

```shell
kongctl plan -f config.yaml --mode apply
```

Generate a sync plan and output to STDOUT:

```shell
kongctl plan -f config.yaml --mode sync
```

## Subcommands

kongctl provides the following tools for planning changes:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl plan konnect](/kongctl/plan/konnect/)
    description: "Plan changes for {{site.konnect_short_name}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/plan/index.md %}
