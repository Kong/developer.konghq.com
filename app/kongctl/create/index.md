---
title: kongctl create
description: "Create {{site.konnect_short_name}} access tokens using kongctl."
content_type: reference
layout: reference

works_on:
  - konnect

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

kongctl provides the following tools for creating {{site.konnect_short_name}} access tokens:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl create konnect](/kongctl/create/konnect/)
    description: "Create {{site.konnect_short_name}} resources."
  - command: |
      [kongctl create organization](/kongctl/create/organization/)
    description: "Create {{site.konnect_short_name}} system accounts."
  - command: |
      [kongctl create pat](/kongctl/create/pat/)
    description: "Create a {{site.konnect_short_name}} personal access token."
  - command: |
      [kongctl create spat](/kongctl/create/spat/)
    description: "Create a {{site.konnect_short_name}} system account access token."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/create/index.md %}
