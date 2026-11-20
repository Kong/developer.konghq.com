---
title: kongctl adopt identity
description: "Adopt Kong Identity resources using namespace labels or ownership metadata."
content_type: reference
layout: reference


works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/adopt/

related_resources:
  - text: kongctl adopt commands
    url: /kongctl/adopt/
  - text: kongctl get identity
    url: /kongctl/get/identity/
  - text: kongctl import identity
    url: /kongctl/import/identity/
  - text: kongctl inspect identity
    url: /kongctl/inspect/identity/
  - text: kongctl list identity
    url: /kongctl/list/identity/
---

Adopt Kong Identity resources using namespace labels or ownership metadata.

kongctl provides the following tools for adopting Kong Identity resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl adopt identity auth-server](/kongctl/adopt/identity/#kongctl-adopt-identity-auth-server)
    description: "Adopt a Kong Identity authorization server using labels."
  - command: |
      [kongctl adopt identity directory](/kongctl/adopt/identity/#kongctl-adopt-identity-directory)
    description: "Adopt a Kong Identity directory using `managed_by` ownership metadata."
  - command: |
      [kongctl adopt identity group](/kongctl/adopt/identity/#kongctl-adopt-identity-group)
    description: "Adopt an ordinary Kong Identity group using `managed_by` ownership."
  - command: |
      [kongctl adopt identity principal](/kongctl/adopt/identity/#kongctl-adopt-identity-principal)
    description: "Adopt a principal by UUID with a local ref."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/adopt/identity/index.md %}

### kongctl adopt identity auth-server

Adopt a Kong Identity authorization server using labels.

{% include_cached /kongctl/help/adopt/identity/auth-server.md %}

### kongctl adopt identity directory

Adopt a Kong Identity directory using `managed_by` ownership metadata.

{% include_cached /kongctl/help/adopt/identity/directory.md %}

### kongctl adopt identity group

Adopt an ordinary Kong Identity group using `managed_by` ownership.

{% include_cached /kongctl/help/adopt/identity/group.md %}

### kongctl adopt identity principal

Adopt a principal by UUID with a local ref.

{% include_cached /kongctl/help/adopt/identity/principal.md %}
