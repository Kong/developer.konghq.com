---
title: kongctl explain
description: "Explain shows the declarative schema for a supported resource type or field path."
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

Explain shows the declarative schema for a supported resource type or field
path.

Run `kongctl explain` without a path to list every available declarative
resource path. Use text output for human-readable field summaries. Use JSON or
YAML to retrieve the same machine-readable schema.

Lower-maturity resources and operations include a maturity label. Unlabeled
resources are GA. JSON and YAML schema output exposes maturity through
`x-kongctl-maturity`.

## Command usage

{% include_cached /kongctl/help/explain/index.md %}
