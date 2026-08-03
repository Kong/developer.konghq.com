---
title: How to create global plugins when converting OpenAPI spec to declarative Kong config
content_type: support
description: The `x-kong-plugin` extension only adds plugins at the service level, so global plugins must be added manually to the declarative config after conversion.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I create global plugins when converting an OpenAPI spec to declarative Kong config?
  a: |
    The `x-kong-plugin` extension only attaches plugins at the service or route level, not globally.
    After running `deck file openapi2kong`, add the global plugin to a `plugins:` entry in the declarative config by hand, then sync it with a tag, for example `deck gateway sync --select-tag global-plugins`, to avoid affecting the rest of the workspace.
related_resources:
  - text: rate limiting advanced plugin basic example
    url: /plugins/rate-limiting-advanced/how-to/basic-example/
  - text: "`deck_sync` flags reference"
    url: /deck/reference/deck_sync/#flags
---

## Overview

When using the `x-kong-plugin` property in the OpenAPI spec file it adds the plugin to the service level. How can I add the plugin globally?

## Steps

The decK `file openapi2kong` command converts OpenAPI spec to declarative config for Kong using Kong APIOps. When using the `x-kong-plugin` custom extension in the OpenAPI spec file can help to generate plugin config in the declarative config for Kong for routes and services. But for the plugin at the global level, it is not supported. You may need to manually add a plugins entry in the declarative configuration file after you have generated the declarative config.

For example, if you want to enable the rate limiting advanced plugin globally you can create the following `rla-global.yaml` file:

```yaml
_format_version: "3.0"
_workspace: test
plugins:
- name: rate-limiting-advanced
  tags:
    - global-plugins
  config:
    limit:
    - 5
    window_size:
    - 30
    identifier: consumer
    sync_rate: -1
    namespace: example_namespace
    strategy: local
    hide_client_headers: false
```

Then, you can use the decK command `deck gateway sync --select-tag global-plugins` with the `--workspace` flag to determine which Kong workspace you want to sync.

Note it is important to add `--select-tag global-plugins` in this case, otherwise it will affect all the configuration in the workspace. Using the created `rla-global.yaml` file you can enable the rate-limiting-advanced plugin globally in the workspace “test” with the following command:

```bash
deck gateway sync --select-tag global-plugins --workspace test rla-global.yaml
```
