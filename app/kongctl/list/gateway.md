---
title: kongctl list gateway
description: "List gateways."
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

List gateways.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl list gateway control-plane](/kongctl/list/gateway/#kongctl-list-gateway-control-plane)
    description: "List gateway control planes."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/list/gateway/index.md %}

### kongctl list gateway control-plane

List gateway control planes.

{% include_cached /kongctl/help/list/gateway/control-plane.md %}
