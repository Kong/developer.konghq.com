---
title: "How to reset password by 'Reset Password' link without SMTP server"
content_type: support
description: This article explains how to reset an admin or RBAC user's password using the Reset Password link when no SMTP server is configured.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I reset an admin or RBAC user's password using the Reset Password link when there's no SMTP server configured?
  a: |
    In Kong Manager, open the invited user and click `Generate registration link` to get a registration link without needing an email from an SMTP server. Copy the link and open it at `{Your kong manager URL: 8002}/{copied registration link in step 3}` to reach the reset password page.
---

## Overview

Sometimes, you'd like to reset the password by clicking the `Reset Password` link. However, there is no SMTP server. This article teaches you how to reset the password by clicking the `Reset Password` link without SMTP server.

## Steps

1. Invite an admin user or RBAC user through Kong Manager.
2. Click the invited user.
3. Click `Generate registration link`.
4. Copy the registration link.
5. Access the reset password page at `{Your kong manager URL: 8002}/{copied registration link in step 3}`.
