---
title: "Kong Gateway: Prevent the jwt-signer plugin from re-signing tokens"
content_type: support
description: Omitting the `access_token_upstream_header` config value in the `jwt-signer` plugin prevents the token from being re-signed before it's proxied upstream.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
published: false
tldr:
  q: Can I prevent the jwt-signer plugin from re-signing tokens?
  a: |
    Yes — omitting the `access_token_upstream_header` config value stops the `jwt-signer` plugin from re-signing tokens, though it also strips the authorization header sent upstream.
    For pure token validation without re-signing, use the OIDC plugin instead, setting `auth_methods` to `Bearer` and including `extra_jwks_uri`.
---

## Problem

We are using the `jwt-signer` plugin but have a use case that requires the token not be re-signed.

## Solution

Yes, omitting the value for the config value `access_token_upstream_header` will prevent the token from being re-signed. However, keep in mind this will also strip the authorization header to the upstream and in some cases will result in other authorization errors. If the desired result is simply token validation, the OIDC plugin can satisfy this use case. You could set `auth_methods` to `Bearer` and include the `extra_jwks_uri` parameter. This will allow validation of the token and proxying it to the upstream.
