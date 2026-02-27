---
title: kongctl api
description: Make API requests using kongctl.

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

kongctl provides the following tools for making {{site.konnect_short_name}} API requests using kongctl:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl api delete](/kongctl/api/delete/)
    description: "Delete resources via API."
  - command: |
      [kongctl api get](/kongctl/api/get/)
    description: "Retrieve resources via API."
  - command: |
      [kongctl api patch](/kongctl/api/patch/)
    description: "Partially update resources via API."
  - command: |
      [kongctl api post](/kongctl/api/post/)
    description: "Create resources via API."
  - command: |
      [kongctl api put](/kongctl/api/put/)
    description: "Update resources via API."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/api/index.md %}
