---
title: kongctl list konnect
description: "List {{site.konnect_short_name}} resources."
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

List {{site.konnect_short_name}} resources.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl list konnect analytics](/kongctl/list/konnect/#kongctl-list-konnect-analytics)
    description: "The `analytics` command allows you to work with [{{site.konnect_short_name}} {{site.observability}}](/observability/) resources."
  - command: |
      [kongctl list konnect api](/kongctl/list/konnect/#kongctl-list-konnect-api)
    description: "List {{site.konnect_short_name}} APIs."
  - command: |
      [kongctl list konnect auth-strategy](/kongctl/list/konnect/#kongctl-list-konnect-auth-strategy)
    description: "List {{site.konnect_short_name}} authentication strategies."
  - command: |
      [kongctl list konnect dcr-provider](/kongctl/list/konnect/#kongctl-list-konnect-dcr-provider)
    description: "Use the `list` verb with the `dcr-provider` command to query {{site.konnect_short_name}} Dynamic Client Registration providers."
  - command: |
      [kongctl list konnect event-gateway](/kongctl/list/konnect/#kongctl-list-konnect-event-gateway)
    description: "List {{site.konnect_short_name}} event gateways."
  - command: |
      [kongctl list konnect gateway](/kongctl/list/konnect/#kongctl-list-konnect-gateway)
    description: "List {{site.konnect_short_name}} gateways."
  - command: |
      [kongctl list konnect organization](/kongctl/list/konnect/#kongctl-list-konnect-organization)
    description: "List {{site.konnect_short_name}} organizations."
  - command: |
      [kongctl list konnect portal](/kongctl/list/konnect/#kongctl-list-konnect-portal)
    description: "List {{site.konnect_short_name}} Portal configurations."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/list/konnect/index.md %}

### kongctl list konnect analytics

The `analytics` command allows you to work with [{{site.konnect_short_name}} {{site.observability}}](/observability/) resources.

{% include_cached /kongctl/help/list/konnect/analytics.md %}

### kongctl list konnect api

List {{site.konnect_short_name}} APIs.

{% include_cached /kongctl/help/list/konnect/api.md %}

### kongctl list konnect auth-strategy

List {{site.konnect_short_name}} authentication strategies.

{% include_cached /kongctl/help/list/konnect/auth-strategy.md %}

### kongctl list konnect dcr-provider

Use the `list` verb with the `dcr-provider` command to query {{site.konnect_short_name}} Dynamic Client Registration providers.

{% include_cached /kongctl/help/list/konnect/dcr-provider.md %}

### kongctl list konnect event-gateway

List {{site.konnect_short_name}} event gateways.

{% include_cached /kongctl/help/list/konnect/event-gateway.md %}

### kongctl list konnect gateway

List {{site.konnect_short_name}} gateways.

{% include_cached /kongctl/help/list/konnect/gateway.md %}

### kongctl list konnect organization

List {{site.konnect_short_name}} organizations.

{% include_cached /kongctl/help/list/konnect/organization.md %}

### kongctl list konnect portal

List {{site.konnect_short_name}} Portal configurations.

{% include_cached /kongctl/help/list/konnect/portal.md %}
