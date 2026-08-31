---
title: kongctl scaffold
description: "Scaffold emits a commented YAML starter configuration for a supported declarative resource path."
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

Scaffold emits a commented YAML starter configuration for a supported
declarative resource path.

Run `kongctl scaffold` without a path to list the available resource paths.
The output is intended to be edited and then used with declarative commands
such as `apply` or `sync`.

Scaffolds for beta or tech-preview resources begin with a maturity comment. GA
scaffolds don't include a maturity warning.

## Command usage

{% include_cached /kongctl/help/scaffold/index.md %}
