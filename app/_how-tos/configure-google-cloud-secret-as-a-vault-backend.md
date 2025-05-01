---
title: Configure Google Cloud Secret Manager as a Vault entity in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Rotate secrets in Google Cloud Secret with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-google-cloud-secret/
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure Google Cloud Secret Manager with Workload Identity in {{site.base_gateway}}
    url: /how-to/configure-google-cloud-secret-manager-with-workload-identity/

products:
    - gateway

works_on:
    - on-prem

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
      Save a secret in [Google Cloud Secret Manager](https://console.cloud.google.com/security/secret-manager) and create a service account with the `Secret Manager Secret Accessor` role. Export your service account key JSON as an environment variable (`GCP_SERVICE_ACCOUNT`), set `lua_ssl_trusted_certificate=system` in your `kong.conf` file, then configure a Vault entity with your Secret Manager configuration. Reference secrets from your Secret Manager vault like the following: `{vault://gcp-sm-vault/test-secret}`

tools:
    - deck

prereqs:
  gateway:
    - name: GCP_SERVICE_ACCOUNT
    - name: KONG_LUA_SSL_TRUSTED_CERTIFICATE
  cloud:
    gcp:
      secret: true

faqs:
  - q: "How do I fix the `Error: could not get value from external vault (no value found (unable to retrieve secret from gcp secret manager (code : 403, status: PERMISSION_DENIED)))` error when I try to use my secret from the Google Cloud vault?"
    a: Verify that your [Google Cloud service account has the `Secret Manager Secret Accessor` role](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project). This role is required for {{site.base_gateway}} to access secrets in the vault.
  - q: How do I rotate my secrets in Google Cloud and how does {{site.base_gateway}} pick up the new secret values?
    a: You can rotate your secret in Google Cloud by creating a new secret version with the updated value. You'll also want to configure the `ttl` settings in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} pulls the rotated secret periodically. For more information, see [Store and rotate Mistral API keys as secrets in Google Cloud with {{site.base_gateway}} and the AI Proxy plugin](/how-to/rotate-secrets-in-google-cloud-secret/).

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---

## Configure Secret Manager as a vault with the Vault entity

To enable Secret Manager as your vault in {{site.base_gateway}}, you can use the [Vault entity](/gateway/entities/vault/).

{% entity_examples %}
entities:
  vaults:
    - name: gcp
      description: Stored secrets in Secret Manager
      prefix: gcp-sm-vault
      config:
        project_id: test-gateway-vault
{% endentity_examples %}

## Validate

To validate that the secret was stored correctly in Google Cloud, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. If the Docker container is named `kong-quickstart-gateway`, you can use the following command:

```sh
docker exec kong-quickstart-gateway kong vault get {vault://gcp-sm-vault/test-secret}
```

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://gcp-sm-vault/test-secret}` to reference the secret in any referenceable field.


    