---
title: Kong Manager admin login fails when the casing of the email address doesn't match what's stored in Kong
content_type: support
description: "The `openid-connect` plugin has a property, `by_username_ignore_case`, that allows username values to be matched case-insensitively with Identity Provider claims."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong Manager admin login fail when the casing of the email address doesn't match what's stored in Kong?
  a: |
    The `openid-connect` plugin's `by_username_ignore_case` property matches usernames case-insensitively against Identity Provider claims. Add `"by_username_ignore_case": true` to the `admin_gui_auth_conf` configuration option used by Kong Manager to stop case mismatches from blocking admin logins.
---

## Problem

We are using `openid-connect` authentication with Kong Manager, and admins have had problems logging into Kong when the email address that was used to log in differs in terms of casing from what was created when the admin was created initially in Kong.

The kong logs show the following:

```

2026/09/07 08:31:41 [debug] 2072#0: *4289703 [lua] api_helpers.lua:141: validate_admin(): [api_helpers] Admin not found with user_name=Firstame.Lastname@mycompnay.com
```

But the Admin username in Kong is firstname.lastname@mycompany.com

How can we make sure that email addresses to log into Manager are NOT case sensitive.

## Solution

The `openid-connect` plugin has a property, i.e. `by_username_ignore_case`, which allows username values to be matched case-insensitively with Identity Provider claims. It is possible to match usernames case-insensitively by adding `"by_username_ignore_case": true` to the existing `admin_gui_auth_conf` configuration option used by Kong Manager as in the example in this KB article.
