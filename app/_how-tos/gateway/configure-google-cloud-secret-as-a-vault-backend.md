---
title: Configure Google Cloud Secret Manager as a vault backend
permalink: /how-to/configure-google-cloud-secret-as-a-vault-backend/
content_type: how_to
related_resources:
  - text: Rotate secrets in Google Cloud Secret with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-google-cloud-secret/
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Google Cloud Vault configuration parameters
    url: /gateway/entities/vault/?tab=google-cloud#vault-provider-specific-configuration-parameters
  - text: Configure Google Cloud Secret Manager as a Vault entity with {{ site.kic_product_name }}
    url: "/kubernetes-ingress-controller/vault/gcp/"
description: Learn how to store a secret in Google Cloud Secret Manager, configure GCP as a Vault entity, and reference the stored secret in {{site.base_gateway}}.
products:
    - gateway

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

search_aliases:
  - GCP

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
  konnect:
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
  - q: I'm using Google Workload Identity, how do I configure a Vault?
    a: |
      To use GCP Secret Manager with
      [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
      on a GKE cluster, update your pod spec so that the service account (`GCP_SERVICE_ACCOUNT`) is
      attached to the pod. For configuration information, read the [Workload
      Identity configuration
      documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to).

      {:.info}
      > **Notes:**
      > * With Workload Identity, setting the `GCP_SERVICE_ACCOUNT` isn't necessary.
      > * When using GCP Vault as a backend, make sure you have configured `system` as part of the
      > [`lua_ssl_trusted_certificate` configuration directive](/gateway/configuration/#lua-ssl-trusted-certificate)
      so that the SSL certificates used by the official GCP API can be trusted by {{site.base_gateway}}.
  - q: |
      {% include /gateway/vaults-format-faq.md type='question' %}
    a: |
      {% include /gateway/vaults-format-faq.md type='answer' %}
cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
  - text: What can be stored as a secret?
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret
  - text: Rotate secrets in Google Cloud Secret with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-google-cloud-secret/

automated_tests: false
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

To validate that the secret was stored correctly in Google Cloud, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. 

{% validation vault-secret %}
secret: '{vault://gcp-sm-vault/test-secret}'
value: 'secret'
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://gcp-sm-vault/test-secret}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret). 
    