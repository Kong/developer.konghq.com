---
title: How to configure rate limiting by consumer from the openid-connect plugin
content_type: support
description: Configure rate limiting by consumer from the openid-connect plugin using `config.credential_claim` without mapping consumers in Kong.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I rate limit by consumer from the openid-connect plugin without mapping consumers in Kong?
  a: |
    Keep the rate limiting plugin on its default `config.limit_by = consumer`, and leave `config.consumer_claim` empty with `config.consumer_optional = false` so consumers aren't mapped in Kong.
    The openid-connect plugin then rate limits by the token's `sub` claim via `config.credential_claim` (default `sub`); point it at another claim, such as `tenant`, if you identify the consumer differently.
related_resources: []
---

## Overview

When configuring rate limiting by consumer, the consumer should be taken from the subject authenticated by the openid-connect plugin, but the consumer should not exist in Kong. How can this be configured?

## Steps

Regarding the rate limiting (or rate limiting advanced) plugin, you need to make sure it has configured `config.limit_by = consumer` (default value). Then, the openid-connect plugin by default tries to search claim `sub` inside the token and if that exists, the rate limiting plugin can rate limit by that, which is configurable with `config.credential_claim`.

`sub` is the Subject Identifier: a locally unique and never reassigned identifier within the Issuer for the End-User, which is intended to be consumed by the Client.

You can also use `config.consumer_claim` and `config.consumer_optional` and then apply rate limit to specific consumers. So, if it is not required to map the consumers in Kong, you need to set:

```
config.consumer_claim = // empty, default value
config.consumer_optional = false // default value - you don't want to map the consumers in Kong
```

Then, you also need to make sure the token includes the `sub` claim. If so, you can keep the default value `config.credential_claim = sub` - but if you identify the consumer by the tenant for example you should set `config.credential_claim = tenant`.
