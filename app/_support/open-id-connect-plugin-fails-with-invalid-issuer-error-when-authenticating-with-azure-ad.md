---
title: "Open ID Connect plugin fails with 'invalid issuer' error when authenticating with Azure AD"
content_type: support
description: "When configuring the Open ID Connect plugin with Azure AD, the user authenticates successfully in the external IDP but it receives an Unauthorized error on Kong's side."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the Open ID Connect plugin fail with an "invalid issuer" error when authenticating with Azure AD?
  a: |
    Azure AD can return an access token whose issuer doesn't match the `issuer` configured in the OpenID Connect plugin, for example when the token comes from the Azure AD v1 endpoint but the plugin expects v2. Add the valid issuer values to `issuers_allowed` in the plugin config so Kong accepts tokens from the Azure AD v2 endpoints.
---

## Problem

I configured the Open ID Connect plugin with Azure AD. The user authenticates correctly in the external IDP, however on Kong there is an 'invalid issuer' error and the user is Unauthorized. How should I configure the plugin?

## Solution

When configuring the Open ID Connect plugin with Azure AD, the user authenticates successfully in the external IDP but it receives an Unauthorized error on Kong's side. The logs show an error like:

```
[openid-connect] invalid issuer (https://sts.windows.net/<tenant-id>/) was specified for access token, https://login.microsoftonline.com/<tenant-id>/v2.0 was expected
```

If you check out the token, the issuer (`iss`) contains the following value: https://sts.windows.net/<tenant-id>/

```json
{
  "iss": "https://sts.windows.net/<tenant-id>/",
  // and other properties of your token
}
```

The issuer is valid, but not the one Kong was expecting. This is configured in the OpenID Connect plugin, and you may have configured:

```json
"issuer": "https://login.microsoftonline.com/<domain>.onmicrosoft.com/v2.0/.well-known/openid-configuration"
```

To make your Kong plugin work with the Azure AD v2 endpoints, you need to add the following configuration for the OpenID Connect plugin:

```json
"issuers_allowed": [
  "https://sts.windows.net/<tenant-id>/",
  "https://login.microsoftonline.com/<tenant-id>/v2.0",
  "https://login.windows.net/<tenant-id>/v2.0"
]
```
