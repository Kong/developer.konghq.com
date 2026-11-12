---
title: kongctl inspect mesh
description: "Inspect what a {{site.mesh_product_name}} control plane computed, rather than what was applied to it."
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
  - text: kongctl apply mesh
    url: /kongctl/apply/mesh/
  - text: kongctl create mesh
    url: /kongctl/create/mesh/
  - text: kongctl delete mesh
    url: /kongctl/delete/mesh/
  - text: kongctl dump mesh
    url: /kongctl/dump/mesh/
  - text: kongctl get mesh
    url: /kongctl/get/mesh/
---

Inspect what a {{site.mesh_product_name}} control plane computed, rather than what was
applied to it.

`get mesh` reads stored resource configuration. `inspect` answers the
questions that only the control plane can: which policies apply to a proxy
once matching and merging have run, and which proxies a policy matches.

{{site.mesh_product_name}} 3.0 or later control plane is required.

kongctl provides the following tools for inspecting {{site.mesh_product_name}} resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl inspect mesh dataplane](/kongctl/inspect/mesh/#kongctl-inspect-mesh-dataplane)
    description: "Inspect what applies to one dataplane."
  - command: |
      [kongctl inspect mesh dataplanes](/kongctl/inspect/mesh/#kongctl-inspect-mesh-dataplanes)
    description: "Overview of every dataplane in the mesh."
  - command: |
      [kongctl inspect mesh meshes](/kongctl/inspect/mesh/#kongctl-inspect-mesh-meshes)
    description: "Overview of every mesh."
  - command: |
      [kongctl inspect mesh zones](/kongctl/inspect/mesh/#kongctl-inspect-mesh-zones)
    description: "Overview of every zone."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/inspect/mesh/index.md %}

### kongctl inspect mesh dataplane

Inspect what applies to one dataplane.

{% include_cached /kongctl/help/inspect/mesh/dataplane.md %}

### kongctl inspect mesh dataplanes

Overview of every dataplane in the mesh.

{% include_cached /kongctl/help/inspect/mesh/dataplanes.md %}

### kongctl inspect mesh meshes

Overview of every mesh.

{% include_cached /kongctl/help/inspect/mesh/meshes.md %}

### kongctl inspect mesh zones

Overview of every zone.

{% include_cached /kongctl/help/inspect/mesh/zones.md %}
