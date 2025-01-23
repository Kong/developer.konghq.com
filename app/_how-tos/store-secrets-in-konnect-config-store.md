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
      Use the {{site.konnect_short_name}} API to create a Config Store using the `config-stores` endpoint, create a {{site.konnect_short_name}} Vault using the [`/vaults/` endpoint](/api/konnect/control-planes-config/v2/#/operations/create-vault), and then store your secret as a key/value pair using the `/config-stores/{configStoreId}/secrets` endpoint. Then the secret will be refrenceable using the Vault prefix and the key name, for example: `{vault://mysecretvault/mistral-key}`

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Mistral AI API key
      include_content: prereqs/vault-backends/mistral-env-var
    - title: Konnect API
      include_content: prereqs/konnect-api-for-curl

tools:
  - konnect-api

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

Before you can configure a {{site.konnect_short_name}} Vault, you must first create a Config Store using the [Control Planes Configuration API](link) by sending a `POST` request to the `/config-stores` endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    name: my-config-store
{% endcontrol_plane_request %}
<!--vale on-->

Export your Config Store ID as an environment variable so you can use it later:

```sh
export CONFIG_STORE_ID=config-store-uuid
```

## 2. Configure {{site.konnect_short_name}} as your Vault

To enable {{site.konnect_short_name}} as your vault with the [Vault entity](/gateway/entities/vault) send a `POST` request to the [`/v2/control-planes/{controlPlaneId}/core-entities/vaults/` endpoint](/api/konnect/control-planes-config/v2/#/operations/create-vault):



<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/vaults/
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    config:
      config_store_id: $CONFIG_STORE_ID
    description: Storing secrets in Konnect
    name: konnect
    prefix: mysecretvault
{% endcontrol_plane_request %}
<!--vale on-->

## 3. Store the Mistral AI key as a secret

Storing the Mistral AI API key you copied earlier as a secret in your Vault will allow you to reference this later in a plugin configuration. 

Store your Mistral key as a secret by sending a `POST` request to the `/v2/control-planes/{controlPlaneId}/config-stores/{configStoreId}/secrets` endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$CONFIG_STORE_ID/secrets/
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    key: mistral-key
    value: Bearer <mistral-key-here>
{% endcontrol_plane_request %}
<!--vale on-->

## 4. Reference your stored secret

To reference a secret, you use the prefix from your Vault config, the name of the secret, and optionally the property in the secret you want to use. Now that the {{site.konnect_short_name}} Konnect vault is configured, you can reference secrets stored in that Vault in configurations. In this tutorial, you'll be referencing the API key you set previously and using it to generate an answer to a question using the [AI Proxy plugin](/plugins/ai-proxy/). 

Enable the AI Proxy plugin on your route by sending a `POST` request to the [`/routes/{RouteId}/plugins` endpoint](/api/konnect/control-planes-config/v2/#/operations/create-plugin-with-route):

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    config:
      route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: '{vault://mysecretvault/mistral-key}'
      model:
        provider: mistral
        name: mistral-tiny
        options: 
          mistral_format: openai
          upstream_url: https://api.mistral.ai/v1/chat/completions
    enabled: true
    name: ai-proxy
    route:
      id: $ROUTE_ID
{% endcontrol_plane_request %}
<!--vale on-->

## 5. Validate

To verify that {{site.base_gateway}} can pull the secrets from {{site.konnect_short_name}} Config Store, you can use the AI Proxy plugin to confirm that the plugin is using the correct API key when a request is made:

<!--vale off-->
{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}
<!--vale on-->