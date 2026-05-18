---
title: Fix JWT Signer plugin keyset field warning on Konnect
content_type: support
description: How to fix the JWT Signer plugin keyset field warning when running on {{site.konnect_short_name}}.
products:
  - gateway
works_on:
  - konnect
tldr:
  q: How do I fix the JWT Signer plugin keyset field warning on Konnect?
  a: |
    Set the `access_token_keyset` or `channel_token_keyset` field to a URL that points to a valid JWKS endpoint. On {{site.konnect_short_name}}, JWKS must be managed externally.
---

## Understanding the warning

When using the JWT Signer plugin on {{site.konnect_short_name}}, you may see the following warning in your data plane logs:

```
*_token_keyset should be a valid URL when kong is running in Konnect mode, *_token_signing is true and *_token_upstream_header is set.
```

This warning appears when all of the following conditions are true:
- `access_token_signing` or `channel_token_signing` is set to `true`
- `access_token_upstream_header` or `channel_token_upstream_header` is set to a non-empty value
- `access_token_keyset` or `channel_token_keyset` is left empty

On {{site.konnect_short_name}}, all JWKS for the JWT Signer plugin must be managed externally. You must provide a URL that points to a valid JWKS endpoint for re-signing requests.

## Fixing the warning

Set the corresponding `*_token_keyset` field to the URL of the JWKS you want to use for re-signing:

```yaml
access_token_keyset: https://example.com/.well-known/jwks.json
```

Or for the channel token:

```yaml
channel_token_keyset: https://example.com/.well-known/jwks.json
```

## Validation

After updating the configuration, check the data plane logs. The warning should no longer appear.

