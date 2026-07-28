---
title: "Migrating from OAuth 2.0 plugin to {{site.identity}}"
content_type: reference
layout: reference

permalink: /identity/migrate-oauth-to-identity

breadcrumbs:
  - /identity/
products:
    - identity

works_on:
    - konnect

description: This guide walks you through migrating from the Oauth2 plugin to Kong Identity with OIDC or OAuth Introspection.

related_resources:
  - text: "{{site.identity}} authorization servers"
    url: /identity/auth-servers/
tags:
  - auth
  - migration

min_version:
  gatway: '3.15' 
---

Describe existing setup with legacy OAuth plugin

## Retrieve the existing credentials

Stored in PG, in the in the `oauth2_credentials` table. 

### Per Consumer

```sh
curl -s localhost:8001/consumers/acme-app/oauth2 | jq
```

### Retrieve all Consumers credentials

```sh
for consumer in $(curl -s localhost:8001/consumers | jq -r '.data[].username'); do
  echo "=== $consumer ==="
  curl -s "localhost:8001/consumers/$consumer/oauth2" | jq '.data[] | {name, client_id, client_secret, hash_secret}'
done
```

## Create a {{site.identity}} authorization server

```sh
_response=$(curl -X POST "https://us.api.konghq.com/v1/auth-servers" \
     --no-progress-meter --fail-with-body  \
     -H "Authorization: Bearer $KONNECT_TOKEN"\
     -H "Content-Type: application/json" \
     --json '{
       "name": "Auth server example",
       "description": "Auth server example",
       "audience": "api://default"
     }')
```

Export the environment variables:

```sh
export AUTH_SERVER_ID=$(echo "$_response" | jq -r ".id")
export ISSUER_URL=$(echo "$_response" | jq -r ".issuer")
```

## Create a client and upload the existing credentials

```sh
curl -s -X PUT "https://us.api.konghq.tech/v1/auth-servers/$AUTH_SERVER_ID/clients/acme-app-client-id" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "acme-app",
    "client_secret": "acme-app-client-secret",
    "grant_types": ["client_credentials"],
    "response_types": ["token"]
  }' | jq
  ```

  Export the environment variables:

  ```sh
export CLIENT_ID=$(echo "$_response" | jq -r ".id")
export CLIENT_SECRET=$(echo "$_response" | jq -r ".client_secret")
```

**Warn about**

- `client_id` must be ≤36 chars matching [-_\w]+ — so if a legacy `client_id` has characters outside that set, it can't be uploaded as-is and needs remapping.
- `grant_types` here only allows `implicit` or `client_credentials`: `authorization_code` isn't in the enum.

## Map the Consumer via a claim

```sh
curl -s -X POST "https://us.api.konghq.tech/v1/auth-servers/$AUTH_SERVER_ID/claims" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "consumer_name",
    "value": "acme-app",
    "include_in_token": true,
    "include_in_all_scopes": true,
    "enabled": true
  }' | jq
```
