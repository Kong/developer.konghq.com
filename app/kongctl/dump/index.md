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

Export all `portal` and `api` resources to kongctl declarative configuration and the `team-alpha` namespace:

```shell
kongctl dump declarative --resources=portal,api --default-namespace=team-alpha
```

When bringing existing resources into declarative management, use
[`kongctl adopt --declarative-output`](/kongctl/declarative/adoption/) to assign
ownership and save configuration in one command. For example, adopt a custom
dashboard created in the {{site.konnect_short_name}} UI:

```shell
kongctl adopt analytics dashboard 22cd8a0b-72e7-4212-9099-0764f8e9c5ac \
  --namespace analytics --declarative-output dashboard.yaml
```

Use a new output path, then review a plan using the saved declaration:

```shell
kongctl plan -f dashboard.yaml --mode apply
```

Use `dump declarative` when you need a current-state export independently of
adoption. Dumping configuration doesn't assign ownership to resources.

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
      [kongctl dump mesh](/kongctl/dump/mesh/)
    description: "Export resources from a {{site.mesh_product_name}} control plane."
  - command: |
      [kongctl dump tf-import](/kongctl/dump/tf-import/)
    description: "Export for Terraform import."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/dump/index.md %}
