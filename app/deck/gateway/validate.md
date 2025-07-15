---
title: deck gateway validate
description: Validate the data in the provided state file against a live Admin API.

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

The `deck gateway validate` command reads one or more declarative state files and ensures validity. It reports YAML/JSON parsing issues, checks for foreign relationships, and alerts if there are broken relationships or missing links present.

This command also validates against the Admin API via communication with {{site.base_gateway}}. This increases the time for validation but catches significant errors. No resource is created in {{site.base_gateway}}.

For offline validation, see [deck file validate](/deck/file/validate/).

## Validate specific entities

The `deck gateway validate` command may take a long time to check all entities if you have a large state file.

To reduce this time, you can provide the `--online-entities-list` flag and specify specific entities to validate.
For example:

```bash
deck gateway validate --online-entities-list Plugins kong.yaml
```

## Command Usage

{% include_cached deck/help/gateway/validate.md %}