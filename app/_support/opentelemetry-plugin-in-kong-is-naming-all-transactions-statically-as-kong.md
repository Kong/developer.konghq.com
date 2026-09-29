---
title: "OpenTelemetry plugin in Kong is naming all transactions statically as \"kong\""
content_type: support
description: A pre-function plugin can set the OpenTelemetry trace name to include the request method and path, working around Kong naming all transactions statically as "kong".
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Kong PR that introduced this change"
    url: "https://github.com/Kong/kong/pull/10577"
tldr:
  q: Why does the OpenTelemetry plugin name all transactions statically as "kong"?
  a: |
    A change in {{site.base_gateway}} made the OpenTelemetry plugin use a static "kong" trace name instead of the protocol/method/host/port/path format. Work around it with a global pre-function (Serverless Functions) plugin that sets `root_span.name` from the request method and path in the `header_filter` phase.
---

## Problem

The OpenTelemetry plugin names all transactions statically as "kong" instead of using the expected format with the protocol, method, host, port, and path.

## Cause

The change in question was introduced in this PR.

## Solution

To work around this issue you can enable a global pre-function plugin that sets the trace name to include the method and path, as shown below.

Here is the Lua code snippet that you can use in a Serverless Functions plugin to dynamically set the trace name:

```lua
header_filter:
local root_span = kong.tracing.active_span()
local path = kong.request.get_path()
local method = kong.request.get_method()
root_span.name = method .. " " .. path
```

You can find more information on how to use the Serverless Functions plugin in the Kong documentation: Serverless Functions.
