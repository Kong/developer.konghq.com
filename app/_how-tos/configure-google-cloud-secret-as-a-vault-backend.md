---
title: Configure Google Cloud Secret Manager as a Vault entity in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Rotate secrets in Google Cloud Secret with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-google-cloud-secret 
  - text: Secrets management
    url: /gateway/secrets-management
  - text: Configure Google Cloud Secret Manager with Workload Identity in {{site.base_gateway}}
    url: /how-to/configure-google-cloud-secret-manager-with-workload-identity

products:
    - gateway

tier: enterprise

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How do I use Google Cloud Secret Manager as a Vault in {{site.base_gateway}}?
    a: |
      Export your service account key JSON as an environment variable (`GCP_SERVICE_ACCOUNT`), set `lua_ssl_trusted_certificate=system` in your `kong.conf` file, then configure a Vault entity with your Secret Manager configuration. Reference secrets from your Secret Manager vault like the following: `{vault://gcp-sm-vault/test-secret/key}`

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Mistral AI API key
      include_content: prereqs/vault-backends/mistral-env-var
    - title: Google Cloud Secret Manager
      include_content: prereqs/vault-backends/google-secret-manager

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Set your Secret Manager credentials with an environment variable

You can set your JSON Google Cloud service account key with the `GCP_SERVICE_ACCOUNT` environment variable. {{site.base_gateway}} uses the key to automatically authenticate with the Google Cloud API so that it can pull secret values as they are referenced.

Add your service account JSON file to your Docker container and export it as an environment variable:

```sh
export GCP_SERVICE_ACCOUNT=$(cat gcp-project-c61f2411f321.json)
```

## 2. Configure {{site.base_gateway}} to trust Google Cloud API SSL certificates

Configure `lua_ssl_trusted_certificate=system` in your `kong.conf` file [LINK!!!]. This ensures that the SSL certificates that the Google Cloud API uses can be trusted by {{site.base_gateway}}. You can configure this directly in your `kong.conf`, or use [environment variables](/deck/environment-variables/):

```sh
export KONG_LUA_SSL_TRUSTED_CERTIFICATE='system'
```

## 3. Configure Secret Manager as a vault with the Vault entity

To enable Secret Manager as your vault in {{site.base_gateway}}, you can use the [Vault entity](/gateway/entities/vault).

For the sake of the tutorial, we aren't separating the Vault decK configuration from the other entities, like Consumers and Services. However, if you're implementing a Vault configuration in production and have a large organization with many teams, we recommend splitting the Vault configuration from other entities with decK. For more information, see [Declarative configuration (decK) best practices for Vaults](/gateway/entities/vault/#declarative-configuration-deck-best-practices-for-vaults).

Add the following content to `kong.yaml` to create a Secret Manager Vault:

{% entity_examples %}
entities:
  vaults:
    - config:
        project_id: test-gateway-vault
      description: Stored secrets in Secret Manager
      name: gcp
{% endentity_examples %}

## 4. Reference the secret from your Vault in {{site.base_gateway}} configuration

Now that Secret Manager is configured as your vault, you can reference secrets stored in that vault in configuration. In this tutorial, you'll be referencing the API key you set previously and using it to generate an answer to a question using the [AI Proxy plugin](/plugins/ai-proxy/). To reference a secret, you use the provider name from your Vault config, the name of the secret, and the property in the secret you want to use.

Add the following content to `kong.yaml` to reference the Vault secret as your bearer token:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      route: example-route
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: '{vault://gcp-sm-vault/test-secret/key}'
        model:
          provider: mistral
          name: mistral-tiny
          options:
            mistral_format: openai
            upstream_url: https://api.mistral.ai/v1/chat/completions
{% endentity_examples %}

## 5. Apply configuration

{% include how-tos/steps/apply_config.md %}

## 6. Validate

To verify that {{site.base_gateway}} can pull the secrets from Secret Manager, you can use the AI Proxy plugin to confirm that the plugin is using the correct API key when a request is made:

```
curl -X POST http://localhost:8000/anything \
 -H 'Content-Type: application/json' \
 --data-raw '{ "messages": [ { "role": "system", "content": "You are a mathematician" }, { "role": "user", "content": "What is 1+1?"} ] }'
```


    