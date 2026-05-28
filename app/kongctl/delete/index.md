---
title: kongctl delete
description: Delete resources using kongctl.

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

`delete` removes all resources defined in the input declarative configuration files from the target {{site.konnect_short_name}} organization.
Use `delete` for experimenting with a known set of resources or resetting a test environment. It isn't a common part of the declarative configuration workflow.

`kongctl delete -f <files>` is equivalent to generating a delete-mode [plan](/kongctl/plan/) for the input files and running it.

## Examples

Preview targeted deletions:

```shell
kongctl diff -f config.yaml --mode delete
```

Delete resources declared in a file:

```shell
kongctl delete -f config.yaml
```

{:.warning}
> **Caution**: `delete` plans to delete all resources specified in the input
> configuration. Always verify the changes before approving execution.

## Command usage

{% include_cached /kongctl/help/delete/index.md %}
