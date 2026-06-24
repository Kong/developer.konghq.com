---
title: kongctl get gateway
description: "Get gateway information."
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

Get gateway information.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get gateway control-plane](/kongctl/get/gateway/#kongctl-get-gateway-control-plane)
    description: "Get gateway control plane."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/gateway/index.md %}

### kongctl get gateway control-plane

Get gateway control plane.

{% include_cached /kongctl/help/get/gateway/control-plane.md %}
