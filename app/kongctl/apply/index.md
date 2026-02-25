---
title: "Applying {{site.konnect_short_name}} configuration using kongctl"
short_title: kongctl apply overview
description: "Apply {{site.konnect_short_name}} configuration using kongctl."

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

kongctl provides the following tools for applying configuration in {{site.konnect_short_name}}:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl apply konnect](/kongctl/apply/konnect/)
    description: "Apply configuration to {{site.konnect_short_name}}."
{% endtable %}
