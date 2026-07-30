---
title: Interacting with {{site.ai_gateway}} entities
short_title: decK ai
description: Manage {{site.ai_gateway}} entities on-prem with decK.
weight: 1000

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

tags:
  - declarative-config

search_aliases:
  - declarative configuration

breadcrumbs:
  - /deck/

---

decK provides the following tools for managing {{site.ai_gateway}} configuration:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [dump](/deck/ai/dump/)
    description: Export the current state of {{ site.ai_gateway }} to a file.
  - command: |
      [sync](/deck/ai/sync/)
    description: Update {{site.ai_gateway}} to match the state defined in the provided configuration.
{% endtable %}
