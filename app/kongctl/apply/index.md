---
title: kongctl apply
description: "Apply {{site.konnect_short_name}} configuration using kongctl."

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

The `apply` command creates or updates resources to match the desired state. It does not delete resources.

Because `apply` doesn't delete resources, you can use it to incrementally apply resource configurations. For example, you could apply a `portal` in one command and then apply `apis` in a separate command.

If you want to delete resources when applying configuration, use [`kongctl sync`](/kongctl/sync/).

## Examples

Apply directly from config:

```shell
kongctl apply -f config.yaml
```

Apply from a saved plan:

```shell
kongctl apply --plan plan.json
```

Preview changes without applying:

```shell
kongctl apply -f config.yaml --dry-run
```

## Subcommands

kongctl provides the following tools for applying configuration in {{site.konnect_short_name}}:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl apply konnect](/kongctl/apply/konnect/)
    description: "Apply configuration to {{site.konnect_short_name}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/apply/index.md %}
