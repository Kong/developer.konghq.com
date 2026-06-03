---
title: kongctl create konnect
description: "Create {{site.konnect_short_name}} access tokens"
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/create/
  - /kongctl/create/konnect/

related_resources:
  - text: kongctl create commands
    url: /kongctl/create/
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
      [kongctl create konnect organization](/kongctl/create/konnect/organization/)
    description: "Manage {{site.konnect_short_name}} organization resources."
  - command: |
      [kongctl create konnect pat](/kongctl/create/konnect/pat/)
    description: "Create a {{site.konnect_short_name}} personal access token."
  - command: |
      [kongctl create konnect spat](/kongctl/create/konnect/spat/)
    description: "Create a {{site.konnect_short_name}} system account access token."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/create/konnect/index.md %}
