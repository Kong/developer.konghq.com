---
title: "Kong Konnect: Using a Service Account without an email address with OIDC for the Developer Portal"
content_type: support
description: Remove the `email` scope from the OIDC identity provider configuration on the Konnect Developer Portal so Service Accounts without an email address can log in.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can we log in to the Konnect Developer Portal with a Service Account (no email) using OIDC?
  a: |
    Remove the `email` scope from the identity provider configuration under Developer Portal > Settings > Identity > edit Provider > Advanced Settings. This lets accounts without an email address complete OIDC login.
related_resources: []
---

## Problem

We are utilizing OIDC with a Konnect Developer portal.

We need to setup a Service Account (an account with no email address). However we're getting the following error when trying to log in.

```

"loginError=oidc+callback+error"
```

If we log in with our standard user account (an account with an email), it logs in successfully using OIDC.

How can we log in with a Service Account?

## Solution

In this specific instance when trying to setup a Service Account (no email) we need to make sure that the `email` scope is removed from the Identity tab. To do this we can go to the Developer portal tab -> Settings -> Identity -> "edit Provider". Once there, we can see under Advanced Settings and remove the scope `email` under scopes. Lastly, we need to verify that the user accounts and email accounts can log in successfully. If you continue to receive this error message after this, please reach out to Kong Support and we can look further into it.
