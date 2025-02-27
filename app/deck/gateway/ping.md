---
title: deck gateway ping
description: Verify that decK can talk to the configured Admin API

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
  - text: All decK documentation
    url: /index/deck/
---

The `deck file ping` command checks that decK can contact the Admin API. This could be either the {{site.konnect_short_name}} API, or an on-prem installation.

`deck file ping` validates both network connectivity and authentication details.
