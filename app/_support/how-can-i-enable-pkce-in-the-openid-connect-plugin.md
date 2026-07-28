---
title: Enabling PKCE in the `openid-connect` plugin
content_type: support
published: false
description: The `openid-connect` plugin supports PKCE, and it sends the required `code_challenge` parameter automatically with the authorization code flow request.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I enable PKCE in the `openid-connect` plugin?
  a: |
    No plugin configuration is required. The `openid-connect` plugin supports PKCE and automatically sends the `code_challenge` parameter with the authorization code flow request. PKCE is used whenever the configured IdP enforces it, and is simply skipped when the IdP does not.
related_resources: []
---

## Overview

How can I enable the Proof Key for Code Exchange (PKCE) extension to the Authorization Code flow in the Kong `openid-connect` plugin?

## Steps

The `openid-connect` plugin supports PKCE, and it sends the required `code_challenge` parameter automatically with the authorization code flow request. This means that there is no configuration on the plugin side required. As long as the IdP that is configured to be used by the `openid-connect` plugin enforces PCKE, it will be used during the Authorization Code flow. If the IdP does not support or enforce PCKE, this will not be used but again, there is no need to set any specific configuration in the plugin.
