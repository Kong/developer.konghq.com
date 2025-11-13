---
title: deck gateway ping
description: Verify that decK can talk to the configured Admin API.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/gateway/

related_resources:
  - text: deck gateway commands
    url: /deck/gateway/
---

The `deck gateway ping` command checks that decK can contact the Admin API. This could be either the {{site.konnect_short_name}} API, or an on-prem installation.

`deck gateway ping` validates both network connectivity and authentication details.

## On-prem example

```bash
deck gateway ping --kong-addr https://example.com:8001
```

## Konnect example

```bash
deck gateway ping \
  --konnect-token $KONNECT_TOKEN \
  --konnect-addr https://us.api.konghq.com \
  --konnect-control-plane-name default
```

## Command usage

{% include_cached deck/help/gateway/ping.md %}