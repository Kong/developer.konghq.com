---
title: kongctl inspect identity
description: "Inspect Kong Identity principal resources."
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
  - text: kongctl adopt identity
    url: /kongctl/adopt/identity/
  - text: kongctl get identity
    url: /kongctl/get/identity/
  - text: kongctl import identity
    url: /kongctl/import/identity/
  - text: kongctl list identity
    url: /kongctl/list/identity/
---

Inspect Kong Identity principal resources.

kongctl provides the following tools for inspecting Kong Identity resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl inspect identity principal](/kongctl/inspect/identity/#kongctl-inspect-identity-principal)
    description: "Manage Identity principal child resources."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/inspect/identity/index.md %}

### kongctl inspect identity principal

Manage Identity principal child resources.

{% include_cached /kongctl/help/inspect/identity/principal.md %}
