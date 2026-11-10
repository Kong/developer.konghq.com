---
title: kong-harnesses statusline
description: Render one status-bar line for the client that invokes it.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `statusline` command renders one status-bar line for the client that invokes it. The client writes its session document to stdin and displays what this command writes to stdout, so it is configured as the statusLine command in the client's settings.

## Command usage

{% include_cached kong-harnesses/help/statusline/index.md %}
