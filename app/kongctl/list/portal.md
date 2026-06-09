---
title: kongctl list portal
description: "List Portal configurations."
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

Use the `list` verb with the `portal` command to query {{site.konnect_short_name}} portals.

kongctl provides the following tools for listing resources and resource details for {{site.konnect_short_name}} portals:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl list portal application-registrations](/kongctl/list/portal/#kongctl-list-portal-application-registrations)
    description: "Use the `registrations` command to list or retrieve application registrations for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal applications](/kongctl/list/portal/#kongctl-list-portal-applications)
    description: "Use the `applications` command to list or retrieve applications for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal assets](/kongctl/list/portal/#kongctl-list-portal-assets)
    description: "Use the `assets` command to fetch logo and favicon images for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal auth-settings](/kongctl/list/portal/#kongctl-list-portal-auth-settings)
    description: "Use the `auth-settings` command to fetch authentication settings for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal developers](/kongctl/list/portal/#kongctl-list-portal-developers)
    description: "Use the `developers` command to list or retrieve developers for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal email-domains](/kongctl/list/portal/#kongctl-list-portal-email-domains)
    description: "Use the `email-domains` command to list custom email domains that can be used for portal emails."
  - command: |
      [kongctl list portal identity-providers](/kongctl/list/portal/#kongctl-list-portal-identity-providers)
    description: "Use the `identity-providers` command to list identity providers for a {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal pages](/kongctl/list/portal/#kongctl-list-portal-pages)
    description: "Use the `pages` command to list or retrieve custom pages for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal snippets](/kongctl/list/portal/#kongctl-list-portal-snippets)
    description: "Use the `snippets` command to list or retrieve custom snippets for a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal team-roles](/kongctl/list/portal/#kongctl-list-portal-team-roles)
    description: "Use the `team-roles` command to list role assignments for teams in a specific {{site.konnect_short_name}} portal."
  - command: |
      [kongctl list portal teams](/kongctl/list/portal/#kongctl-list-portal-teams)
    description: "Use the `teams` command to list or retrieve developer teams for a specific {{site.konnect_short_name}} portal."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/list/portal/index.md %}

### kongctl list portal application-registrations

List Portal application registrations.

{% include_cached /kongctl/help/list/portal/application-registrations.md %}

### kongctl list portal applications

List Portal applications.

{% include_cached /kongctl/help/list/portal/applications.md %}

### kongctl list portal assets

List Portal assets.

{% include_cached /kongctl/help/list/portal/assets.md %}

### kongctl list portal auth-settings

List Portal authentication settings.

{% include_cached /kongctl/help/list/portal/auth-settings.md %}

### kongctl list portal developers

List Portal developers.

{% include_cached /kongctl/help/list/portal/developers.md %}

### kongctl list portal email-domains

List Portal email domains.

{% include_cached /kongctl/help/list/portal/email-domains.md %}

### kongctl list portal identity-providers

Use the `identity-providers` command to list identity providers for a {{site.konnect_short_name}} portal.

{% include_cached /kongctl/help/list/portal/identity-providers.md %}

### kongctl list portal pages

List Portal pages.

{% include_cached /kongctl/help/list/portal/pages.md %}

### kongctl list portal snippets

List Portal snippets.

{% include_cached /kongctl/help/list/portal/snippets.md %}

### kongctl list portal team-roles

List Portal team roles.

{% include_cached /kongctl/help/list/portal/team-roles.md %}

### kongctl list portal teams

List Portal teams.

{% include_cached /kongctl/help/list/portal/teams.md %}
