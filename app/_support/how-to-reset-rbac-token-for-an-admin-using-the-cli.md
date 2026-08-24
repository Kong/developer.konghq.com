---
title: How to reset RBAC token for an Admin using the CLI
content_type: support
description: The following script takes a username and password, converts it to a session, which is then used to log in to the `admin-api` and retrieve a new RBAC token for the authenticating admin.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I reset the RBAC token for a Kong Admin using the CLI?
  a: |
    Run a script that logs in with the admin's username and password to obtain a session cookie, then sends a `PATCH` request to `/admins/self/token` with that session to generate a new RBAC token. Update the `USERNAME`, `PASSWORD`, and `KONG_ADMIN` variables in the script before running it.
---

## Overview

How to reset RBAC token for an Admin using the CLI.

## Steps

The following script takes a username and password, converts it to a session, which is then used to log in to the `admin-api` and retrieve a new RBAC token for the authenticating admin.

Change the `USERNAME`, `PASSWORD`, and `KONG_ADMIN` variables as necessary.

```bash

#!/bin/bash

USERNAME="kong_admin"
PASSWORD="admin"
KONG_ADMIN="https://localhost:8444"

BASE64_ENCODED_AUTH=$(echo -n $USERNAME:$PASSWORD | base64 )

# printf "\n\n$BASE64_ENCODED_AUTH"

printf "\nAuthorising admin and retrieving session id ..."
GET_SESSION_RESPONSE=$(curl -skv --location --request GET $KONG_ADMIN/auth \
  -H "Authorization: Basic $BASE64_ENCODED_AUTH" \
  -H "Kong-Admin-User: $USERNAME" 2>&1 )

SESSION_ID=$(echo "$GET_SESSION_RESPONSE" | grep "Set-Cookie" | cut -d ";" -f 1 | cut -d " " -f 3)

if [[ $SESSION_ID != "" ]]
then
    printf "SUCCESS"
    printf "\nSession ID: $SESSION_ID"
else
    printf "FAILED\n"
    printf "$GET_SESSION_RESPONSE"
    exit 1
fi

printf "\nGenerating RBAC Token for admin ..."
RBAC_TOKEN_RESPONSE=$(curl -sk --location --request PATCH $KONG_ADMIN/admins/self/token \
  -H 'Content-Type: application/json' \
  -H "Cookie: $SESSION_ID" \
  -H "Kong-Admin-User: $USERNAME" \
  -d '{}')

NEW_RBAC_TOKEN=$(echo $RBAC_TOKEN_RESPONSE | jq .token -j )

if [[ $NEW_RBAC_TOKEN != "" ]]
then
    printf "SUCCESS"
    printf "\nNew admin RBAC token: $NEW_RBAC_TOKEN"
else
    printf "FAILED\n"
    printf "$RBAC_TOKEN_RESPONSE"
    exit 1
fi
```
