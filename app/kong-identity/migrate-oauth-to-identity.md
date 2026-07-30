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

You also need the proxy URL to verify the migration at the end of this guide. When you run Kong Gateway locally, the default HTTPS proxy URL is `https://localhost:8443`:

```sh
export KONG_PROXY_URL='https://localhost:8443'
```

### List the existing Consumers

```sh
curl -s $KONG_ADMIN_API/consumers | jq
```

The response lists all existing Consumers. If only one Consumer appears in the list, save it as an environment variable: 

```sh
export CONSUMER=$(curl -s $KONG_ADMIN_API/consumers | jq -r '.data[0].username')
```

If the list contains more than one Consumer, this guide contains scripts to help you bulk migrate them in the following sections. 

## Get the Consumer credentials

The OAuth 2.0 plugin uses a PostgreSQL database to store credentials in the `oauth2_credentials` table. If they secret is hashed, you can't extract the original secret, as Kong only stores the hash. You can create a new credential with a fresh, unhashed secret, to replace the hashed one before migrarting.

### Consumers with hashed secrets

Check if any Consumer holds a hashed secret:

```sh
hashed_consumers=$(for consumer in $(curl -s $KONG_ADMIN_API/consumers | jq -r '.data[].username'); do
  curl -s "$KONG_ADMIN_API/consumers/$consumer/oauth2" | \
    jq -r --arg c "$consumer" '.data[] | select(.hash_secret == true) | $c'
done)

echo "$hashed_consumers"
```
The response displays a list of Consumers with secrets containing the field `hash_secret: true`. If the list is empty, you can proceed to the migration. If the list contains Consumer names, you can generate a unhashed new secret for them with this command:

{% navtabs "retrieve-credentials" %}
{% navtab "Single Consumer" %}

Run this request to add a new secret to a single Consumer:

```sh
curl -s -X POST $KONG_ADMIN_API/consumers/$CONSUMER/oauth2 \
  -d "name=acme-app-new-credential" \
  -d "client_id=acme-app-client-id-v2" \
  -d "hash_secret=false" | jq
``` 

{% endnavtab %}
{% navtab "Multiple Consumers" %}

This command bulk creates new the secrets for all existing Consumers with hashed secrets. It uses the filtered list to:

1. Loop through each hashed credential.
1. Create a new secret for each Consumer.

```sh
for consumer in $(curl -s $KONG_ADMIN_API/consumers | jq -r '.data[].username'); do
  curl -s "$KONG_ADMIN_API/consumers/$consumer/oauth2" | \
    jq -c --arg c "$consumer" '.data[] | select(.hash_secret == true) | {consumer: $c, cred_name: .name}' | \
  while read -r row; do
    consumer_name=$(echo "$row" | jq -r '.consumer')
    cred_name=$(echo "$row" | jq -r '.cred_name')

    curl -s -X POST "$KONG_ADMIN_API/consumers/$consumer_name/oauth2" \
      -d "name=${cred_name}-migrated" \
      -d "hash_secret=false" > /dev/null
  done
done
```

{% endnavtab %}
{% endnavtabs %}

### Get the Consumer credentials

To get the existing credentials, run the following command:

{% navtabs "retrieve-credentials" %}
{% navtab "Single Consumer" %}

This commands gets the secrets from a single Consumer and saves them as `LEGACY_CLIENT_ID` and `LEGACY_CLIENT_SECRET` environment variables:

```sh
export LEGACY_CLIENT_ID=$(curl -s $KONG_ADMIN_API/consumers/$CONSUMER/oauth2 | jq -r '.data[0].client_id')
export LEGACY_CLIENT_SECRET=$(curl -s $KONG_ADMIN_API/consumers/$CONSUMER/oauth2 | jq -r '.data[0].client_secret')
```

{% endnavtab %}
{% navtab "Multiple Consumers" %}

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

## Create a client and upload the existing credentials

{% navtabs "upload-credentials" %}
{% navtab "Single Consumer" %}

