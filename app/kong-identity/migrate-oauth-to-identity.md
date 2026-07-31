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

To use the Consumers credentials in {{site.identity}}, you create a client per pair of credentials, then upload the secrets to match `client_id` and `client_secret`.

{% navtabs "create-client" %}
{% navtab "Single Consumer" %}

Get a single credentials from one Consumer and save them as `CLIENT_ID` and `CLIENT_SECRET` environment variables:

```sh
export CLIENT_ID=$(curl -s $KONG_ADMIN_API/consumers/$CONSUMER/oauth2 | jq -r '.data[0].client_id')
export CLIENT_SECRET=$(curl -s $KONG_ADMIN_API/consumers/$CONSUMER/oauth2 | jq -r '.data[0].client_secret')
```

Create a client in the authorization server using the [`/v1/auth-servers/{authServerId}/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient) and upload the credentials:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients/$CLIENT_ID
status_code: 201
method: PUT
headers:
  - 'Content-Type: application/json'
body:
  name: "$CONSUMER"
  client_secret: "$CLIENT_SECRET"
  grant_types:
    - "client_credentials"
  response_types:
    - "token"
{% endkonnect_api_request %}
<!--vale on-->

Map the Consumer to this client by setting `custom_id` to match the client's ID:

```sh
curl -s -X PATCH "$KONG_ADMIN_API/consumers/$CONSUMER" \
  -d "custom_id=$CLIENT_ID" | jq -c '{username: .username, custom_id: .custom_id}'
```

If your Consumer contains multiple credentials, use the Multiple Consumers method.

**Warn about**

- `client_id` must be ≤36 chars matching [-_\w]+ — so if a legacy `client_id` has characters outside that set, it can't be uploaded as-is and needs remapping.
- `grant_types` here only allows `implicit` or `client_credentials`: `authorization_code` isn't in the enum.


{% endnavtab %}
{% navtab "Multiple Consumers" %}
Migrating Consumers credentials to Kong Identity clients requires preventing two collision risks that this section solves:

- **Name collision:** Each client needs a unique name. A Consumer containing multiple credentials is the equivalent of multiple clients with the same name containing the credentials. Trying to migrate this configuration will fail, because client names can't be duplicate. To avoid that, this section sets the `name` value of every client to its `client_id`.
- **`custom_id` collision:** Every client metadate contains a unique `custom_id` value that you can set, useful for mapping Consumers to services and plugins. We extract this value from the Consumer's `id` and pass it to the client. However if a Consumer contains multiple credentials, the same ID can't be set to the same client. To avoid `custom_id` collisions, this section shows you how to group Consumers into sub-Consumers, each with their own `custom_id`.

Rename every Consumer:

```sh
name="${consumer}-${client_id}"
```

Run the migration script:

```sh
for consumer in $(curl -s $KONG_ADMIN_API/consumers | jq -r '.data[].username'); do
  creds=$(curl -s "$KONG_ADMIN_API/consumers/$consumer/oauth2" | jq -c '.data')
  count=$(echo "$creds" | jq 'length')

  if [ "$count" -gt 1 ]; then
    curl -s -X POST "$KONG_ADMIN_API/consumer_groups" -d "name=$consumer" > /dev/null

    echo "$creds" | jq -c '.[]' | while read -r cred; do
      client_id=$(echo "$cred" | jq -r '.client_id')
      client_secret=$(echo "$cred" | jq -r '.client_secret')
      sub_consumer="${consumer}-${client_id}"

      # Each sub-Consumer gets its own custom_id, matching its own client_id
      curl -s -X POST "$KONG_ADMIN_API/consumers" \
        -d "username=$sub_consumer" \
        -d "custom_id=$client_id" > /dev/null

      # The group records "these sub-Consumers are really one app"
      curl -s -X POST "$KONG_ADMIN_API/consumer_groups/$consumer/consumers" \
        -d "consumer=$sub_consumer" > /dev/null

      curl -s -X PUT "$KONNECT_API_URL/v1/auth-servers/$AUTH_SERVER_ID/clients/$client_id" \
        -H "Authorization: Bearer $KONNECT_TOKEN" \
        --json "{
          \"name\": \"$sub_consumer\",
          \"client_secret\": \"$client_secret\",
          \"grant_types\": [\"client_credentials\"],
          \"response_types\": [\"token\"]
        }" | jq -c '{client_id: .id, name: .name}'
    done
  fi
done
```
The preceding script:

- Retrieves the credentials for every Consumer.
- Splits Consumers with multiple credentials into one sub-Consumer per credential, then group them.

Your current setup with the Auth 2.0 plugin stills maps the old Consumer. To finish the migration, configure the OIDC or Instropection plugin to start usin tokens issued by the {{site.identity}} authorization server.

{% endnavtab %}
{% endnavtabs %}

## Configure the OIDC plugin on the service

Activate the OIDC plugin:

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


### Attach the plugin to services

{% navtabs "Attach the plugin" %}
{% navtab "Attach to a single service" %}

List the services:

```sh
curl -s $KONG_ADMIN_API/services | jq -r '.data[] | {name, id, host, path}'
```

Pick a service and save it as a `$SERVICE` environment variable:

```sh
export SERVICE='<your-service-name-or-id>'
```

Attach the plugin to the chosen service:

```sh
curl -s -X POST "$KONG_ADMIN_API/services/$SERVICE/plugins" \
  -H "Content-Type: application/json" \
  --json '{
    "name": "openid-connect",
    "config": {
      "issuer": "'"$ISSUER"'",
      "auth_methods": ["client_credentials"],
      "consumer_claims": [["client_id"]],
      "consumer_by": ["custom_id"]
    }
  }'
```

{% endnavtab %}
{% navtab "Attach to all services" %}

Attach the OIDC plugin to all your services:

```sh
curl -s $KONG_ADMIN_API/services | jq -r '.data[].id' | \
while read -r service_id; do
  curl -s -X POST "$KONG_ADMIN_API/services/$service_id/plugins" \
    -H "Content-Type: application/json" \
    --json '{
      "name": "openid-connect",
      "config": {
        "issuer": "'"$ISSUER"'",
        "auth_methods": ["client_credentials"],
        "consumer_claims": [["client_id"]],
        "consumer_by": ["custom_id"]
      }
    }' | jq -c --arg sid "$service_id" '{service: $sid, plugin_id: .id}'
done
```
{% endnavtab %}
{% endnavtabs %}

**Warnings**
Unlike single-tenant OIDC examples, this plugin config intentionally omits client_id/client_secret. Each migrated app authenticates using its own credentials against the Auth Server's token endpoint; the plugin only needs to validate the resulting token and resolve it to a Consumer via consumer_claims

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

**Warn about**

- Same constraints as the single-Consumer case: `client_id` ≤36 chars matching `[-_\w]+`, and `grant_types` only supports `implicit` or `client_credentials`.
- If `client_id` needed sanitizing, the app must be updated with the new sanitized ID, not just the new token endpoint — this isn't a transparent cutover for that Consumer.
- Consumers with `hash_secret: true` need to go through the new-credential flow first (see [Get the Consumer credentials](#get-the-consumer-credentials)) — this loop assumes plaintext secrets are already retrievable.
- `custom_id` here is set to the *sanitized* client_id, not the legacy one — the OIDC plugin's `consumer_by: custom_id` mapping depends on this matching exactly.