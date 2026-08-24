---
title: OIDC authenticated group mapping fails when using the `groups` claim with Azure AD
content_type: support
description: "With Azure AD as the IdP, use the `roles` claim (not `groups`) as the `authenticated_groups_claim` so RBAC role mapping resolves correctly, since the `groups` claim only contains UUIDs."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why doesn't OIDC authenticated group mapping work with the `groups` claim in Azure AD?
  a: |
    Azure AD's `groups` claim returns UUIDs, so mapping `authenticated_groups_claim` to `groups` won't match your RBAC role names. Use the `roles` claim instead, and assign string values in the format `<workspace_name>:<role_name>` (e.g. `default:super-admin`) to the Azure AD app roles. If mapping still doesn't work, enable `debug` log level on Kong and check log entries prefixed with `[openid-connect]`.
---

## Problem

We are trying to set up openid-connect authentication in Kong Manager with OIDC Authenticated Group Mapping with Azure AD using `authenticated_groups_claim` set to `groups`, but since the `groups` claim only contains UUIDs, this does not lead to the user logging in getting the correct RBAC role assigned. How can we fix this?

## Solution

With Azure AD as the IdP, you should not use `groups` as the `authenticated_groups_claim`, but use `roles` instead. When setting up roles in Azure AD, you can assign string values to the `roles` claim that match the requirement necessary for the group mapping to work. As per documentation, the claim needs to have string values of the format `<workspace_name>:<role_name>`, e.g. `default:super-admin`, for mappings to be successful.

If you have tried setting roles in the way that should work as per the Kong documentation but still do not see the correct role assignment when logging in, enable `debug` log level on Kong, and check the log entries prefixed with `[openid-connect]` to see what is not working correctly during the login process.
