---
title: kongctl create mesh
description: "The mesh command works with resources on a {{site.mesh_product_name}} control plane."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/create/

related_resources:
  - text: kongctl create commands
    url: /kongctl/create/
  - text: kongctl apply mesh
    url: /kongctl/apply/mesh/
  - text: kongctl delete mesh
    url: /kongctl/delete/mesh/
  - text: kongctl dump mesh
    url: /kongctl/dump/mesh/
  - text: kongctl get mesh
    url: /kongctl/get/mesh/
  - text: kongctl inspect mesh
    url: /kongctl/inspect/mesh/
---

The `mesh` command works with resources on a {{site.mesh_product_name}} control plane.

The resource types available are reported by the control plane itself, so
policies and resource types added by newer {{site.mesh_product_name}} releases are usable
without upgrading kongctl.

{{site.mesh_product_name}} 3.0 or later is required.

kongctl provides the following tools for creating {{site.mesh_product_name}} resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl create mesh dataplane-token](/kongctl/create/mesh/#kongctl-create-mesh-dataplane-token)
    description: "Issue a dataplane token from the control plane."
  - command: |
      [kongctl create mesh zone-token](/kongctl/create/mesh/#kongctl-create-mesh-zone-token)
    description: "Issue a zone token from the control plane."
{% endtable %}

To create or replace other {{site.mesh_product_name}} resources, use [`kongctl apply mesh`](/kongctl/apply/mesh/).

## Command usage

{% include_cached /kongctl/help/create/mesh/index.md %}

### kongctl create mesh dataplane-token

Issue a dataplane token from the control plane.

A dataplane token lets `kuma-dp` prove its identity when it connects. Bind the
token as narrowly as the deployment allows: to a name, to a workload, or to
tags, rather than to the mesh alone.

The token is written to stdout with no trailing newline, so it can be
redirected straight into the file `kuma-dp` reads.

{% include_cached /kongctl/help/create/mesh/dataplane-token.md %}

### kongctl create mesh zone-token

Issue a zone token from the control plane.

A zone token lets a zone control plane prove its identity to a global control
plane when it joins.

The token is written to stdout with no trailing newline, so it can be
redirected straight into a file.

{% include_cached /kongctl/help/create/mesh/zone-token.md %}
