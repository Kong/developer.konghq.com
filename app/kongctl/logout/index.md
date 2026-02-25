---
title: Logging out with kongctl
short_title: kongctl logout overview
description: Log out with kongctl.

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

kongctl provides the following tools for logging out:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl logout konnect](/kongctl/logout/konnect/)
    description: "Log out from {{site.konnect_short_name}}."
{% endtable %}
