---
title: kongctl diff
description: Compare configurations using kongctl.

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

Display a preview of changes between current and desired state.

## Examples

Preview changes in apply mode (`CREATE` and `UPDATE` only):

```shell
kongctl diff -f config.yaml --mode apply
```

Preview changes in sync mode (`CREATE`, `UPDATE`, and `DELETE`):

```shell
kongctl diff -f config.yaml --mode sync
```

Preview targeted deletions in delete mode (`DELETE` only for matching resources):

```shell
kongctl diff -f config.yaml --mode delete
```

Preview changes from a plan artifact:

```shell
kongctl diff --plan plan.json
```

{:.info}
> **Note:** `--mode` can't be used with `--plan` because mode is stored in the plan artifact metadata.

For `UPDATE` actions, the text diff shows only the fields that would be changed.
JSON and YAML outputs expose the same detail in each change's `changed_fields` object while keeping `fields` as the execution payload.

## Subcommands

kongctl provides the following tools for viewing diffs:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl diff konnect](/kongctl/diff/konnect/)
    description: "Show {{site.konnect_short_name}} configuration diffs."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/diff/index.md %}
