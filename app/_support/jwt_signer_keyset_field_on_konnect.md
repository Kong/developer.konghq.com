---
title: Fix JWT Signer plugin keyset field warning on Konnect
content_type: support
description: How to fix the JWT Signer plugin keyset field warning when running on {{site.konnect_short_name}}.
products:
  - gateway
works_on:
  - konnect
tldr:
  q: How do I fix the JWT Signer plugin keyset field warning on {{site.konnect_short_name}}?
  a: |
    Set the `access_token_keyset` or `channel_token_keyset` field to a URL that points to a valid JWKS endpoint. On {{site.konnect_short_name}}, JWKS must be managed externally.
---

## Understanding the warning

The JWT Signer plugin on {{site.konnect_short_name}} writes one or both of the following warnings to the data plane logs when it detects a missing keyset URL:

```
access_token_keyset should be a valid URL when kong is running in Konnect mode, access_token_signing is true and access_token_upstream_header is set.
```
{:.no-copy-code}

```
channel_token_keyset should be a valid URL when kong is running in Konnect mode, channel_token_signing is true and channel_token_upstream_header is set.
```
{:.no-copy-code}

The warning appears when either of the following sets of conditions is true:

- `access_token_signing` is `true`, `access_token_upstream_header` is non-empty, and `access_token_keyset` is empty
- `channel_token_signing` is `true`, `channel_token_upstream_header` is non-empty, and `channel_token_keyset` is empty

{{site.konnect_short_name}} requires all JWKS for the JWT Signer plugin to be managed externally. Provide a URL that points to a valid JWKS endpoint for re-signing requests.

Without a configured `access_token_keyset` or `channel_token_keyset` value, `NULL` is sent to the data plane. Each data plane node then generates its own JWKS independently, making consistent downstream verification of re-signed tokens impossible.

## Fixing the warning

Set the corresponding `access_token_keyset` or `channel_token_keyset` field to the URL of the JWKS you want to use for re-signing.

For the access token:

```yaml
access_token_keyset: https://example.com/.well-known/jwks.json
```

For the channel token:

```yaml
channel_token_keyset: https://example.com/.well-known/jwks.json
```

## Validation

Restart or wait for the data plane to reload the updated configuration, then review the data plane logs. The keyset warning no longer appears.

