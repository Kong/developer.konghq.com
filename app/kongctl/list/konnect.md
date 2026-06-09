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
