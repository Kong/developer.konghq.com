---
title: Exit Transformer Plugin replaces body and ignores Mocking Plugin
content_type: support
description: The Exit Transformer plugin triggers on a Mocking plugin response because both act on a Kong response exit, and Exit Transformer takes precedence.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the Exit Transformer plugin override the Mocking plugin's response body?
  a: |
    Both plugins act on a Kong response exit, and the Exit Transformer takes precedence over the Mocking plugin, so its body transformation overwrites the mocked response. To surface the Mocking plugin's response instead, read the existing `body.message` in the Exit Transformer rather than overwriting it, and return that value in the transformed response.
related_resources:
  - text: Doc Reference
    url: /custom-plugins/handler.lua/#plugins-execution-order
---

## Problem

We've previously configured the Exit Transformer (globally) and recently configured the Mocking Plugin for a specific route. The Mocking plugin will trigger off status 200 on the configured path, in this case "/echo". If we disable the Exit Transformer, then the Mocking plugin will return a successful response. However, we notice the body is being modified by the Exit Transformer instead of the Mocking plugin's responses. Why is the Exit Transformer plugin kicking off for a status 200, and how can we display the results from the Mocking plugin?

## Cause

The reason the Exit Transformer triggers off of a Mocking plugin is that the Exit Transformer kicks off for a Kong response exit. The Mocking plugin triggers a Kong response exit, and the Exit Transformer takes precedence over the Mocking plugin.

## Solution

It is possible to get the Mocking plugin results to display on top of the Exit Transformer plugin, but it takes some adjustments.

A sample code snippet to get both the Mocking Plugin and the Exit Transformer to trigger:

Snippet inside Exit Transformer:

```lua
   local new_body = {
      error = true,
      status = status,
      message = body.message .. ", arr!", --displays body from the mocking plugin
      exitTest = "Test Message from Exit Transformer" --Displays message from exit transformer
      }
    return status, new_body, headers
```

Response:

Now if you modify the body inside the Exit Transformer Plugin, this will take precedence over the Mocking Plugin.

```lua
    body.message = "overwrite body inside Exit Transformer"
    local new_body = {
      error = true,
      status = status,
      message = body.message
    }
    return status, new_body, headers
```

Response:
