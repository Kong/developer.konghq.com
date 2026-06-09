---
title: kongctl adopt konnect
description: "Adopt {{site.konnect_short_name}} resources."
content_type: reference
layout: reference


works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/adopt/

related_resources:
  - text: kongctl adopt commands
    url: /kongctl/adopt/
---

Adopt {{site.konnect_short_name}} resources.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl adopt konnect analytics](/kongctl/adopt/konnect/#kongctl-adopt-konnect-analytics)
    description: "Adopt {{site.konnect_short_name}} {{site.observability}} resources into namespace management."
  - command: |
      [kongctl adopt konnect api](/kongctl/adopt/konnect/#kongctl-adopt-konnect-api)
    description: "Adopt an existing Konnect API into namespace management."
  - command: |
      [kongctl adopt konnect auth-strategy](/kongctl/adopt/konnect/#kongctl-adopt-konnect-auth-strategy)
    description: "Adopt an existing Konnect authentication strategy into namespace management."
  - command: |
      [kongctl adopt konnect control-plane](/kongctl/adopt/konnect/#kongctl-adopt-konnect-control-plane)
    description: "Adopt an existing Konnect control plane into namespace management."
  - command: |
      [kongctl adopt konnect dcr-provider](/kongctl/adopt/konnect/#kongctl-adopt-konnect-dcr-provider)
    description: "Adopt an existing Konnect DCR provider into namespace management."
  - command: |
      [kongctl adopt konnect event-gateway](/kongctl/adopt/konnect/#kongctl-adopt-konnect-event-gateway)
    description: "Adopt an existing Konnect Event Gateway into namespace management."
  - command: |
      [kongctl adopt konnect organization](/kongctl/adopt/konnect/#kongctl-adopt-konnect-organization)
    description: "Adopt organization resources into namespace management."
  - command: |
      [kongctl adopt konnect portal](/kongctl/adopt/konnect/#kongctl-adopt-konnect-portal)
    description: "Adopt an existing Konnect portal into namespace management."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/adopt/konnect/index.md %}

### kongctl adopt konnect analytics

The `analytics` command adopts [{{site.konnect_short_name}} {{site.observability}}](/observability/) resources into namespace management.

{% include_cached /kongctl/help/adopt/konnect/analytics.md %}

### kongctl adopt konnect api

Adopt {{site.konnect_short_name}} APIs.

{% include_cached /kongctl/help/adopt/konnect/api.md %}

### kongctl adopt konnect auth-strategy

Adopt {{site.konnect_short_name}} authentication strategies.

{% include_cached /kongctl/help/adopt/konnect/auth-strategy.md %}

### kongctl adopt konnect control-plane

Adopt {{site.konnect_short_name}} control plane configuration.

{% include_cached /kongctl/help/adopt/konnect/control-plane.md %}

### kongctl adopt konnect dcr-provider

Apply the KONGCTL-namespace label to an existing {{site.konnect_short_name}} DCR provider that is not currently managed by kongctl.

{% include_cached /kongctl/help/adopt/konnect/dcr-provider.md %}

### kongctl adopt konnect event-gateway

Apply the KONGCTL-namespace label to an existing {{site.konnect_short_name}} {{site.event_gateway_short}} Control Plane that is not currently managed by kongctl.

{% include_cached /kongctl/help/adopt/konnect/event-gateway.md %}

### kongctl adopt konnect organization

Adopt {{site.konnect_short_name}} organization settings.

{% include_cached /kongctl/help/adopt/konnect/organization.md %}

### kongctl adopt konnect portal

Adopt {{site.konnect_short_name}} Developer Portal configuration.

{% include_cached /kongctl/help/adopt/konnect/portal.md %}
