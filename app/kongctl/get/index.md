---
title: kongctl get
description: Get detailed information about resources using kongctl.

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

kongctl provides the following tools for retrieving resources and resource details:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get api](/kongctl/get/api/)
    description: "Get API details."
  - command: |
      [kongctl get audit-logs](/kongctl/get/audit-logs/)
    description: "Get audit logs."
  - command: |
      [kongctl get auth-strategy](/kongctl/get/auth-strategy/)
    description: "Get authentication strategy details."
  - command: |
      [kongctl get catalog](/kongctl/get/catalog/)
    description: "Get {{site.catalog}} details."
  - command: |
      [kongctl get gateway](/kongctl/get/gateway/)
    description: "Get gateway information."
  - command: |
      [kongctl get konnect](/kongctl/get/konnect/)
    description: "Get {{site.konnect_short_name}} account information."
  - command: |
      [kongctl get me](/kongctl/get/me/)
    description: "Get current user information."
  - command: |
      [kongctl get organization](/kongctl/get/organization/)
    description: "Get organization details."
  - command: |
      [kongctl get portal](/kongctl/get/portal/)
    description: "Get Portal configuration."
  - command: |
      [kongctl get profile](/kongctl/get/profile/)
    description: "Get user profile."
  - command: |
      [kongctl get regions](/kongctl/get/regions/)
    description: "Get available regions."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/index.md %}
