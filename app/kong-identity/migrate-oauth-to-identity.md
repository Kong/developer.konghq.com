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
    - on-prem
    - konnect

description: This guide walks you through migrating from the Oauth2 plugin to Kong Identity with OIDC or OAuth Introspection.

related_resources:
  - text: "{{site.identity}} authorization servers"
    url: /identity/auth-servers/
tags:
  - authentication
  - migration

min_version:
  gatway: '3.15' 
---

This guide shows you how to migrate from the OAuth 2.0 legacy plugin to Kong Identity for an on-prem Kong Gateway Enterprise setup.

## Requirements

- An on-prem EE setup
- Access to the Kong Admin API
- The OAuth 2.0 legacy plugin for authentication wrokflows
- Admin access to the PostgreSQL database connected to the plugin
- A Konnect account
- Personal Access Token (PAT) linked to your account

## Migration overview

The migration follows this order:

1. Getting the existing credentials
1. Uploading the credentials to Kong Identity
1. Deactivating and deleting the OAuth 2.0 plugin

Check the folllowing sections to get the information that suit best your configuration. 

## Set up the Admin API URL

To call your Kong on-prem instance, use your Kong Admin API. When you run it locally, the default Admin API URL is `localhost:8001`. The command examples assume you run the commands from a local setup. If you're calling your Admin API from a different location, replace the  value by you're actual URL.

```sh
export KONG_ADMIN_API='localhost:8001'
```

## Get the Consumer credentials

The OAuth 2.0 plugin uses a PostgreSQL database to store credentials in the `oauth2_credentials` table. If they're hashed and you aren't stored anywhere else in plain text, you might need to create new unhashed credentials for this migration.

### List the existing Consumers

```sh
curl -s $KONG_ADMIN_API/consumers | jq
```

### Get the Consumer credentials
To get the existing credentials, run

{% navtabs "retrieve-credentials" %}
{% navtab "Per Consumer" %}

This commands gets the secrets from a single Consumer:

```sh
curl -s $KONG_ADMIN_API/consumers/acme-app/oauth2 | jq
```

{% endnavtab %}
{% navtab "All Consumers" %}

This command gets the secrets for all existing Consumers:

```sh
for consumer in $(curl -s $KONG_ADMIN_API/consumers | jq -r '.data[].username'); do
  echo "=== $consumer ==="
  curl -s "$KONG_ADMIN_API/consumers/$consumer/oauth2" | jq '.data[] | {name, client_id, client_secret, hash_secret}'
done
```

{% endnavtab %}
{% endnavtabs %}

## Create a {{site.identity}} authorization server

Create an authorization server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer), and save the `AUTH_SERVER_ID` variable:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Auth server example"
  description: "Auth server example"
  audience: "api://default"
capture:
  - variable: AUTH_SERVER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Export the environment variable:

```sh
export AUTH_SERVER_ID=$(echo "$_response" | jq -r ".id")
```

## Create a client and upload the existing credentials

Create a client in the authorization server using the [`/v1/auth-servers/{authServerId}/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient), and save the `CLIENT_ID` and `CLIENT_SECRET` variables:

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

## Configure the OIDC plugin on the service

```sh
curl -s "https://us.api.konghq.tech/v1/auth-servers/$AUTH_SERVER_ID" \
  -H "Authorization: Bearer $KONNECT_TOKEN" | jq -r '.issuer'
```

Save the `$ISSUER` environment variable.


Attach the plugin to the service:

```sh
curl -s -X POST localhost:8001/services/demo-service/plugins \
  -d "name=openid-connect" \
  -d "config.issuer=$ISSUER" \
  -d "config.client_id=acme-app-client-id" \
  -d "config.client_secret=acme-app-client-secret" \
  -d "config.auth_methods=client_credentials" \
  -d "config.consumer_claim=consumer_name" \
  -d "config.consumer_by=username" | jq
```

**Version warnings**

- `consumer_claim` vs `consumer_claims`: Kong Gateway ≥3.14 uses the plural `consumer_claims` (array). Older versions use singular `consumer_claim`: include two versions of the snippet?
- `consumer_by: username`: this tells the plugin to match the claim value against the Consumer's `username` field.

## Verify

Pull the token endpoint path: 

```sh
curl -s "$ISSUER/.well-known/openid-configuration" | jq -r '.token_endpoint'
```

Request a token from the new endpoint:

```sh
curl -s -X POST "$TOKEN_ENDPOINT" \
  -d "grant_type=client_credentials" \
  -d "client_id=acme-app-client-id" \
  -d "client_secret=acme-app-client-secret" | jq
```

Confirm the service accepts the token: 

```sh
curl -sk https://localhost:8443/demo/anything \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq
```

## Deactivate the OAuth 2.0 plugin

```sh
PLUGIN_ID=$(curl -s localhost:8001/services/demo-service/plugins | jq -r '.data[] | select(.name=="oauth2") | .id')

curl -s -X PATCH localhost:8001/plugins/$PLUGIN_ID \
  -d "enabled=false" | jq
```

## Delete the OAuth 2.0 plugin

```sh
curl -s -X DELETE localhost:8001/plugins/$PLUGIN_ID
```