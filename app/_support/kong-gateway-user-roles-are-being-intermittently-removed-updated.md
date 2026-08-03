---
title: "Kong Gateway: User roles are being intermittently removed/updated"
content_type: support
description: This can occur when you manually assign roles, either through Manager or the Admin API, but have also defined an `authenticated_groups_claim` in your `admin_gui_auth_conf`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do Kong Manager role assignments get intermittently removed or reset?
  a: |
    If you manually assign roles through Kong Manager or the Admin API but also configure `authenticated_groups_claim` in `admin_gui_auth_conf`, the group claim mapping takes precedence on each login and overwrites the manual role assignment. Either manage roles entirely through group mapping, or remove `authenticated_groups_claim` to stop the conflict.
related_resources:
  - text: Reference
    url: /gateway/kong-manager/auth/oidc/mapping/#main
---

## Problem

When using OIDC for Kong Manager login, it was noticed that the roles assigned are being intermittently removed/updated. After resetting the role via Manger/Admin API, the problem is fixed but will resurface shortly after. What is causing this issue?

## Solution

This can occur when you manually assign roles, either through Manager or the Admin API, but have also defined an `authenticated_groups_claim` in your `admin_gui_auth_conf`. When a user authenticates the group claim will be used to map a role within Kong. If this maps to a non-existent group or has a role with different permissions assigned, it will take precedence over the manual role updates. If you wish to manage roles based on the `authenticated_groups_claim`, you should properly define your roles and refrain from managing the permissions through the Manager/API. If you do not wish to do role mapping, the claim can simply be removed to avoid the conflict.
