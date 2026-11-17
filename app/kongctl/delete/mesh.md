---
title: kongctl delete mesh
description: "Delete one resource from a {{site.mesh_product_name}} 3.0 or later control plane."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/delete/

related_resources:
  - text: kongctl delete commands
    url: /kongctl/delete/
  - text: kongctl apply mesh
    url: /kongctl/apply/mesh/
  - text: kongctl create mesh
    url: /kongctl/create/mesh/
  - text: kongctl dump mesh
    url: /kongctl/dump/mesh/
  - text: kongctl get mesh
    url: /kongctl/get/mesh/
  - text: kongctl inspect mesh
    url: /kongctl/inspect/mesh/
---

Delete one resource from a {{site.mesh_product_name}} 3.0 or later control plane.

Specify the resource type and name. For a mesh-scoped resource, select its mesh
with `--mesh`. The default is `default`. Read-only types can't be deleted.

## Command usage

{% include_cached /kongctl/help/delete/mesh.md %}
