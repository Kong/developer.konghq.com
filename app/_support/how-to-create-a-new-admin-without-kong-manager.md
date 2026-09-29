---
title: How to create a new admin without Kong Manager
content_type: support
description: Provides a bash script that creates a new Kong Manager admin, sets their password, and generates an RBAC token, all via the Admin API.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I create a new Kong admin with RBAC credentials without using Kong Manager?
  a: |
    Using only the Admin API and an existing `Kong-Admin-Token`, run a script that creates the admin, generates an invite/registration token, sets the admin's password, authenticates as the new admin to get a session ID, and then generates a new RBAC token for them, all without going through the Kong Manager UI.
related_resources: []
---

## Overview

How to create a new admin without Kong Manager

## Steps

There are 5 steps to creating a new administrator with RBAC credentials, without using the Admin API.

Beforehand you will need the following variables:

`$KONG_ADMIN` = Admin API endpoint

`$ADMIN_TOKEN` = The admin token of the creating admin, not the new admin.

`$EMAIL` = The email of the new admin

`$USERNAME` = The name of the new admin

`$PASSWORD` = The new password of the admin

The following script does the following operations all at once:

1. Create a new admin using `$USERNAME` and `$EMAIL` as the details

2. Generates the invite token

3. Sets the newly created admins password to the value of: `$PASSWORD` using the token generated in step 2

4. Authenticates with the Admin API using basic authentication with the new admins credentials

5. Generates a new RBAC Token for the new admin

```bash

#!/bin/bash

USERNAME="test-admin"
PASSWORD="test-password"
EMAIL="test-admin@test.com"
ADMIN_TOKEN="admin"
KONG_ADMIN="https://localhost:8444"

# 1. Creates a new admin
CREATE_DATA="{\"email\":\"$EMAIL\" ,\"username\":\"$USERNAME\",\"rbac_token_enabled\":true}"
printf "Generating new admin with the following JSON: $CREATE_DATA ..."

CREATE_RESPONSE=$(curl -sk --location --request POST $KONG_ADMIN/admins \
--header "Kong-Admin-Token:$ADMIN_TOKEN" \
--header "Content-Type:application/json" \
--data-raw "$CREATE_DATA")

NAME=$(echo $CREATE_RESPONSE | jq .admin.username -j )

if [[ $USERNAME == $NAME ]]
then
    printf "SUCCESS"
else
    printf "FAILED"
    exit 1
fi

# 2. Generates the invite token
printf "\nGenerating invite token ..."

INVITE_RESPONSE=$(curl -sk --location --request GET $KONG_ADMIN/admins/$NAME \
--header "Content-Type:application/json" \
--header "Kong-Admin-Token:$ADMIN_TOKEN" \
--data-raw '{"generate_register_url":true}')

TOKEN=$(echo $INVITE_RESPONSE | jq .token -j)

if [[ $TOKEN != "" ]]
then
    printf "SUCCESS"
else
    printf "FAILED"
    exit 1
fi

# 3. Sets a password for the admin
printf "\nSetting new admin password ..."
SET_PASSWORD_DATA="{\"username\":\"$NAME\",\"email\":\"$EMAIL\",\"token\":\"$TOKEN\",\"password\":\"$PASSWORD\"}"

SET_PASSWORD_RESPONSE=$(curl -skv --location --request POST $KONG_ADMIN/admins/register \
--header "Kong-Admin-Token:$ADMIN_TOKEN" \
--header "Content-Type:application/json" \
--data-raw "$SET_PASSWORD_DATA" 2>&1)

SUB_STRING="201 Created"
if [[ $SET_PASSWORD_RESPONSE == *"$SUB_STRING"* ]]
then
    printf "SUCCESS"
else
    printf "FAILED"
    exit 1
fi

BASE64_ENCODED_AUTH=$(echo -n $USERNAME:$PASSWORD | base64 )

# printf "\n\n$BASE64_ENCODED_AUTH"

# 4. Authenticates and gets a session ID
printf "\nAuthorising new admin and retrieving session id ..."
GET_SESSION_RESPONSE=$(curl -skv --location --request GET $KONG_ADMIN/auth \
  -H "Authorization: Basic $BASE64_ENCODED_AUTH" \
  -H "Kong-Admin-User: $USERNAME" 2>&1 )

SESSION_ID=$(echo "$GET_SESSION_RESPONSE" | grep "Set-Cookie" | cut -d ";" -f 1 | cut -d " " -f 3)

if [[ $SESSION_ID != "" ]]
then
    printf "SUCCESS"
    printf "\nSession ID: $SESSION_ID"
else
    printf "\nFailed to get session id"
    exit 1
fi

# 5. Generates a new RBAC Token for the new admin
printf "\nGenerating RBAC Token for new admin ..."
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
    printf "FAILED"
    exit 1
fi
```
