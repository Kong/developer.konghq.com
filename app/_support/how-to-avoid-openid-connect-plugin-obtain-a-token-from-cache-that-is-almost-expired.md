---
title: How to avoid the OpenID Connect plugin obtaining a token from cache that is almost expired
content_type: support
description: Explains how to set `config.cache_ttl_max` on the OpenID Connect plugin so Kong requests a new access token before the cached token expires.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I avoid the OpenID Connect plugin obtaining a token from cache that is almost expired?
  a: |
    Set `config.cache_ttl_max` on the OpenID Connect plugin to a value lower than the access token's actual lifetime (as configured in the IDP). Kong will then request a new token from the IDP once the cached token's age passes that threshold, instead of reusing a token that is about to expire. For example, with a 180s access token lifetime, setting `config.cache_ttl_max=165` gets a new token 15s before expiry.
related_resources:
  - text: OpenID Connect plugin documentation
    url: /plugins/openid-connect/
---

## Overview

By default, the OpenID Connect plugin caches access tokens until they expire. This means Kong can serve a cached token that is only seconds from expiring, which may cause the downstream request to fail. You can use `config.cache_ttl_max` to set an upper limit on how long a token stays in cache, so Kong fetches a fresh token before the cached one expires.

## Steps

Whether Kong fetches a new token from the IDP (such as Okta, Keycloak, or Azure AD) depends on two things:

- The access token lifetime configured in the IDP
- The `config.cache_ttl_max` value set on the OpenID Connect plugin

To configure early token refresh:

1. Set `config.cache_tokens=true` on the OpenID Connect plugin to enable token caching.

2. Check the access token lifetime in your IDP configuration.

3. Set `config.cache_ttl_max` to the token lifetime minus the buffer you want. For example, with a 180-second token lifetime and a 15-second buffer, set `config.cache_ttl_max=165` (180 - 15 = 165).

With this configuration, Kong fetches a new token from the IDP once the cached token's age exceeds `config.cache_ttl_max`, rather than waiting for the token to fully expire.

## Example

Using a 180-second token lifetime and `config.cache_ttl_max=165`:

1. **At 0s:** The first request reaches Kong. The plugin fetches a new access token from the IDP, caches it, and forwards it to the upstream. The token is valid for 180s.

2. **At 150s:** Another request reaches Kong. The cached token is 150s old, which is under the 165s limit, so the plugin returns the cached token. The token is still valid for 30s (180 - 150 = 30).

3. **At 166s:** Another request reaches Kong. The cached token is 166s old, which exceeds `config.cache_ttl_max`. The plugin fetches a new access token from the IDP. The new token is valid for 180s.
