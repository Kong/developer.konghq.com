---
title: Listing resources using kongctl
short_title: kongctl list overview
description: List resources using kongctl.

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

kongctl provides the following tools for listing resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl list api](/kongctl/list/api/)
    description: "List APIs."
  - command: |
      [kongctl list auth-strategy](/kongctl/list/auth-strategy/)
    description: "List authentication strategies."
  - command: |
      [kongctl list gateway](/kongctl/list/gateway/)
    description: "List gateways."
  - command: |
      [kongctl list konnect](/kongctl/list/konnect/)
    description: "List Konnect resources."
  - command: |
      [kongctl list organization](/kongctl/list/organization/)
    description: "List organizations."
  - command: |
      [kongctl list portal](/kongctl/list/portal/)
    description: "List Portal configurations."
  - command: |
      [kongctl list themes](/kongctl/list/themes/)
    description: "List Portal themes."
{% endtable %}
