---
title: deck file kong2ai
description: Convert a decK state file using Kong Gateway Services, Routes, and AI plugins to the AI Gateway 2.0 entity model.

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
  - ai
  - declarative-config
---

This command takes a standard decK state file and converts it to an {{site.ai_gateway}} 2.0 entity model. This can be used to migrate an existing {{site.base_gateway}} configuration that uses AI plugins to {{site.ai_gateway}}.

The conversion is best-effort: AI plugins are detected in the configuration, while entities without {{site.ai_gateway}} representation are reported as warnings.

The state file may be provided in either YAML or JSON; the format is auto-detected. The output format is controlled by the `--format` flag.

## Convert a {{site.base_gateway}} state file to an {{site.ai_gateway}} 2.0 file

Export a {{site.base_gateway}} state file from your existing {{site.base_gateway}} deployment. Then convert it to an {{site.ai_gateway}} 2.0 state file:
```bash
deck file kong2ai --state kong.yaml --output-file ai.yaml
```

## Command usage

{% include_cached deck/help/file/kong2ai.md %}
