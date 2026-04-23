---
title: kongctl scaffold
description: "Scaffold emits a commented YAML starter configuration for a supported declarative resource path."
content_type: reference
layout: reference

beta: true
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

Scaffold emits a commented YAML starter configuration for a supported declarative resource path.

The output is intended to be edited and then used with declarative commands such as apply or sync.

## Command usage

{% include_cached /kongctl/help/scaffold/index.md %}
