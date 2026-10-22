---
title: kongctl get mesh
description: "The mesh command works with resources on a {{site.mesh_product_name}} control plane."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
  - text: kongctl apply mesh
    url: /kongctl/apply/mesh/
  - text: kongctl create mesh
    url: /kongctl/create/mesh/
  - text: kongctl delete mesh
    url: /kongctl/delete/mesh/
  - text: kongctl dump mesh
    url: /kongctl/dump/mesh/
  - text: kongctl inspect mesh
    url: /kongctl/inspect/mesh/
---

The `mesh` command works with resources on a {{site.mesh_product_name}} control plane.

The resource types available are reported by the control plane itself, so
policies and resource types added by newer {{site.mesh_product_name}} releases are usable
without upgrading kongctl.

{{site.mesh_product_name}} 3.0 or later is required.

kongctl provides the following tools for retrieving {{site.mesh_product_name}} resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get mesh control-planes](/kongctl/get/mesh/#kongctl-get-mesh-control-planes)
    description: "List the {{site.konnect_short_name}} hosted {{site.mesh_product_name}} control planes the authenticated identity can see."
  - command: |
      [kongctl get mesh resource-types](/kongctl/get/mesh/#kongctl-get-mesh-resource-types)
    description: "List the resource types the selected {{site.mesh_product_name}} control plane serves."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/mesh/index.md %}

### kongctl get mesh control-planes

List the {{site.konnect_short_name}} hosted {{site.mesh_product_name}} control planes the authenticated identity
can see, with the identifier every other `mesh` command needs.

The `API LINE` column is the {{site.konnect_short_name}} API line a control plane is reached on,
not the version it runs. A control plane on the v3 line runs {{site.mesh_product_name}} 3.
One on the v0 line runs the 2.14 series, which this command surface doesn't
support. To read the version a control plane actually runs, address it
and read its index endpoint.

Identifiers are abbreviated in text output, as they are elsewhere in
kongctl. Pass `--text-id-format full` to print them whole, or `-o json`. In
most cases the identifier isn't needed at all: other `mesh` commands accept
`--control-plane-name`.

{% include_cached /kongctl/help/get/mesh/control-planes.md %}

### kongctl get mesh resource-types

List the resource types the selected {{site.mesh_product_name}} control plane serves,
along with the name each is addressed by, its scope, and whether it can be
modified.

Use this to discover what a control plane supports, including policies and
enterprise resource types that vary between {{site.mesh_product_name}} releases.

{% include_cached /kongctl/help/get/mesh/resource-types.md %}
