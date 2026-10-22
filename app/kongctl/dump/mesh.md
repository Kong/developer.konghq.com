---
title: kongctl dump mesh
description: "Export resources from a {{site.mesh_product_name}} 3.0 or later control plane as a YAML stream."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/dump/

related_resources:
  - text: kongctl dump commands
    url: /kongctl/dump/
  - text: kongctl apply mesh
    url: /kongctl/apply/mesh/
  - text: kongctl create mesh
    url: /kongctl/create/mesh/
  - text: kongctl delete mesh
    url: /kongctl/delete/mesh/
  - text: kongctl get mesh
    url: /kongctl/get/mesh/
  - text: kongctl inspect mesh
    url: /kongctl/inspect/mesh/
---

Export resources from a {{site.mesh_product_name}} 3.0 or later control plane as a YAML stream.

The export covers the entire control plane, including every mesh. The default
`federation` profile prepares resources for migration to another global control
plane and excludes policies. Use `federation-with-policies` to include policies.
These profiles strip control-plane-owned labels so the destination can set them.

The `all` and `no-dataplanes` profiles retain source labels and may include read-only
resources. They are inventories and can't necessarily be applied back unchanged.

{:.warning}
> **Caution**: Exports can contain secrets. Save them in a location appropriate for credentials.

## Command usage

{% include_cached /kongctl/help/dump/mesh.md %}
