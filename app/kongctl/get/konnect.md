---
title: kongctl get konnect
description: "Get {{site.konnect_short_name}} account information."
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

Get {{site.konnect_short_name}} account information.

## Command usage

{% include_cached /kongctl/help/get/konnect/index.md %}

### kongctl get konnect analytics

The `analytics` command allows you to work with [{{site.konnect_short_name}} {{site.observability}}](/observability/) resources.

{% include_cached /kongctl/help/get/konnect/analytics.md %}

### kongctl get konnect api

Get {{site.konnect_short_name}} API information.

{% include_cached /kongctl/help/get/konnect/api.md %}

### kongctl get konnect audit-logs

Get {{site.konnect_short_name}} audit logs.

{% include_cached /kongctl/help/get/konnect/audit-logs.md %}

### kongctl get konnect auth-strategy

Get {{site.konnect_short_name}} authentication strategy details.

{% include_cached /kongctl/help/get/konnect/auth-strategy.md %}

### kongctl get konnect dcr-provider

Use the `get` verb with the `dcr-provider` command to query {{site.konnect_short_name}} Dynamic Client Registration providers.

{% include_cached /kongctl/help/get/konnect/dcr-provider.md %}

### kongctl get konnect event-gateway

Use the `get` verb with the `event-gateway` command to query {{site.konnect_short_name}} {{site.event_gateway_short}}s.

{% include_cached /kongctl/help/get/konnect/event-gateway.md %}

### kongctl get konnect gateway

Get {{site.konnect_short_name}} gateway information.

{% include_cached /kongctl/help/get/konnect/gateway.md %}

### kongctl get konnect me

Get {{site.konnect_short_name}} user information.

{% include_cached /kongctl/help/get/konnect/me.md %}

### kongctl get konnect organization

Get {{site.konnect_short_name}} organization details.

{% include_cached /kongctl/help/get/konnect/organization.md %}

### kongctl get konnect pat

Get {{site.konnect_short_name}} [personal access tokens](/konnect-api/#konnect-api-authentication).

{% include_cached /kongctl/help/get/konnect/pat.md %}

### kongctl get konnect portal

Get {{site.konnect_short_name}} Portal configuration.

{% include_cached /kongctl/help/get/konnect/portal.md %}

### kongctl get konnect regions

Get {{site.konnect_short_name}} available regions.

{% include_cached /kongctl/help/get/konnect/regions.md %}

### kongctl get konnect spat

Get {{site.konnect_short_name}} [system account access tokens](/konnect-api/#konnect-api-authentication).

{% include_cached /kongctl/help/get/konnect/spat.md %}
