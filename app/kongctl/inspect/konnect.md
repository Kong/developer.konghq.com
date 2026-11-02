---
title: kongctl inspect konnect
description: "The konnect command allows you to manage {{site.konnect_short_name}} resources."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/inspect/

related_resources:
  - text: kongctl inspect commands
    url: /kongctl/inspect/
---

The `konnect` command allows you to manage {{site.konnect_short_name}} resources.

## Command usage

{% include_cached /kongctl/help/inspect/konnect/index.md %}

### kongctl inspect konnect mesh

Inspect what a {{site.mesh_product_name}} control plane computed, rather than what was
applied to it.

`get mesh` reads stored resource configuration. `inspect` answers the
questions that only the control plane can: which policies apply to a proxy
once matching and merging have run, and which proxies a policy matches.

{{site.mesh_product_name}} 3.0 or later control plane is required.

{% include_cached /kongctl/help/inspect/konnect/mesh.md %}
