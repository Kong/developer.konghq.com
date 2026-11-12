---
title: kongctl apply mesh
description: "Apply resource documents directly to a {{site.mesh_product_name}} 3.0 or later control plane."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/apply/

related_resources:
  - text: kongctl apply commands
    url: /kongctl/apply/
  - text: kongctl create mesh
    url: /kongctl/create/mesh/
  - text: kongctl delete mesh
    url: /kongctl/delete/mesh/
  - text: kongctl dump mesh
    url: /kongctl/dump/mesh/
  - text: kongctl get mesh
    url: /kongctl/get/mesh/
  - text: kongctl inspect mesh
    url: /kongctl/inspect/mesh/
---

Apply resource documents directly to a {{site.mesh_product_name}} 3.0 or later control plane.

Each document creates or replaces the resource addressed by its type and name.
This command doesn't generate a declarative plan or show a diff. It doesn't
delete resources omitted from the input. Documents are processed in input order.
If a write fails, later documents are still attempted and the command exits
with an error after reporting all results.

## Command usage

{% include_cached /kongctl/help/apply/mesh.md %}
