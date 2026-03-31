---
title: Configure HashiCorp Vault as a vault backend with GCP service account authentication
permalink: /how-to/configure-hashicorp-vault-with-gcp-service-account-auth/
content_type: how_to
description: "Learn how to configure HashiCorp Vault with GCP IAM authentication using a service account and reference HashiCorp Vault secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Configure HashiCorp Vault as a vault backend with GCP workload identity
    url: /how-to/configure-hashicorp-vault-with-gcp-workload-identity/
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
  - gcp_iam

tldr:
    q: How do I configure HashiCorp Vault to authenticate using a GCP service account?
    a: |
      Run {{site.base_gateway}} in a Google Cloud VM instance. Enable the GCP auth method in HashiCorp Vault and configure it with your Vault server's GCP service account credentials, the IAM role bound to {{site.base_gateway}}'s service account, and store a secret.

      Then in {{site.base_gateway}}, configure a Vault entity with the following:
      * Set `config.auth_method` set to `gcp_iam`.
      * Set `config.gcp_auth_role` to the Vault role name.
      * Set `config.gcp_service_account` to the GCP service account email that {{site.base_gateway}} will authenticate as.
      * Set `config.gcp_jwt_exp` to the JWT expiration time in seconds (maximum 900).

      Retrieve the secret with `{vault://hashicorp-vault/headers/request/header}`.

tools:
    - admin-api

prereqs:
  skip_product: true
  inline:
    - title: GCP service account for {{site.base_gateway}}
      content: |
        To complete this tutorial, you need a GCP project with the `iam.googleapis.com` API enabled and a GCP service account that {{site.base_gateway}} will use to authenticate to HashiCorp Vault.

        1. In the [Google Cloud console](https://console.cloud.google.com/), create a service account key and grant IAM permissions:
           1. In the [Service Account settings](https://console.cloud.google.com/iam-admin/serviceaccounts), click your project.
           1. Click **Create service account**.
           1. Enter a name for your service account.
           1. Copy and export the service account email:
              ```sh
              export GCP_SERVICE_ACCOUNT_EMAIL="kong@YOUR-PROJECT.iam.gserviceaccount.com"
              ```
           1. Click **Create and continue**.
           1. From the **Select a role** dropdown menu, select "Service Account Token Creator" and "Service Account Key Admin". 
              For more information about this role, see [Roles for service account authentication](https://docs.cloud.google.com/iam/docs/service-account-permissions#token-creator-role).
           1. Click **Continue**.
           1. In the **Service account users role** field, enter your service account email.
           1. In the **Service account admins role** field, enter your service account email. 
              
              {:.warning}
              > **Scope the role to the service account only**: You must scope the Service Account Token Creator to the service account itself instead of project-wide. HashiCorp explicitly warns that a [project-wide grant allows the service account to impersonate any other service account in the project](https://developer.hashicorp.com/vault/docs/auth/gcp#permissions-for-authenticating-against-vault).
           1. Click **Done**.

      icon_url: /assets/icons/google-cloud.svg
    - title: HashiCorp Vault
      content: |
        You need [HashiCorp Vault installed](https://developer.hashicorp.com/vault/install) on your VM. 

        The steps in this how to assume that HashiCorp Vault and {{site.base_gateway}} are installed on the same VM. 
        Production instances will often install HashiCorp Vault and {{site.base_gateway}} on separate VMS. 
        If this is the case, see the [HashiCorp Vault GCP authentication documentation](https://developer.hashicorp.com/vault/docs/auth/gcp) for the configuration changes you'll need to make.
      icon_url: /assets/icons/hashicorp.svg

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
        unset DECK_GCP_SERVICE_ACCOUNT
        ```
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
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

Before you can configure the Vault entity in {{site.base_gateway}}, you must configure HashiCorp Vault to authenticate clients using GCP service account JWTs and store a secret.

### Create configuration files

{% include /gateway/hashicorp-vault-create-policies.md %}

### Configure the Vault and store a secret

{% include /gateway/hashicorp-vault-basic-setup.md %}

1. Enable GCP authentication:
   ```sh
   vault auth enable gcp
   ```

1. Create an IAM role that binds to {{site.base_gateway}}'s GCP service account:
   ```sh
   vault write auth/gcp/role/kong-role \
     type="iam" \
     bound_service_accounts="$GCP_SERVICE_ACCOUNT_EMAIL" \
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

## Create a Vault entity for HashiCorp Vault

Using decK, create a [Vault entity](/gateway/entities/vault/) in the `kong.yaml` file with the required parameters for HashiCorp Vault GCP IAM authentication:
<!--vale off-->
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
    auth_method: gcp_iam
    gcp_auth_role: $GCP_AUTH_ROLE
    gcp_service_account: $GCP_SERVICE_ACCOUNT_EMAIL
    gcp_jwt_exp: 900
{% endcontrol_plane_request %}
<!--vale on-->

## Validate

To validate that the secret was stored correctly in HashiCorp Vault, call a secret from your vault using the `kong vault get` command within the Data Plane container.

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/headers/request/header}'
value: 'x-kong:test'
{% endvalidation %}

If the vault was configured correctly, this command returns the value of the secret. You can use `{vault://hashicorp-vault/headers/request/header}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).