Create a client in the authorization server using the [`/v1/auth-servers/{authServerId}/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient), and save the `CLIENT_ID` and `CLIENT_SECRET` variables:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients/$LEGACY_CLIENT_ID
status_code: 200
method: PUT
headers:
  - 'Content-Type: application/json'
body:
  name: "$CONSUMER"
  client_secret: "$LEGACY_CLIENT_SECRET"
  grant_types:
    - "client_credentials"
  response_types:
    - "token"
capture:
  - variable: CLIENT_ID
    jq: ".id"
  - variable: CLIENT_SECRET
    jq: ".client_secret"
{% endkonnect_api_request %}
<!--vale on-->

**Warn about**

- `client_id` must be ≤36 chars matching [-_\w]+ — so if a legacy `client_id` has characters outside that set, it can't be uploaded as-is and needs remapping.
- `grant_types` here only allows `implicit` or `client_credentials`: `authorization_code` isn't in the enum.


{% endnavtab %}
{% navtab "Multiple Consumers" %}

To migrate more than one Consumer, use the `custom_id` field. Set each Consumer's `custom_id` to match its Client's `client_id`:

```sh
for consumer in $(curl -s $KONG_ADMIN_API/consumers | jq -r '.data[].username'); do
  client_id=$(curl -s "$KONG_ADMIN_API/consumers/$consumer/oauth2" | jq -r '.data[0].client_id')
  curl -s -X PATCH "$KONG_ADMIN_API/consumers/$consumer" \
    -d "custom_id=$client_id" | jq -c '{username: .username, custom_id: .custom_id}'
done
```

{% endnavtab %}
{% endnavtabs %}

## Configure the OIDC plugin on the service

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID
status_code: 200
method: GET
capture:
  - variable: ISSUER
    jq: ".issuer"
{% endkonnect_api_request %}
<!--vale on-->


## Attach the plugin to a service

- List the services

```sh
curl -s $KONG_ADMIN_API/services | jq -r '.data[] | {name, id, host, path}'
```

- 2 options:
  - pick a service and save it as `$SERVICE`
  - attach the plugin to all services


```sh
curl -s -X POST $KONG_ADMIN_API/services/$SERVICE/plugins \
  -d "name=openid-connect" \
  -d "config.issuer=$ISSUER" \
  -d "config.client_id=$CLIENT_ID" \
  -d "config.client_secret=$CLIENT_SECRET" \
  -d "config.auth_methods=client_credentials" \
  -d "config.consumer_claim=consumer_name" \
  -d "config.consumer_by=username" | jq
```

**Version warnings**

- `consumer_claim` vs `consumer_claims`: Kong Gateway ≥3.14 uses the plural `consumer_claims` (array). Older versions use singular `consumer_claim`: include two versions of the snippet?
- `consumer_by: username`: this tells the plugin to match the claim value against the Consumer's `username` field.

## Verify

Pull the token endpoint path and save it as an environment variable: 

```sh
export TOKEN_ENDPOINT=$(curl -s "$ISSUER/.well-known/openid-configuration" | jq -r '.token_endpoint')
```

Request a token from the new endpoint and save it as an environment variable:

```sh
export ACCESS_TOKEN=$(curl -s -X POST "$TOKEN_ENDPOINT" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" | jq -r '.access_token')
```

Confirm the service accepts the token: 

```sh
curl -sk $KONG_PROXY_URL/demo/anything \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq
```

## Deactivate the OAuth 2.0 plugin

```sh
PLUGIN_ID=$(curl -s $KONG_ADMIN_API/services/demo-service/plugins | jq -r '.data[] | select(.name=="oauth2") | .id')

curl -s -X PATCH $KONG_ADMIN_API/plugins/$PLUGIN_ID \
  -d "enabled=false" | jq
```

## Delete the OAuth 2.0 plugin

```sh
curl -s -X DELETE $KONG_ADMIN_API/plugins/$PLUGIN_ID
```