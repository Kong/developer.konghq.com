---
title: Configuration transformation with decK
description: "Provides multiple commands to manipulate an existing declarative configuration file"

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/file/

related_resources:
  - text: decK file management commands
    url: /deck/file/

skip_index: true
---

`deck file` provides multiple commands to manipulate an existing declarative configuration file. They can be used to update values in the configuration, add new plugins, and more.

<!--vale off-->
{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: "[patch](/deck/file/manipulation/patch/)"
    description: Update existing values.
  - command: "[add-tags](/deck/file/manipulation/tags/#add-tags)"
    description: Add tags to specific entities.
  - command: "[remove-tags](/deck/file/manipulation/tags/#remove-tags)"
    description: Remove tags from specific entities.
  - command: "[namespace](/deck/file/manipulation/namespace/)"
    description: Add a prefix to Routes that is stripped before sending to the upstream.
{% endtable %}
<!--vale on-->