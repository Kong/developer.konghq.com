---
title: "OIDC Plugin: Sending the `refresh_token` does not refresh the authentication token"
content_type: support
published: false
description: With the {{site.base_gateway}} OIDC plugin, the refresh token must be sent on its own; if it is sent alongside the authentication token the refresh is ignored.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does sending the refresh token alongside the authentication token fail to refresh it?
  a: |
    The {{site.base_gateway}} OIDC plugin ignores the refresh token when it is sent together with the authentication token, and refuses authentication based on the expired token.
    Send the refresh token on its own, only when the client detects the authentication token has expired.
---

## Problem

An OIDC client sends the refresh token along with the authentication token, but the authentication token never refreshes.

## Solution

When using refresh tokens with the {{site.base_gateway}} OIDC plugin it is important the refresh token is sent on its own and not with the authentication token.

The OIDC client should check the expiration of the token and decide if a refresh is required. If this is the case then the refresh token should be sent from the client. If both tokens are sent the refresh is ignored and authentication is refused based on the authentication token's expired status.
