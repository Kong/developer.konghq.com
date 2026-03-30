---
title: Configure HashiCorp Vault as a vault backend with GCP workload identity
permalink: /how-to/configure-hashicorp-vault-with-gcp-workload-identity/
content_type: how_to
description: "Learn how to configure HashiCorp Vault with GCP GCE authentication using workload identity and reference HashiCorp Vault secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Configure HashiCorp Vault as a vault backend with GCP service account authentication
    url: /how-to/configure-hashicorp-vault-with-gcp-service-account-auth/
  - text: Configure HashiCorp Vault as a vault backend with AWS IAM authentication
    url: /how-to/configure-hashicorp-vault-with-aws-iam-auth/
  - text: Configure HashiCorp Vault as a vault backend with AWS EC2 authentication
    url: /how-to/configure-hashicorp-vault-with-aws-ec2-auth/
  - text: Store Keyring data in a HashiCorp Vault
    url: /how-to/store-keyring-in-hashicorp-vault/
  - text: HashiCorp Google Cloud auth method reference
    url: https://developer.hashicorp.com/vault/api-docs/auth/gcp

works_on:
    - on-prem

min_version:
  gateway: '3.14'

entities:
  - vault

tags:
    - secrets-management
    - security
    - hashicorp-vault

search_aliases:
  - Hashicorp Vault
  - GCP
  - gcp_gce
  - GCE

tldr:
    q: How do I configure HashiCorp Vault to authenticate using GCP workload identity?
    a: |
      Run {{site.base_gateway}} on a GCE instance with a service account attached. Enable the GCP auth method in HashiCorp Vault and create a GCE role bound to your {{site.base_gateway}} service account.

      Then in {{site.base_gateway}}, configure a Vault entity with the following:
      * Set `config.auth_method` to `gcp_gce`
      * Set `config.gcp_auth_role` to the Vault role name. 
        The GCE instance identity token is provided automatically by the instance metadata service, no credential files are required.

tools:
    - admin-api

prereqs:
  skip_product: true
  inline:
    - title: GCE instance with service account
      content: |
        To complete this tutorial, {{site.base_gateway}} must be running on a GCE (Google Compute Engine) instance with a service account that {{site.base_gateway}} will use to authenticate to HashiCorp Vault.
        1. [Enable the following GCP APIs in your project](https://docs.cloud.google.com/endpoints/docs/openapi/enable-api):
           * `iam.googleapis.com`
           * `compute.googleapis.com`
        1. Export the bound project, zone, and labels for your GCE instance:
           ```sh
           export GCP_PROJECT='YOUR GCP PROJECT'
           export GCE_ZONE='YOUR GCE INSTANCE ZONE'
           export GCE_LABEL='YOUR GCE INSTANCE LABELS'
           ```
        1. Create a service account to attach to your GCE instance with the "Compute Viewer" and "View Service Accounts" permissions.  
        1. Export the service account email attached to your GCE instance:
           ```sh
           export GCE_SERVICE_ACCOUNT="kong@YOUR-PROJECT.iam.gserviceaccount.com"
           ```
        1. [Attach the service account to your GCE instance](https://docs.cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances). 

        If {{site.base_gateway}} isn't running on a GCE instance, use [GCP service account authentication](/how-to/configure-hashicorp-vault-with-gcp-service-account-auth/) instead.

      icon_url: /assets/icons/google-cloud.svg

cleanup:
  inline:
    - title: Clean up HashiCorp Vault
      content: |
        Stop the HashiCorp Vault process by running the following:
        ```sh
        pkill vault
        ```

        Unset environment variables:
        ```sh
        unset VAULT_ADDR
        unset VAULT_GCP_CREDENTIALS_FILE
        ```
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: What if {{site.base_gateway}} is not running on a GCE instance?
    a: |
      The `gcp_gce` auth method requires {{site.base_gateway}} to run on a GCE instance. 
      It relies on the GCE instance metadata service to provide the identity token automatically. 
      If {{site.base_gateway}} isn't on GCE, use [GCP service account authentication](/how-to/configure-hashicorp-vault-with-gcp-service-account-auth/) (`gcp_iam`) instead, which works from any environment.
  - q: How do I rotate my secrets in HashiCorp Vault and how does {{site.base_gateway}} pick up the new secret values?
    a: You can rotate your secret in HashiCorp Vault by creating a new secret version with the updated value. You'll also want to configure the `ttl` settings in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} pulls the rotated secret periodically.
  - q: |
      {% include /gateway/vaults-format-faq.md type='question' %}
    a: |
      {% include /gateway/vaults-format-faq.md type='answer' %}

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
  - text: What can be stored as a secret?
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret

automated_tests: false
---

## Configure HashiCorp Vault

Before you can configure the Vault entity in {{site.base_gateway}}, you must configure HashiCorp Vault to authenticate clients using GCE instance identity tokens and store a secret.

### Create configuration files

{% include /gateway/hashicorp-vault-create-policies.md %}

### Configure the Vault and store a secret

{% include /gateway/hashicorp-vault-basic-setup.md %}

1. Enable GCP authentication:
   ```sh
   vault auth enable gcp
   ```

1. Create a GCE role that binds to {{site.base_gateway}}'s GCP service account:
   ```sh
   vault write auth/gcp/role/kong-role \
     type="gce" \
     bound_projects="$GCP_PROJECT" \
     bound_zones="$GCE_ZONE" \
     bound_labels="$GCE_LABEL" \
     bound_service_accounts="$GCE_SERVICE_ACCOUNT" \
     token_policies="rw-secrets"
   ```

1. Enable the K/V secrets engine:
   ```sh
   vault secrets enable -path=kong kv
   ```

1. Create a secret:
   ```sh
   vault kv put kong/headers/request header="x-kong:test"
   ```

1. Confirm you can retrieve the secret through Vault:
   ```sh
   vault kv get kong/headers/request
   ```

## Set environment variables

Find the internal IP for your VM:
```sh
hostname -I
```

Export the following environment variables before creating the Vault entity:

```sh
export HCV_HOST="YOUR VM INTERNAL IP"
export GCP_AUTH_ROLE=kong-role
```

In this tutorial, `host.docker.internal` is used as the host instead of `localhost` because {{site.base_gateway}} is running in a Docker container and uses a different `localhost` from the Vault server.

## Create a Vault entity for HashiCorp Vault

Using decK, create a [Vault entity](/gateway/entities/vault/) in the `kong.yaml` file with the required parameters for HashiCorp Vault GCP workload identity authentication:
{% control_plane_request %}
url: /vaults
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: hcv
  prefix: hashicorp-vault
  description: Storing secrets in HashiCorp Vault
  config:
    host: $HCV_HOST
    kv: v1
    mount: kong
    port: 8200
    protocol: http
    auth_method: gcp_gce
    gcp_auth_role: $GCP_AUTH_ROLE
    gcp_login_path: /v1/auth/gcp/login
{% endcontrol_plane_request %}

## Validate

To validate that the secret was stored correctly in HashiCorp Vault, call a secret from your vault using the `kong vault get` command.

```sh
sudo -E kong vault get {vault://hashicorp-vault/headers/request/header}
```

If the vault was configured correctly, this command returns the value of the secret. You can use `{vault://hashicorp-vault/headers/request/header}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).
