---
title: How to create a Kong Manager and RBAC user via Admin API
content_type: support
description: Explains how to create a Kong Manager admin user, assign it the `super-admin` RBAC role, and activate it entirely through the Admin API using an existing RBAC token.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I create a Kong Manager admin user and assign the super-admin RBAC role using only the Admin API?
  a: |
    With an existing RBAC token, POST to `/<workspace>/admins` to create the user, then POST to `/<workspace>/admins/<id>/roles` to assign the `super-admin` role. If SMTP isn't configured, generate a registration URL directly via `?generate_register_url=true` on the admin's endpoint and use it to activate the account and set a password, bypassing email verification.
related_resources: []
---

## Overview

If the user does not have access to Kong manager to invite user, how can they use Admin API (with RBAC token) to create new users?

## Steps

Prerequisites:

- A user needs to have an existing RBAC token

### Create new user

As I will be creating a super-admin, the user will be created in the default workspace.

```bash

curl http://<ADMIN_API_HOST>:<ADMIN_API_PORT>/<workspace>/admins \
-H "Kong-Admin-Token:<RBAC_TOKEN>" \
-H "Content-Type: application/json" \
-d '{"email":"<USER_EMAIL>","rbac_token_enabled":true,"username":"<USER_NAME>"}'
```

Response should be similar to below. Please note down `id`.

```json

{
 "admin": {
  "created_at": 1614061705,
  "updated_at": 1614061705,
  "id": "4cb58015-3394-4ee7-9eb7-519e820cec94",
  "rbac_token_enabled": true,
  "status": 4,
  "username": "<USER_NAME>",
  "email": "<USER_EMAIL>"
 }
}
```

### Assign role to the new user

Here we will be assigning `super-admin` role to this user, id `4cb58015-3394-4ee7-9eb7-519e820cec94`.

```bash

curl http://<ADMIN_API_HOST>:<ADMIN_API_PORT>/<workspace>/admins/4cb58015-3394-4ee7-9eb7-519e820cec94/roles \
-H "Kong-Admin-Token:<RBAC_TOKEN>" \
-H "Content-Type: application/json" \
-d '{"roles":"super-admin"}'
```

The response should come back as below.

```json

{
  "roles": [
    {
      "comment": "Full access to all endpoints, across all workspaces",
      "created_at": 1614084842,
      "id": "e72111a7-47c8-46b3-844f-895f0af4189a",
      "name": "super-admin",
      "is_default": false,
      "role_source": "local",
      "ws_id": "d478d5c9-4dc9-4bb6-9c67-fa4b6b76b823"
    }
  ]
}
```

If you have SMTP set up, this user should receive the invite to create password.

### Activate user and create password

To bypass the email verification, an RBAC user can generate the register url directly with Admin API.

```bash

curl http://<ADMIN_API_HOST>:<ADMIN_API_PORT>/<workspace>/admins/4cb58015-3394-4ee7-9eb7-519e820cec94?generate_register_url=true \
-H 'Kong-Admin-Token:<RBAC_TOKEN>'
```

You should get similar response as below:

```json

{
  "rbac_token_enabled": true,
  "belong_workspace": {
    "id": "d478d5c9-4dc9-4bb6-9c67-fa4b6b76b823",
    "name": "default",
    "created_at": 1614061000,
    "updated_at": 1614061000
  },
  "email": "<USER_EMAIL>",
  "username": "<USER_NAME>",
  "id": "1b8959ab-d45d-4e2b-8190-3ce47d6bd498",
  "status": 4,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MTQzNDYzODIsImlkIjoiZGVjN2M0MTktNzMwNC00YTU5LWFkNWItZDRmYTk2NzdhMWIwIn0.syMkow-XC3yCWuVCTViP47oubvECbv7IqhMNtRRiBJ4",
  "workspaces": [
    { "name": "*" },
    { "is_admin_workspace": true, "id": "d478d5c9-4dc9-4bb6-9c67-fa4b6b76b823", "name": "default" }
  ],
  "register_url": "http://<KONG_MANAGER_HOST>:<KONG_MANAGER_PORT>/register?email=<USER_EMAIL>&username=<USER_NAME>&token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MTQzNDYzODIsImlkIjoiZGVjN2M0MTktNzMwNC00YTU5LWFkNWItZDRmYTk2NzdhMWIwIn0.syMkow-XC3yCWuVCTViP47oubvECbv7IqhMNtRRiBJ4",
  "updated_at": 1614087069,
  "groups": {},
  "created_at": 1614087069
}
```

We can go to `http://<KONG_MANAGER_HOST>:<KONG_MANAGER_PORT>/register?email=<USER_EMAIL>&username=<USER_NAME>&token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MTQzNDYzODIsImlkIjoiZGVjN2M0MTktNzMwNC00YTU5LWFkNWItZDRmYTk2NzdhMWIwIn0.syMkow-XC3yCWuVCTViP47oubvECbv7IqhMNtRRiBJ4` to create password for new user `<USER_NAME>`.
