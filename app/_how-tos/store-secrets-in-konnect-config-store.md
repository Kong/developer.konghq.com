---
title: Store secrets in Konnect Config Store
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management 
  - text: Vault entity
    url: /gateway/entities/vault

products:
    - gateway

works_on:
    - konnect

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How do I use {{site.konnect_short_name}} as a Vault backend and store secrets in it?
    a: |
      Use the {{site.konnect_short_name}} API to create a Config Store using the `/v2/control-planes/{controlPlaneId}/config-stores` endpoint, create a {{site.konnect_short_name}} Vault using the `/v2/control-planes/{controlPlaneId}/core-entities/vaults/`, and then store your secret as a key/value pair using the `/v2/control-planes/{controlPlaneId}/config-stores/{configStoreId}/secrets`. To reference the secret in configuration, use the Vault prefix and the key name, for example: `{vault://mysecretvault/mistral-key}`

tools:
  - konnect-api

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Mistral AI API key
      include_content: prereqs/vault-backends/mistral-env-var

faqs:
  - q: How do I replace certificates used in {{site.base_gateway}} data plane nodes with a secret reference?
    a: Set up a {{site.konnect_short_name}} or any other Vault, define the certificate and key in a secret in the Vault. 
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---


## 1. Configure a {{site.konnect_short_name}} Config Store

Before you can configure a {{site.konnect_short_name}} Vault, you must first create a config store:

```sh
curl -i -X POST $KONNECT_API_REGION_URL/v2/control-planes/$CONTROL_PLANE_ID/config-stores \
 --header "Authorization: Bearer $KONNECT_TOKEN" \
 --header 'Content-Type: application/json' \
 --data '{
	"name": "my-config-store"
}'
```

Export your config store ID as an environment variable so we can use it later:

```sh
export CONFIG_STORE_ID=config-store-uuid
```

## 2. Configure {{site.konnect_short_name}} as your Vault

To enable {{site.konnect_short_name}} as your vault in {{site.base_gateway}}, you can use the [Vault entity](/gateway/entities/vault).

```sh
curl -i -X POST $KONNECT_API_REGION_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/vaults/  \
 --header "Authorization: Bearer $KONNECT_TOKEN" \
 --header 'Content-Type: application/json' \
 --data '{
	"config":{
		"config_store_id": "$CONFIG_STORE_ID"
	},
	"description": "Storing secrets in Konnect",
	"name": "konnect",
	"prefix": "mysecretvault"
}'
```

## 3. Store the Mistral AI key as a secret

In this how-to, you're storing the Mistral AI API key you copied earlier as a secret in your Vault. This will allow you to reference this later in a plugin configuration. 

```sh
curl -i -X POST $KONNECT_API_REGION_URL/v2/control-planes/$CONTROL_PLANE_ID/config-stores/$CONFIG_STORE_ID/secrets \
  --header "Authorization: Bearer $KONNECT_TOKEN" \
  --header 'Content-Type: application/json' \
  --data '{
  "key": "mistral-key",
  "value": "Bearer <mistral-key-here>"
}'
```

## 4. Reference your stored secret

Now that {{site.konnect_short_name}} is configured as your vault, you can reference secrets stored in that vault in configuration. In this tutorial, you'll be referencing the API key you set previously and using it to generate an answer to a question using the [AI Proxy plugin](/plugins/ai-proxy/). To reference a secret, you use the provider name from your Vault config, the name of the secret, and the property in the secret you want to use.

```sh
curl --request POST \
  --url $KONNECT_API_REGION_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $KONNECT_TOKEN" \
  --data '{
    "config": {
    "route_type": "llm/v1/chat",
   "auth": {
     "header_name": "Authorization",
     "header_value": "{vault://mysecretvault/mistral-key}"
   },
   "model": {
     "provider": "mistral",
     "name": "mistral-tiny",
     "options": {
       "mistral_format": "openai",
       "upstream_url": "https://api.mistral.ai/v1/chat/completions"
     }
   }
 },
    "enabled": true,
    "name": "ai-proxy",
    "route": {
      "id": "$ROUTE_ID"
    }
  }'
```

## 5. Validate

To verify that {{site.base_gateway}} can pull the secrets from {{site.konnect_short_name}} Config Store, you can use the AI Proxy plugin to confirm that the plugin is using the correct API key when a request is made:

```sh
curl -X POST $KONNECT_PROXY_URL/anything \
 -H 'Content-Type: application/json' \
 --data-raw '{ "messages": [ { "role": "system", "content": "You are a mathematician" }, { "role": "user", "content": "What is 1+1?"} ] }'
```