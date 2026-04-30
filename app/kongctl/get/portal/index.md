---
title: kongctl get portal
description: "Get Portal configuration."
content_type: reference
layout: reference

beta: true
works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/
  - /kongctl/get/portal/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
---

Use the `get` verb with the `portal` command to query {{site.konnect_short_name}} portals.

kongctl provides the following tools for retrieving resources and resource details for {{site.konnect_short_name}} portals:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get portal application-registrations](/kongctl/get/portal/application-registrations/)
    description: "Use the `registrations` command to list or retrieve application registrations for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal applications](/kongctl/get/portal/applications/)
    description: "Use the `applications` command to list or retrieve applications for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal assets](/kongctl/get/portal/assets/)
    description: "Use the `assets` command to fetch logo and favicon images for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal auth-settings](/kongctl/get/portal/auth-settings/)
    description: "Use the `auth-settings` command to fetch authentication settings for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal developers](/kongctl/get/portal/developers/)
    description: "Use the `developers` command to list or retrieve developers for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal email-domains](/kongctl/get/portal/email-domains/)
    description: "Use the `email-domains` command to list custom email domains that can be used for portal emails."
  - command: |
      [kongctl get portal identity-providers](/kongctl/get/portal/identity-providers/)
    description: "Use the `identity-providers` command to list identity providers for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal pages](/kongctl/get/portal/pages/)
    description: "Use the `pages` command to list or retrieve custom pages for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal snippets](/kongctl/get/portal/snippets/)
    description: "Use the `snippets` command to list or retrieve custom snippets for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal team-roles](/kongctl/get/portal/team-roles/)
    description: "Use the `team-roles` command to list role assignments for teams in a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal teams](/kongctl/get/portal/teams/)
    description: "Use the `teams` command to list or retrieve developer teams for a specific {{site.konnect_short_name}} portal."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/portal/index.md %}
