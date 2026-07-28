---
title: About `admin_gui_auth_login_attempts` parameters
content_type: support
published: false
description: Explains the lockout behavior of the `admin_gui_auth_login_attempts` setting and how to manually unlock a disabled admin user.
products:
  - gateway
works_on:
  - on-prem
  - konnect
faqs:
  - q: What is the expected behavior when a number n > 0 is configured for `admin_gui_auth_login_attempts`?
    a: |
      See the [`admin_gui_auth_login_attempts`](/gateway/configuration/#admin-gui-auth-login-attempts) configuration reference.

      If the user attempts to log in more than `n` times continuously, the user is disabled (not deleted) and cannot log in for a week.
  - q: How do I enable or unlock that user manually?
    a: |
      First, check the user's ID using Kong Manager or the Admin API.

      Then, log in to the Kong database and delete the user from the `login_attempts` table, for example:

      ```sql
      delete from login_attempts where consumer_id = '<user-id>';
      ```
tldr:
  q: What happens when `admin_gui_auth_login_attempts` locks out a user, and how do I unlock them?
  a: |
    When `admin_gui_auth_login_attempts` is set to a number greater than 0, a user who exceeds that many continuous failed login attempts is disabled (not deleted) and locked out for a week. To unlock the user manually, find their ID using Kong Manager or the Admin API, then delete their row from the `login_attempts` database table.
related_resources: []
---

## About `admin_gui_auth_login_attempts` parameters
