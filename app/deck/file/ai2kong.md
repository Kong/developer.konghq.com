---
title: deck file ai2kong
description: Convert a state file that uses the {{site.ai_gateway}} 2.0 entity model to Kong Services and Routes.

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

tags:
  - openapi
  - declarative-config
---

This command takes a state file in {{site.ai_gateway}} 2.0 format and converts it to a standard decK state file for use with a self-managed (on-prem) {{site.base_gateway}}.
It also adds the `managed_by:deck-ai` tag to all entities by default.

The source file may be provided in either YAML or JSON; the format is auto-detected. The output format is controlled by the `--format` flag.

## Convert an {{site.ai_gateway}} 2.0 file to a {{site.base_gateway}} state file

Converting an OpenAPI file to a Kong declarative configuration can be done in a single command:

```bash
deck file ai2kong --source ai-gateway-2.yaml --output-file kong.yaml
```

## Command usage

{% include_cached deck/help/file/ai2kong.md %}
