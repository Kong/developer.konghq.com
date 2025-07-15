---
title: deck gateway apply
description: Apply configuration to Kong without deleting existing entities.

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

The `deck gateway apply` command creates or updates entities in {{ site.base_gateway }} without deleting any existing configuration. `deck gateway apply` is useful when building your configuration incrementally.
For example:

```bash
echo '_format_version: "3.0"
services:
- name: example-service
  url: http://httpbin.konghq.com' | deck gateway apply
```

We recommend using [`deck gateway dump`](/deck/gateway/dump/) to back up the complete configuration to a file once you have finished iterating on your configuration. This file can then be used with [`deck gateway sync`](/deck/gateway/sync/).

## Command Usage

{% include_cached deck/help/gateway/apply.md %}
