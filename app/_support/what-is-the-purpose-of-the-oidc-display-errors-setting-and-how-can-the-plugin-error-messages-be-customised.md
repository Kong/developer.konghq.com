---
title: Purpose of the OIDC `display_errors` setting and customizing plugin error messages
content_type: support
description: "The `config.display_errors` toggle enables extra debugging detail in OpenID Connect plugin errors; use the Exit Transformer plugin to customize the error messages returned to clients."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "What is the purpose of the OIDC `display_errors` setting and how can the plugin error messages be customized?"
  a: |
    `config.display_errors` only controls whether extra debugging detail is added to errors; it does not suppress error responses, which are always returned.
    To change the error messages clients see, use the Exit Transformer plugin.
related_resources:
  - text: "debugging"
    url: "/plugins/openid-connect/#debugging-the-oidc-plugin"
  - text: "Exit Transformer plugin"
    url: "/plugins/exit-transformer/#main"
---

## Problem

When using the OpenID connect plugin the display errors toggle doesn't stop the plugin from returning error messages. This affects information leakage. How can the errors from this plugin be customized?

## Cause

Setting the `config.display_errors` toggle to true is meant for debugging, that is, it can offer extra information.

However, keeping it with its default value of false does not mean that no error will be shown.

## Solution

Here's an example of the `display_errors` setting in action.

Testing accessing a route with the wrong token gives this error:

```bash
❯ curl -H "Authorization: Bearer $TOKENBAD" http://proxy.kong.lan/auth/oidc

{"message":"An unexpected error occurred"}%
```

If however the `display_errors` setting is set to true then we get more info that can be useful for understanding why an error took place.

```bash
❯ curl -H "Authorization: Bearer $TOKENBAD" http://proxy.kong.lan/auth/oidc

{"message":"An unexpected error occurred (anonymous consumer was not found)"}%
```

The "Exit Transformer" plugin can be used for the customization of the OpenID connect plugin error messages.
