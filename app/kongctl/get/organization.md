---
title: kongctl get organization
description: "Get organization details."
content_type: reference
layout: reference


works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
---

Get organization details.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get organization system-account](/kongctl/get/organization/#kongctl-get-organization-system-account)
    description: "Get organization system account."
  - command: |
      [kongctl get organization team](/kongctl/get/organization/#kongctl-get-organization-team)
    description: "Get organization team."
  - command: |
      [kongctl get organization user](/kongctl/get/organization/#kongctl-get-organization-user)
    description: "Use the `get` verb with the `user` command to query {{site.konnect_short_name}} organization users."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/organization/index.md %}

### kongctl get organization system-account

Get organization system account.

{% include_cached /kongctl/help/get/organization/system-account.md %}

### kongctl get organization team

Get organization team.

{% include_cached /kongctl/help/get/organization/team.md %}

### kongctl get organization user

Use the `get` verb with the `user` command to query {{site.konnect_short_name}} organization users.

{% include_cached /kongctl/help/get/organization/user.md %}
