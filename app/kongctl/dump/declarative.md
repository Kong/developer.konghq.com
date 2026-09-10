---
title: kongctl dump declarative
description: Export declarative configuration.
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/dump/

related_resources:
  - text: kongctl dump commands
    url: /kongctl/dump/
---

Export declarative configuration from {{site.konnect_short_name}}.

Use `--include-child-resources` to include children of the selected parent
resource types. Use `--skip-defaults` to omit literal API defaults while
preserving explicit `null` and non-default values.

To dump {{site.ai_gateway}} and its children, select the parent:

```sh
kongctl dump declarative \
  --resources ai_gateways \
  --include-child-resources
```

Direct {{site.ai_gateway}} child selectors aren't supported.


## Command usage

{% include_cached /kongctl/help/dump/declarative.md %}
