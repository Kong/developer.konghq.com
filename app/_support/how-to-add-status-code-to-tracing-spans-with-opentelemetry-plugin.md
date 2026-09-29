---
title: How to add status code to tracing spans with the OpenTelemetry plugin
content_type: support
description: Add a `pre-function` plugin that sets the `http.status_code` attribute on the OpenTelemetry root tracing span, since the OpenTelemetry plugin doesn't include it by default.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I add a status code attribute to OpenTelemetry tracing spans in Kong?
  a: |
    Kong's OpenTelemetry plugin doesn't include a status code attribute in spans by default. Add a `pre-function` plugin that calls `kong.tracing.active_span():set_attribute("http.status_code", kong.response.get_status())` in `config.header_filter` — but note this only reaches the true root span when `tracing_instrumentations` is set to a lighter level like `request` or `router`; at `tracing_instrumentations = all` it attaches to a nested child span instead.
related_resources:
  - text: Built-in tracing instrumentations
    url: /plugins/opentelemetry/#built-in-tracing-instrumentations
  - text: Customize OpenTelemetry spans as a developer
    url: /plugins/opentelemetry/#create-a-custom-span
---

## Overview

How to add status code to tracing spans with OpenTelemetry plugin?

## Steps

By default, the OpenTelemetry plugin will not include a status code attribute in spans.

We could apply a `pre-function` plugin to include status code attribute in spans.

Below is an example configuration of the `pre-function` plugin

```lua

scope: global or the same service/route entity with OpenTelemetry plugin

config.header_filter:
local root_span = kong.tracing.active_span()
root_span:set_attribute("http.status_code", kong.response.get_status())
```

Next send some requests through kong and confirm the `http.status_code` attribute is in the root span.

Note: `kong.tracing.active_span()` only reliably returns the true root span at lighter `tracing_instrumentations` levels (e.g. `request` or `router`). At `tracing_instrumentations = all`, the active span in the `header_filter` phase is a nested per-plugin child span rather than the root span, so setting the attribute this way no longer attaches it to the root span in that configuration.
