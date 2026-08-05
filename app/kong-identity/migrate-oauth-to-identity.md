---
title: "Migrating from the OAuth 2.0 plugin to {{site.identity}}"
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

description: This guide walks you through migrating from the OAuth 2.0 plugin to {{site.identity}} with OIDC or OAuth 2.0 Introspection.

related_resources:
  - text: "{{site.identity}} authorization servers"
    url: /identity/auth-servers/
tags:
  - authentication
  - migration

min_version:
  gateway: '3.15'

faqs:
  - q: |
      Why am I getting "URL rejected: Malformed input to a URL function" when trying to create the client?
    a: |
      This error comes from curl itself, not from the {{site.identity}} API. The request never reaches the server.

      It happens when the legacy `client_id` you're using in the `PUT` URL contains characters that aren't valid in a URL path segment (for example `@`, `+`, or spaces). Because the client-creation step inserts `client_id` directly into the URL (`/auth-servers/{authServerId}/clients/{clientId}`), any such character breaks the request before it's sent. The `client_id` must match `[-_\w]+` and be 36 characters or fewer.

      Sanitize the value and re-export `CLIENT_ID` with the result, so the rest of the guide works unchanged:

      ```sh
      export CLIENT_ID=$(echo -n "$CLIENT_ID" | sed 's/[^-_A-Za-z0-9]/-/g' | cut -c1-36)
      echo "CLIENT_ID=$CLIENT_ID"
      ```

      If the sanitized `CLIENT_ID` differs from the original, the app must use the sanitized value as its `client_id` when it requests tokens after the migration.

---

This guide shows you how to migrate from the legacy OAuth 2.0 plugin to {{site.identity}} for an on-prem {{site.base_gateway}} Enterprise setup.

{:.info}
> **Scope:** This guide covers apps using the `client_credentials` grant, presenting the resulting token to {{site.base_gateway}} as a Bearer token. Migrating apps using the `authorization_code` grant isn't covered, because `grant_types` on a {{site.identity}} client only accepts `implicit` or `client_credentials`.

## Requirements

- An on-prem {{site.base_gateway}} Enterprise setup
- Access to the {{site.base_gateway}} Admin API
- The OAuth 2.0 plugin configured for authentication
- Admin access to the PostgreSQL database connected to the plugin
- A {{site.konnect_short_name}} account
- A Personal Access Token (PAT) linked to your account

## Migration overview

The migration follows this order:

1. Get the Consumer credentials.
1. Create an authorization server and a client with existing credentials.
1. Map Consumers.
1. Configure the OIDC plugin.
1. Verify.
1. Deactivate and delete the OAuth 2.0 plugin.

Your apps keep using the credentials already set up with the Consumers. The migration only changes your auth workflows, as follows:

{% table %}
columns:
  - title: What changes
    key: aspect
  - title: Before (OAuth 2.0 plugin)
    key: before
  - title: After ({{site.identity}} + OIDC)
    key: after
rows:
  - aspect: Authorization server
    before: Hosted on {{site.base_gateway}} by the OAuth 2.0 plugin.
    after: Hosted on {{site.konnect_short_name}} as a {{site.identity}} authorization server.
  - aspect: Credential storage
    before: |
      Stored in the Gateway's PostgreSQL `oauth2_credentials` table by the OAuth 2.0 plugin, one or more per Consumer.
    after: |
      Stored as clients on the authorization server, one client per credential pair.
  - aspect: Token endpoint
    before: "`/$SERVICE/oauth2/token`, where `$SERVICE` is your {{site.base_gateway}} Service name or ID."
    after: "`$ISSUER/oauth/token`, where `$ISSUER` is the authorization server's issuer URL."
  - aspect: Gateway's role
    before: Issues and validates tokens.
    after: Only validates tokens, using the OIDC plugin.
  - aspect: Consumer identity
    before: Consumer mapped to its OAuth 2.0 credentials.
    after: |
      Consumer mapped by `custom_id` to the client's `client_id`.
{% endtable %}


Read the following sections to get the information that best suits your configuration.

## Set up the Admin API URL

