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

How to avoid the OpenID Connect plugin obtaining a token from cache that is almost expired? Is there a setting where kong can obtain a new token just 10 or 15 secs before the cached token expired?

## Steps

Yes, it is possible by setting the `config.cache_ttl_max` to limit the max TTL for cache.

"Whether kong will get new token from IDP" depends on below 2 factor

(Here the IDP means OpenID Connect providers like Okta/Keycloak/AzureAD...)

(1) access token lifetime configured in the IDP side(2) `config.cache_tokens` configured in OpenID Connect plugin

Firstly please set `config.cache_tokens=true` in OpenID Connect plugin to enable cache function.

And kong will cache the token until it expired.

Next please confirm the access token lifetime in the IDP side and set `config.cache_ttl_max`

to avoid obtaining a token from cache that is almost expired.

For example, assuming the access token lifetime is 180s and we want to get a new token 15s before the access token expire. Then we need to set `config.cache_ttl_max=165`. (180-15=165)

The behavior as below

```

1. We send first request to Kong at 0s, 
OpenID Connect plugin will get a new access token from IDP and cache it. 
This access token is valid for 180s.

2. We send request again to Kong at 150s, 
then OpenID Connect plugin will get the existing access token from cache. 
Here the access token still valid for 30s(180-150=30).

3. We send request again to Kong at 166s, 
then OpenID Connect plugin will get a new access token from IDP. 
Because 166s is larger than 165s which has exceed `config.cache_ttl_max`. 
This new access token is valid for 180s.
```
