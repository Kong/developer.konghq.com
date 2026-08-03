---
title: Integrating 2FA, MFA, OTP, or captcha/recaptcha with Kong Manager
content_type: support
published: false
description: Kong Manager does not directly offer 2FA, MFA, OTP or captcha/Recaptcha.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I integrate 2FA, MFA, OTP, or captcha/recaptcha with Kong Manager?
  a: |
    Kong Manager does not directly support 2FA, MFA, OTP, or captcha/Recaptcha. Configure Kong Manager to use OIDC auth instead, and you can provide MFA (or similar) through the OIDC provider.
related_resources:
  - text: Configure OIDC authentication for Kong Manager
    url: /gateway/kong-manager/auth/oidc/configure/
---

## Overview

How can I integrate 2FA, MFA, OTP, or captcha/recaptcha with Kong Manager?

## Steps

Kong Manager does not directly offer 2FA, MFA, OTP or captcha/Recaptcha. However, if you configured Kong Manager to use OIDC auth then you could provide MFA etc via the OIDC provider.