To call your on-prem {{site.base_gateway}} instance, use your {{site.base_gateway}} Admin API. When you run it locally, the default Admin API URL is `localhost:8001`. The command examples assume you run the commands from a local setup. If you're calling your Admin API from a different location, replace the value with your actual URL:

```sh
export KONG_ADMIN_API='localhost:8001'
```

You also need the proxy URL to verify the migration at the end of this guide. When you run {{site.base_gateway}} locally, the default HTTPS proxy URL is `https://localhost:8443`:

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

The OAuth 2.0 plugin uses a PostgreSQL database to store credentials in the `oauth2_credentials` table. If the secret is hashed, you can't extract the original secret, because {{site.base_gateway}} only stores the hash. You can create a new credential with a fresh, unhashed secret to replace the hashed one before migrating.

### Consumers with hashed secrets

Check if any Consumer holds a hashed secret:

```sh
hashed_consumers=$(for consumer in $(curl -s $KONG_ADMIN_API/consumers | jq -r '.data[].username'); do
  curl -s "$KONG_ADMIN_API/consumers/$consumer/oauth2" | \
    jq -r --arg c "$consumer" '.data[] | select(.hash_secret == true) | $c'
done)

echo "$hashed_consumers"
```

The response displays a list of Consumers with secrets containing the field `hash_secret: true`. If the list is empty, you can proceed to the migration. If the list contains Consumer names, you can generate a new unhashed secret for them with the following command:

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
{% navtab "Multiple Consumers/credentials" %}

This command bulk creates new secrets for all existing Consumers with hashed secrets. It uses the filtered list to:

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

