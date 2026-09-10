---
title: "\"Consumer was not found with access token\" error when the OIDC `consumer_claim` is missing from the token"
content_type: support
description: "This occurs when the claim defined in the OIDC `consumer_claim` field is not found in the token provided."
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: OpenID Connect plugin documentation
    url: /plugins/openid-connect/
tldr:
  q: Why does Kong show "Consumer was not found with access token" for OIDC consumer mapping?
  a: |
    The OIDC plugin's `consumer_claim` config value must exactly match (case-sensitively) a claim present in the token. If the token doesn't include that claim, Kong can't map the token to a consumer and logs this error. Fix it by including the claim in the token, or by changing `consumer_claim` to a claim that already exists in the token (for example, `azp`).
---

## Problem

When consuming an OIDC protected route or service you receive an error similar to the below in the Kong error log.

The name of the claim, in this example `email`, may be different in your environment. What is causing this issue?

```
Consumer was not found with access token (claim (email) was not found for consumer mapping)
```

## Solution

This occurs when the claim defined in the OIDC `consumer_claim` field is not found in the token provided.

For example:

The OIDC config has `consumer_claim = email`

If the token provided has the below payload the error will occur as it is missing the `email` claim.

```json
{
  "iss": "https://accounts.google.com",
  "azp": "329599xxxxxx.apps.googleusercontent.com",
  "aud": "329599xxxxxx.apps.googleusercontent.com",
  "sub": "20376685496334",
  "at_hash": "rN2G5jhTWjw8JEC",
  "iat": 1624462383,
  "exp": 1624465983
}
```

To address this you will need to either:

1. Include the claim as part of the token payload.
2. Change the `consumer_claim` to a value that exists in the token. For the above example, you could use `azp` for instance.

Note: The `consumer_claim` value is case sensitive. `Email` will not be treated the same as `email`.

More details on the OIDC plugin can be found in the OpenID Connect plugin documentation.
