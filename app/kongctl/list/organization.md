---
title: kongctl list organization
description: "List organizations."
content_type: reference
layout: reference


works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/list/

related_resources:
  - text: kongctl list commands
    url: /kongctl/list/
---

List organizations.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl list organization system-account](/kongctl/list/organization/#kongctl-list-organization-system-account)
    description: "List organization system accounts."
  - command: |
      [kongctl list organization team](/kongctl/list/organization/#kongctl-list-organization-team)
    description: "List organization teams."
  - command: |
      [kongctl list organization user](/kongctl/list/organization/#kongctl-list-organization-user)
    description: "Use the `get` verb with the `user` command to query {{site.konnect_short_name}} organization users."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/list/organization/index.md %}

### kongctl list organization system-account

List organization system accounts.

{% include_cached /kongctl/help/list/organization/system-account.md %}

### kongctl list organization team

List organization teams.

{% include_cached /kongctl/help/list/organization/team.md %}

### kongctl list organization user

Use the `get` verb with the `user` command to query {{site.konnect_short_name}} organization users.

{% include_cached /kongctl/help/list/organization/user.md %}
