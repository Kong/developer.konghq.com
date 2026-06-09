---
title: kongctl get portal
description: "Get Portal configuration."
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
      [kongctl get portal application-registrations](/kongctl/get/portal/#kongctl-get-portal-application-registrations)
    description: "Use the `registrations` command to list or retrieve application registrations for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal applications](/kongctl/get/portal/#kongctl-get-portal-applications)
    description: "Use the `applications` command to list or retrieve applications for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal assets](/kongctl/get/portal/#kongctl-get-portal-assets)
    description: "Use the `assets` command to fetch logo and favicon images for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal auth-settings](/kongctl/get/portal/#kongctl-get-portal-auth-settings)
    description: "Use the `auth-settings` command to fetch authentication settings for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal developers](/kongctl/get/portal/#kongctl-get-portal-developers)
    description: "Use the `developers` command to list or retrieve developers for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal email-domains](/kongctl/get/portal/#kongctl-get-portal-email-domains)
    description: "Use the `email-domains` command to list custom email domains that can be used for portal emails."
  - command: |
      [kongctl get portal identity-providers](/kongctl/get/portal/#kongctl-get-portal-identity-providers)
    description: "Use the `identity-providers` command to list identity providers for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal pages](/kongctl/get/portal/#kongctl-get-portal-pages)
    description: "Use the `pages` command to list or retrieve custom pages for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal snippets](/kongctl/get/portal/#kongctl-get-portal-snippets)
    description: "Use the `snippets` command to list or retrieve custom snippets for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal team-roles](/kongctl/get/portal/#kongctl-get-portal-team-roles)
    description: "Use the `team-roles` command to list role assignments for teams in a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl get portal teams](/kongctl/get/portal/#kongctl-get-portal-teams)
    description: "Use the `teams` command to list or retrieve developer teams for a specific {{site.konnect_short_name}} portal."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/portal/index.md %}

### kongctl get portal application-registrations

Get Portal application registrations.

{% include_cached /kongctl/help/get/portal/application-registrations.md %}

### kongctl get portal applications

Get Portal applications.

{% include_cached /kongctl/help/get/portal/applications.md %}

### kongctl get portal assets

Get Portal assets.

{% include_cached /kongctl/help/get/portal/assets.md %}

### kongctl get portal auth-settings

Get Portal authentication settings.

{% include_cached /kongctl/help/get/portal/auth-settings.md %}

### kongctl get portal developers

Get Portal developers.

{% include_cached /kongctl/help/get/portal/developers.md %}

### kongctl get portal email-domains

Get Portal email domains.

{% include_cached /kongctl/help/get/portal/email-domains.md %}

### kongctl get portal identity-providers

Use the `identity-providers` command to list identity providers for a {{site.konnect_short_name}} portal.

{% include_cached /kongctl/help/get/portal/identity-providers.md %}

### kongctl get portal pages

Get Portal pages.

{% include_cached /kongctl/help/get/portal/pages.md %}

### kongctl get portal snippets

Get Portal snippets.

{% include_cached /kongctl/help/get/portal/snippets.md %}

### kongctl get portal team-roles

Get Portal team roles.

{% include_cached /kongctl/help/get/portal/team-roles.md %}

### kongctl get portal teams

Get Portal teams.

{% include_cached /kongctl/help/get/portal/teams.md %}
