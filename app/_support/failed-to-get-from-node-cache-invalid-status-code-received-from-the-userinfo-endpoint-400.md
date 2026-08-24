---
title: "\"failed to get from node cache: invalid status code received from the userinfo endpoint (400)\" error when using the OpenID Connect plugin with Azure AD"
content_type: support
description: "Kong rejects Azure AD access tokens with a userinfo endpoint 400 error when the token's `iss` claim doesn't match the issuer configured in the OpenID Connect plugin."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Reference"
    url: "/plugins/openid-connect/examples/azure-ad/#openid-connect-with-azure-ad"
tldr:
  q: "Why does Kong return \"failed to get from node cache: invalid status code received from the userinfo endpoint (400)\" when validating tokens from Azure AD with the OpenID Connect plugin?"
  a: |
    The token's `iss` (issuer) claim doesn't match the issuer configured in the OpenID Connect plugin. This happens when the Azure AD application manifest's `accessTokenAcceptedVersion` isn't set to `2`, which causes Azure AD to issue tokens with the v1 issuer (`https://sts.windows.net/tenant-id/`) instead of the expected v2 issuer (`https://login.microsoftonline.com/<tenant-id>/v2.0`). Set `accessTokenAcceptedVersion` to `2` in the Azure AD application manifest to fix the mismatch.
---

## Problem

After configuring the Open ID Connect plugin to validate against Microsoft Azure AD, and calling an API with the access token, Kong rejects the request with an error;

```

"message": "Unauthorized"
```

Checking the Kong error log shows the below messages;

```

unable to verify bearer token (invalid issuer (https://sts.windows.net/tenant-id/) was specified for access token, https://login.microsoftonline.com/<tenant-id>/v2.0 was expected)
```

```

[openid-connect] failed to get from node cache: invalid status code received from the userinfo endpoint (400)
```

## Solution

If the access token is decoded at https://jwt.io/, you can see the issuer details. For example;

```

"iss": "https://sts.windows.net/fa6xxxx-d29xxxxxxxx2ffbd3e39/"
```

The `iss` value is different from that configured in the plugin.

During the setup of the Application in Microsoft Azure, make sure the value of `accessTokenAcceptedVersion` in the manifest file of the Application is set to 2;

```

"accessTokenAcceptedVersion": 2
```

If `accessTokenAcceptedVersion` is set to null, the issuer assigned will be https://sts.windows.net/tenant-id/ rather than the expected https://login.microsoftonline.com/<tenant-id>/v2.0 and Kong will reject the call.
