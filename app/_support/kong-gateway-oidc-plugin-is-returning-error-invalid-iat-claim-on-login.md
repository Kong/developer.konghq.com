---
title: "{{site.base_gateway}}: OIDC plugin is returning error \"invalid iat claim\" on login"
content_type: support
description: This error occurs because the time of the host machine and the IDP are out of sync.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "OpenID Connect plugin reference"
    url: "/plugins/openid-connect/"
  - text: "Kong Manager OpenID Connect group mapping reference"
    url: "/gateway/kong-manager/openid-connect/#set-up-authenticated-group-mapping"
tldr:
  q: Why is the OIDC plugin returning an "invalid iat claim" error on login?
  a: |
    The host machine's clock and the identity provider's clock are out of sync, so the token's issued-at (`iat`) time looks invalid. Add a `leeway` value (for example, `60`) to the OpenID Connect plugin configuration to tolerate the clock difference.
---

## Problem

We have setup OIDC for Kong Manager and are running into the following error:

```
2023/04/25 14:46:00 [notice] 2174#0: *2908 [lua] responses.lua:21: [openid-connect] invalid iat claim (1682433961) was specified for id token, client: 172.19.0.1, server: kong, request: "GET /mockbin?code=l5eX_1cw5pSf6COqxsLXUpNO5vmCJBHPJaLdibtQWv4&state=itcXU_mgY2a901EzLnELHANv HTTP/1.1", host: "localhost:8000"
```

How can we resolve this?

## Cause

This error occurs because the time of the host machine and the IDP are out of sync. Typically, the `id_token` should be issued before it reaches your host machine.

## Solution

To allow for this minor time difference between host machine and IDP, we can add a `leeway` field to the OIDC configuration.

Setting this value to `60` will allow for a difference of 60 seconds and will allow you to resolve the original error.

Sample configuration:

```json
{
     "issuer": "{YOUR_IDP_URL}",
     "admin_claim": "email",
     "client_id": ["{CLIENT_ID}"],
     "client_secret": ["{CLIENT_SECRET}"],
     "authenticated_groups_claim": ["{CLAIM_NAME}"],
     "ssl_verify": false,
     "leeway": 60,
     "redirect_uri": ["{YOUR_REDIRECT_URI}"],
     "login_redirect_uri": ["{YOUR_LOGIN_REDIRECT_URI}"],
     "logout_methods": ["GET", "DELETE"],
     "logout_query_arg": "logout",
     "logout_redirect_uri": ["{YOUR_LOGOUT_REDIRECT_URI}"],
     "scopes": ["openid","profile","email","offline_access"],
     "auth_methods": ["authorization_code"]
 }
```
</content>
