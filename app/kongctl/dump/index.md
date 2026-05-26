---
title: kongctl dump
description: Export configurations using kongctl.

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

Export current {{site.konnect_short_name}} resource state to various formats.

## Examples

Export all APIs with their child resources to `tf-import` format:
```shell
kongctl dump tf-import --resources=api --include-child-resources
```

Export all Portal and API resources to kongctl declarative configuration and the `team-alpha` namespace:

```shell
kongctl dump declarative --resources=portal,api --default-namespace=team-alpha
```

For custom dashboards created in the {{site.konnect_short_name}} UI, [adopt](/kongctl/adopt/) the dashboard first,
then dump it with the same namespace:

```shell
kongctl adopt analytics dashboard 22cd8a0b-72e7-4212-9099-0764f8e9c5ac \
  --namespace analytics
kongctl dump declarative --resources=analytics.dashboards \
  --default-namespace=analytics > dashboards.yaml
kongctl plan -f dashboards.yaml --mode apply
```

## Subcommands

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
