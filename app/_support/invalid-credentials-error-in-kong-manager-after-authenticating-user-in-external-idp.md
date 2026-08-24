---
title: "\"Invalid credentials\" error in Kong Manager after authenticating user in external IDP"
content_type: support
description: An incorrect `admin_claim` configuration — not `consumer_claim` — causes Kong Manager to reject OIDC logins even after the external IdP authenticates successfully.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong Manager show an "Invalid credentials" error when authentication is successful in the external IdP?
  a: |
    Kong Manager's OIDC admin login always forces `consumer_optional=true`, so `consumer_claim` has no effect on admin auth — the field that actually controls it is `admin_claim` (default `email`). Confirm `admin_claim` is configured correctly and that the corresponding claim is present in the token returned by the external IdP.
---

## Problem

When enabling OIDC for authentication in Kong Manager, it redirects to the external IDP and you can verify the authentication is successful. But when it redirects back to Kong Manager, it shows an "Invalid credentials" error, even though authentication was successful in the external IDP.

## Solution

This behavior is caused by an incorrect configuration of the `admin_claim` attribute, not `consumer_claim`. Kong Manager's OIDC admin authentication always forces `consumer_optional=true`, so `consumer_claim` has no effect on admin login. The field that actually controls admin authentication is `admin_claim`, which defaults to `email`. Check that `admin_claim` is correctly configured, for example: `"admin_claim": "email"`, and that the corresponding claim is present in the token returned by the external IdP.

Note that an OIDC authentication failure in Kong Manager returns a generic 401 response, not the literal "Invalid credentials" string — that string is reserved for non-OIDC (basic/key/etc.) admin authentication failures.
