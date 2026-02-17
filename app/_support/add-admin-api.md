---
# REQUIRED: The title that appears at the top of the page
title: Add an admin using the Admin API

# REQUIRED: Must be set to "support" for support articles
content_type: support

# OPTIONAL: A brief description of what this support article covers
# This appears in search results and meta tags
description: Create an admin using the Kong Admin API

# OPTIONAL: Which Kong products this article applies to
# Common values: gateway, konnect, mesh, insomnia, deck
products:
  - gateway


works_on:
  - on-prem


min_version:
  gateway: '3.4'

# OPTIONAL: Related resources that provide additional context
# Each entry should have a text label and a url
related_resources:
  - text: RBAC reference
    url: /gateway/kong-enterpise/rbac


# OPTIONAL: TL;DR section that appears at the top of the article
# Provides a quick question and answer summary
tldr:
  q: How do I create an admin using the Admin API instead of Kong Manager or Konnect?
  a: |
    Disable RBAC, create an REBAC user, with the super admin-role, and then re-enable RBAC. 

---

This guide demonstrates how to create admin users programmatically using the Kong Admin API. This is useful for automation, CI/CD pipelines, or when Kong Manager is not accessible.

## Disable RBAC

1. Temporarily disable RBAC to allow the creation of the initial super-admin user. Update your Kong configuration:

   ```bash
   # Set RBAC to off temporarily
   kong config set rbac off
   kong reload
   ```

## Create a super-admin user

1. Create an RBAC user:

   ```bash
   curl -X POST http://localhost:8001/rbac/users \
     -H 'Content-Type: application/json' \
     -d '{
       "name": "JPK1",
       "user_token": "JPK1"
     }'
   ```

2. Assign the super-admin role to the user:

   ```bash
   curl -X POST http://localhost:8001/rbac/users/JPK1/roles \
     -H 'Content-Type: application/json' \
     -d '{
       "roles": "super-admin"
     }'
   ```

## Re-enable RBAC

1. Re-enable RBAC in your Kong configuration:

   ```bash
   kong config set rbac on
   kong reload
   ```

2. Create the new admin using the super-admin token:

   ```bash
   curl -X POST http://localhost:8001/admins \
     -H 'Content-Type: application/json' \
     -H 'Kong-Admin-Token: JPK1' \
     -d '{
       "username": "test@example.com",
       "email": "test@example.com"
     }'
   ```

   Save the admin ID from the response for the next step.

## Assign role and register admin

1. Assign a role to the admin (replace `{ADMIN_ID}` with the ID from the previous step):

   ```bash
   curl -X POST http://localhost:8001/admins/{ADMIN_ID}/roles \
     -H 'Content-Type: application/json' \
     -H 'Kong-Admin-Token: JPK1' \
     -d '{
       "roles": "super-admin"
     }'
   ```

2. Generate a registration token for the admin:

   ```bash
   curl -X GET 'http://localhost:8001/default/admins/test@example.com?generate_register_url=true' \
     -H 'Kong-Admin-Token: JPK1'
   ```

   Copy the token from the response.

3. Register the admin with the token from the previous step:

   ```bash
   curl -X POST http://localhost:8001/admins/register \
     -H 'Content-Type: application/json' \
     -H 'Kong-Admin-Token: JPK1' \
     -d '{
       "email": "test@example.com",
       "username": "test@example.com",
       "password": "secure_password",
       "token": "TOKEN_FROM_PREVIOUS_STEP"
     }'
   ```

## Validate

Verify that the admin was created successfully by attempting to authenticate:

```bash
curl -X GET http://localhost:8002/ \
  -u test@example.com:secure_password
```

You should receive a successful response showing the Kong Manager interface or admin details, confirming that the admin user was created and can authenticate properly.
