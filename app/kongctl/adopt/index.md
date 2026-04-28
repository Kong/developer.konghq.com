---
title: kongctl adopt
description: Adopt Kong resources using kongctl.

content_type: reference
layout: reference

works_on:
  - konnect
beta: true
tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Get started with kongctl
    url: /kongctl/get-started/
---

kongctl provides the following tools for adopting Kong resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl adopt api](/kongctl/adopt/api/)
    description: "Adopt API resources."
  - command: |
      [kongctl adopt auth-strategy](/kongctl/adopt/auth-strategy/)
    description: "Adopt authentication strategies."
  - command: |
      [kongctl adopt control-plane](/kongctl/adopt/control-plane/)
    description: "Adopt control plane configuration."
  - command: |
      [kongctl adopt dcr-provider](/kongctl/adopt/dcr-provider/)
    description: "Adopt an existing Konnect DCR provider into namespace management."
  - command: |
      [kongctl adopt event-gateway](/kongctl/adopt/event-gateway/)
    description: "Adopt an existing Konnect Event Gateway into namespace management."
  - command: |
      [kongctl adopt konnect](/kongctl/adopt/konnect/)
    description: "Adopt {{site.konnect_short_name}} resources."
  - command: |
      [kongctl adopt organization](/kongctl/adopt/organization/)
    description: "Adopt organization settings."
  - command: |
      [kongctl adopt portal](/kongctl/adopt/portal/)
    description: "Adopt Developer Portal configuration."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/adopt/index.md %}
