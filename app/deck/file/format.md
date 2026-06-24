---
title: deck file format
description: Convert decK files between decK and DB-less declarative formats.

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
  - text: decK file commands
    url: /deck/file/
tags:
  - declarative-config
---

The `format` command converts {{site.base_gateway}} configuration files between two declarative configuration formats: decK and Kong's built-in declarative format for DB-less mode.

The two formats differ in how Consumer Group-related entities are represented:

<!--vale off-->
{% table %}
columns:
  - title: Format
    key: format
  - title: Description
    key: desc
rows:
  - format: decK
    desc: |
      * Consumer Group plugins are nested under `consumer_groups[*].plugins`
      * Consumer Group memberships are nested under `consumers[*].groups`
      * Plugin partial links are nested under `plugins[*].partials`
  - format: Built-in DB-less
    desc: |
      * Consumer Group plugins are stored in a top-level `consumer_group_plugins` array
      * Memberships are stored in a top-level `consumer_group_consumers` array
      * Plugin partial links are stored in top-level `plugins_partials`
{% endtable %}
<!--vale on-->

## Command usage

{% include_cached deck/help/file/format.md %}