{:.warning}
> When you create a new credential to replace a hashed one, {{site.base_gateway}} generates a new `client_secret`, and you set a new `client_id`. The app must start using these new credentials after the migration. See [Migrate: Update your apps](#migrate-update-your-apps).

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
  name: "Migration from OAuth to OIDC"
  description: "Auth server migration from OAuth to Identity + OIDC plugin"
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

Get a single credential from one Consumer and save it as `CLIENT_ID` and `CLIENT_SECRET` environment variables:

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

{:.info}
> If the `PUT` request fails with a `Malformed input to a URL function` error, your `client_id` contains characters that aren't valid in a URL path segment. See the [FAQ](#faq) to sanitize it before continuing.

Map the Consumer to this client by setting `custom_id` to match the client's ID:

```sh
curl -s -X PATCH "$KONG_ADMIN_API/consumers/$CONSUMER" \
  -d "custom_id=$CLIENT_ID" | jq -c '{username: .username, custom_id: .custom_id}'
```

{% endnavtab %}
{% navtab "Multiple Consumers/credentials" %}
Migrating Consumer credentials to {{site.identity}} clients requires preventing two collision risks that this section solves:

- **Name collision:** Each client needs a unique name. A Consumer that contains multiple credentials is the equivalent of multiple clients with the same name. Trying to migrate this configuration fails, because client names can't be duplicated. To avoid that, this section sets each client's name to the Consumer's `client_id`, which is unique even when a Consumer has multiple credentials.
- **`custom_id` collision:** Each client contains a unique `custom_id` value that you can set, which is useful for mapping Consumers to Services and plugins. This value is extracted from the credential's `client_id` and passed to the client. Because a Consumer can contain multiple credentials, this section groups Consumers into sub-Consumers, each with its own `custom_id`, to avoid `custom_id` collisions.

Unlike the previous steps, the bulk script calls the {{site.identity}} API directly with curl, so it can't use the region host automatically. Set `KONNECT_API` to the API host for your [{{site.konnect_short_name}} region](/konnect-platform/geos/):

```sh
export KONNECT_API='https://us.api.konghq.com'
```

The script reuses `$KONNECT_TOKEN` and the `$AUTH_SERVER_ID` captured when you [created the authorization server](#create-a-kong-identity-authorization-server).

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
      sub_consumer="$client_id"

      curl -s -X POST "$KONG_ADMIN_API/consumers" \
        -d "username=$sub_consumer" \
        -d "custom_id=$client_id" > /dev/null

      curl -s -X POST "$KONG_ADMIN_API/consumer_groups/$consumer/consumers" \
        -d "consumer=$sub_consumer" > /dev/null

      curl -s -X PUT "$KONNECT_API/v1/auth-servers/$AUTH_SERVER_ID/clients/$client_id" \
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
- Splits Consumers that have more than one credential into one sub-Consumer per credential, then groups them.

{:.warning}
> This script only migrates Consumers that have more than one credential. Consumers with a single credential are handled by the **Single Consumer** tab.

Your current setup with the OAuth 2.0 plugin still maps the old Consumer. To finish the migration, configure the OIDC or OAuth 2.0 Introspection plugin to start using tokens issued by the {{site.identity}} authorization server.

{% endnavtab %}
{% endnavtabs %}

## Configure the OIDC plugin on the Service

Configure the [OpenID Connect (OIDC) plugin](/plugins/openid-connect/) to validate the tokens issued by the {{site.identity}} authorization server and map them to your Consumers.

Get the authorization server's issuer URL, and save the `ISSUER` variable:

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

### Attach the plugin to Services

{% navtabs "Attach the plugin" %}
{% navtab "Attach to a specific Service" %}

List the Services:

```sh
curl -s $KONG_ADMIN_API/services | jq -r '.data[] | {name, id, host, path}'
```

Pick a Service and save it as a `$SERVICE` environment variable:

```sh
export SERVICE='<your-service-name-or-id>'
```

Check whether an `openid-connect` plugin instance already exists on this Service:

```sh
OIDC_PLUGIN_ID=$(curl -s "$KONG_ADMIN_API/services/$SERVICE/plugins" | jq -r '.data[] | select(.name=="openid-connect") | .id')
```

{% navtabs "config-plugin" %}
{% navtab "Create the plugin" %}

If `$OIDC_PLUGIN_ID` is empty, create the plugin:

```sh
curl -s -X POST "$KONG_ADMIN_API/services/$SERVICE/plugins" \
  -H "Content-Type: application/json" \
  --json '{
    "name": "openid-connect",
    "config": {
      "issuer": "'"$ISSUER"'",
      "auth_methods": ["bearer"],
      "audience": ["api://default"],
      "consumer_claims": [["client_id"]],
      "consumer_by": ["custom_id"]
    }
  }' | jq -c '{name, enabled, issuer: .config.issuer}'
```
{% endnavtab %}
{% navtab "Use existing plugin" %}
If `$OIDC_PLUGIN_ID` already has a value, update the existing instance instead. A `POST` fails with a `unique constraint violation` if a plugin of the same name already exists on this Service:

```sh
curl -s -X PATCH "$KONG_ADMIN_API/plugins/$OIDC_PLUGIN_ID" \
  -H "Content-Type: application/json" \
  --json '{
    "enabled": true,
    "config": {
      "issuer": "'"$ISSUER"'",
      "auth_methods": ["bearer"],
      "audience": ["api://default"],
      "consumer_claims": [["client_id"]],
      "consumer_by": ["custom_id"]
    }
  }' | jq -c '{name, enabled, issuer: .config.issuer}'
```
{% endnavtab %}
{% endnavtabs %}
{% endnavtab %}
{% navtab "Attach to all Services" %}

Attach or update the OIDC plugin on every Service:

```sh
curl -s $KONG_ADMIN_API/services | jq -r '.data[].id' | \
while read -r service_id; do
  oidc_plugin_id=$(curl -s "$KONG_ADMIN_API/services/$service_id/plugins" | jq -r '.data[] | select(.name=="openid-connect") | .id')

  if [ -z "$oidc_plugin_id" ]; then
    curl -s -X POST "$KONG_ADMIN_API/services/$service_id/plugins" \
      -H "Content-Type: application/json" \
      --json '{
        "name": "openid-connect",
        "config": {
          "issuer": "'"$ISSUER"'",
          "auth_methods": ["bearer"],
          "audience": ["api://default"],
          "consumer_claims": [["client_id"]],
          "consumer_by": ["custom_id"]
        }
      }' | jq -c --arg sid "$service_id" '{service: $sid, plugin_id: .id}'
  else
    curl -s -X PATCH "$KONG_ADMIN_API/plugins/$oidc_plugin_id" \
      -H "Content-Type: application/json" \
      --json '{
        "enabled": true,
        "config": {
          "issuer": "'"$ISSUER"'",
          "auth_methods": ["bearer"],
          "audience": ["api://default"],
          "consumer_claims": [["client_id"]],
          "consumer_by": ["custom_id"]
        }
      }' | jq -c --arg sid "$service_id" '{service: $sid, plugin_id: .id}'
  fi
done
```

This script checks if an existing plugin already exists, and either use it or create it before attaching it to all your Services.

{% endnavtab %}
{% endnavtabs %}

## Verify

{:.warning}
> **Before testing:** The `oauth2` and `openid-connect` plugins can't both be active on the same Service. If both are enabled, `oauth2` intercepts and rejects the request before `openid-connect` runs. Complete the deactivation step below before testing.

{% navtabs "Choose a Service" %}

{% navtab "Single Service" %}
If you attached the OIDC plugin to a single Service, you already have the `$SERVICE` environment variable saved. Follow these steps to test the migrated setup.
{% endnavtab %}

{% navtab "Multiple Services" %}

To verify the migration, pick one Service that you'll test in the final steps:

```sh
curl -s $KONG_ADMIN_API/services | jq -r '.data[] | {name, id}'
```

Save the Service you want to test as an environment variable:

```sh
export SERVICE='<service-name-or-id>'
```
{% endnavtab %}
{% endnavtabs %}

### Deactivate the OAuth 2.0 plugin

Deactivate the legacy OAuth 2.0 plugin to allow the OIDC plugin to replace it:

```sh
OAUTH2_PLUGIN_ID=$(curl -s $KONG_ADMIN_API/services/$SERVICE/plugins | jq -r '.data[] | select(.name=="oauth2") | .id')

curl -s -X PATCH $KONG_ADMIN_API/plugins/$OAUTH2_PLUGIN_ID \
  -d "enabled=false" | jq
```

### Call the token endpoint

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

Pull a Route from your Service:

```sh
export ROUTE_PATH=$(curl -s "$KONG_ADMIN_API/services/$SERVICE/routes" | jq -r '.data[0].paths[0]')
```

### Test the token on a Route

Confirm the Service accepts the token:

```sh
curl -sk $KONG_PROXY_URL${ROUTE_PATH} \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq
```

A successful response returns `200` and echoes the mapped Consumer in the `X-Consumer-Username` and `X-Consumer-Custom-Id` headers.

### Optional: Reactivate the OAuth 2.0 plugin

If you aren't ready to migrate yet, reactivate the OAuth 2.0 plugin to avoid breaking your app's workflows:

```sh
OAUTH2_PLUGIN_ID=$(curl -s $KONG_ADMIN_API/services/$SERVICE/plugins | jq -r '.data[] | select(.name=="oauth2") | .id')

curl -s -X PATCH $KONG_ADMIN_API/plugins/$OAUTH2_PLUGIN_ID \
  -d "enabled=true" | jq
```

## Migrate: Update your apps

To migrate successfully, update your app's configuration to request a token. Before the migration, the server that issues tokens was hosted on your {{site.base_gateway}}, and it's now hosted on {{site.konnect_short_name}}. Update the token endpoint URL accordingly:

- **Before the migration** (using the OAuth 2.0 plugin): `/$SERVICE/oauth2/token`
- **After the migration** (using the OIDC plugin): `$ISSUER/oauth/token`

If you sanitized a `client_id` or created a new credential to replace a hashed secret, also update the app to use the new `client_id` and `client_secret`.

To avoid downtime in production, recreate your environment with the minimum requirements:

- A staging app.
- A staging {{site.base_gateway}} setup.
- An authorization server in {{site.konnect_short_name}} dedicated to testing the migration.

### Delete the OAuth 2.0 plugin

Once you have confirmed that the traffic and the auth workflows work as expected after deactivating the OAuth 2.0 plugin, you can safely delete it:

```sh
curl -s -X DELETE $KONG_ADMIN_API/plugins/$OAUTH2_PLUGIN_ID
```
