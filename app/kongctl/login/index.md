---
title: kongctl login
description: Authenticate with kongctl.

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

kongctl provides the following tool for logging in:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl login konnect](/kongctl/login/konnect/)
    description: "Log in to {{site.konnect_short_name}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/login/index.md %}
