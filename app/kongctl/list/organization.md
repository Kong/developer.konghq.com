---
title: kongctl list organization
description: "List organizations."
content_type: reference
layout: reference


works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/list/

related_resources:
  - text: kongctl list commands
    url: /kongctl/list/
  - text: kongctl adopt organization
    url: /kongctl/adopt/organization/
  - text: kongctl create organization
    url: /kongctl/create/organization/
  - text: kongctl delete organization
    url: /kongctl/delete/organization/
  - text: kongctl get organization
    url: /kongctl/get/organization/
---

List organizations.

## Command usage

{% include_cached /kongctl/help/list/organization/index.md %}

### kongctl list organization system-account

List organization system accounts.

{% include_cached /kongctl/help/list/organization/system-account.md %}

### kongctl list organization team

List organization teams.

{% include_cached /kongctl/help/list/organization/team.md %}

### kongctl list organization user

Use the `list` verb with the `user` command to query {{site.konnect_short_name}} organization users.

{% include_cached /kongctl/help/list/organization/user.md %}
