---
title: Store a Mistral API key as a secret in {{site.konnect_short_name}} Config Store
description: Learn how to set up {{site.konnect_short_name}} Config Store as a Vault backend and store a Mistral API key.
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management/
  - text: Vault entity
    url: /gateway/entities/vault/
  - text: Configure the {{site.konnect_short_name}} Config Store
    url: /how-to/configure-the-konnect-config-store/
  - text: Reference secrets stored in the {{site.konnect_short_name}} Config Store
    url: /how-to/reference-secrets-from-konnect-config-store/
  - text: Store certificates in {{site.konnect_short_name}} Config Store
    url: /how-to/store-certificates-in-konnect-config-store/
  - text: AI Proxy plugin
    url: /plugins/ai-proxy/
  - text: Mistral AI documentation
    url: https://docs.mistral.ai/

products:
    - gateway

works_on:
    - konnect

entities: 
  - vault

tags:
    - security
    - secrets-management
    - ai

tldr:
    q: How do I store my Mistral API key as a secret in a {{site.konnect_short_name}} Vault and then use it with the AI Proxy plugin?
    a: |
      1. Use the {{site.konnect_short_name}} API to create a Config Store using the `/config-stores` endpoint.
      2. Create a {{site.konnect_short_name}} Vault using the [`/vaults/` endpoint](/api/konnect/control-planes-config/v2/#/operations/create-vault).
      3. Store your Mistral API key as a key/value pair using the `/secrets` endpoint. 
      4. Reference the secret using the Vault prefix and key (for example: `{vault://mysecretvault/mistral-key}`) in the [AI Proxy plugin](/plugins/ai-proxy/) `header_value`. 

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Mistral AI API key
      content: |
        In this tutorial, you'll be storing your Mistral AI API key as a secret in a {{site.konnect_short_name}} Vault.

        In the Mistral AI console, [create an API key](https://console.mistral.ai/api-keys/) and copy it. You'll add this API key as a secret to your vault.

        Export the API key as an environment variable:
        ```sh
        export MISTRAL_API_KEY='YOUR API KEY'
        ```
    - title: "{{site.konnect_short_name}} API"
      include_content: prereqs/konnect-api-for-curl

tools:
  # - konnect-api
  - deck

faqs:
  - q: How do I replace certificates used in {{site.base_gateway}} data plane nodes with a secret reference?
    a: Set up a {{site.konnect_short_name}} or any other Vault and define the certificate and key in a secret in the Vault. 
cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---


## Configure a {{site.konnect_short_name}} Config Store

Before you can configure a {{site.konnect_short_name}} Vault, you must first create a Config Store using the [Control Planes Configuration API](/api/konnect/control-planes-config/v2/#/) by sending a `POST` request to the `/config-stores` endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    name: my-config-store
{% endcontrol_plane_request %}
<!--vale on-->

Export your Config Store ID as an environment variable so you can use it later:

```sh
export DECK_CONFIG_STORE_ID='CONFIG STORE ID'
```

## Configure {{site.konnect_short_name}} as your Vault

Enable {{site.konnect_short_name}} as your vault with the [Vault entity](/gateway/entities/vault/):

{% entity_examples %}
entities:
  vaults:
  - name: konnect
    prefix: mysecretvault
    description: Storing secrets in {{site.konnect_short_name}}
    config:
      config_store_id: ${config-store-id}

variables:
  config-store-id:
    value: $CONFIG_STORE_ID
{% endentity_examples %}

## Store the Mistral AI key as a secret

In this tutorial, you'll be storing the Mistral API key you set previously and using it to generate an answer to a question using the [AI Proxy plugin](/plugins/ai-proxy/). By storing it as a secret in a {{site.konnect_short_name}} Vault, you can reference it during plugin configuration in the next step.

Store your Mistral key as a secret by sending a `POST` request to the `/secrets` endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$DECK_CONFIG_STORE_ID/secrets/
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    key: mistral-key
    value: Bearer $MISTRAL_API_KEY
{% endcontrol_plane_request %}
<!--vale on-->

## Reference your stored Mistral API key

To reference your stored Mistral API key, you use the prefix from your Vault config, the name of the secret, and optionally the property in the secret you want to use. Now, you'll reference the Mistral API key as a secret in the authorization header of the AI Proxy plugin configuration.

Enable the AI Proxy plugin on your Route:

{% entity_examples %}
entities:
  plugins:
  - name: ai-proxy
    route: example-route
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
{% endentity_examples %}

## Validate

You can use the AI Proxy plugin to confirm that the plugin is using the correct API key when a request is made:

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