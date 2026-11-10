---
title: kong-harnesses budget
description: Refresh the budget numbers that the status bar shows.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `budget` command refreshes the budget numbers that the status bar shows. It asks the gateway for your budgets with a profile's saved access token and saves the answer next to the profile; it never signs in, renews the token, or asks questions. See the [budget subcommands](/kong-harnesses/budget/refresh/) for each command.

## Command usage

{% include_cached kong-harnesses/help/budget/index.md %}
