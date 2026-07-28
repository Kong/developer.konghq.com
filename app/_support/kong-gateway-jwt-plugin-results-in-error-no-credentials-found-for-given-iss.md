---
title: "Kong Gateway: JWT Plugin results in error \"No credentials found for given 'iss'\""
content_type: support
description: In this case, the `config.key_claim_name` is configured for `iss`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the JWT plugin return "No credentials found for given 'iss'"?
  a: |
    The `iss` claim value must exactly match (case-sensitive) the key configured for the consumer's JWT credential.
    Verify that the `iss` claim value matches its respective key value configured on the Consumer.
---

## Problem

We are testing out the JWT Plugin and are resulting in the following error.

```json
{"message":"No credentials found for given 'iss'"}
```

If we test this same token directly to the endpoint it is working as expected.

How can we resolve this issue?

## Cause

In this case, the `config.key_claim_name` is configured for `iss`. The value being entered into the `iss` claim is not matching the credentials for a consumer.

## Solution

For example - If the JWT plugin is deployed and a consumer is created with the value "testKey". The `iss` claim value must match "testKey". This value is case sensitive.

If the value is entered as "testkey" it will result in the error:

```json
{"message":"No credentials found for given 'iss'"}
```

To resolve this, please verify that the `iss` claim value matches its respective key value configured on the Consumer.
