---
title: kongctl adopt konnect
description: "Adopt {{site.konnect_short_name}} resources."
content_type: reference
layout: reference

beta: true
works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/adopt/
  - /kongctl/adopt/konnect/

related_resources:
  - text: kongctl adopt commands
    url: /kongctl/adopt/
---

Adopt {{site.konnect_short_name}} resources.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl adopt konnect api](/kongctl/adopt/konnect/api/)
    description: "Adopt an existing Konnect API into namespace management."
  - command: |
      [kongctl adopt konnect auth-strategy](/kongctl/adopt/konnect/auth-strategy/)
    description: "Adopt an existing Konnect authentication strategy into namespace management."
  - command: |
      [kongctl adopt konnect control-plane](/kongctl/adopt/konnect/control-plane/)
    description: "Adopt an existing Konnect control plane into namespace management."
  - command: |
      [kongctl adopt konnect dcr-provider](/kongctl/adopt/konnect/dcr-provider/)
    description: "Adopt an existing Konnect DCR provider into namespace management."
  - command: |
      [kongctl adopt konnect event-gateway](/kongctl/adopt/konnect/event-gateway/)
    description: "Adopt an existing Konnect Event Gateway into namespace management."
  - command: |
      [kongctl adopt konnect organization](/kongctl/adopt/konnect/organization/)
    description: "Adopt organization resources into namespace management."
  - command: |
      [kongctl adopt konnect portal](/kongctl/adopt/konnect/portal/)
    description: "Adopt an existing Konnect portal into namespace management."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/adopt/konnect/index.md %}
