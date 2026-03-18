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
      Enable the GCP auth method in HashiCorp Vault, configure it with your Vault server's GCP service account credentials, and create an IAM role bound to {{site.base_gateway}}'s service account.

      Then in {{site.base_gateway}}:
      * Configure a Vault entity with `config.auth_method` set to `gcp_iam`.
      * Set `config.gcp_auth_role` to the Vault role name.
      * Set `config.gcp_service_account` to the GCP service account email that {{site.base_gateway}}will authenticate as.
      * Set `config.gcp_jwt_exp` to the JWT expiration time in seconds (maximum 900).

tools:
    - deck

prereqs:
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
              export GCP_SERVICE_ACCOUNT_EMAIL="YOUR SERVICE ACCOUNT EMAIL"
              ```
           1. Click **Create and continue**.
           1. From the **Select a role** dropdown menu, select "Service Account Token Creator". 
              For more information about this role, see [Roles for service account authentication](https://docs.cloud.google.com/iam/docs/service-account-permissions#token-creator-role).
           1. Click **Continue**.
           1. In the **Service account users role** field, enter your service account email.
           1. In the **Service account admins role** field, enter your service account email. 
              
              {:.warning}
              > **Scope the role to the service account only**: You must scope the Service Account Token Creator to the service account itself instead of project-wide. HashiCorp explicitly warns that a [project-wide grant allows the service account to impersonate any other service account in the project](https://developer.hashicorp.com/vault/docs/auth/gcp#permissions-for-authenticating-against-vault).
           1. Click **Done**.
          1. Click the service account you just created.
          2. From the **Keys** tab, create a new key from the add key menu and select JSON for the key type.
          3. Save the JSON file you downloaded.
          1. Set the environment variables needed to authenticate to Google Cloud:
             ```sh
             export DECK_GCP_SERVICE_ACCOUNT="/path/to/service-account.json"
             export KONG_LUA_SSL_TRUSTED_CERTIFICATE='system'
             ```

             {{site.base_gateway}} uses Application Default Credentials to sign JWTs when authenticating to Vault. Note that these variables need to be passed when creating your Data Plane container.

      icon_url: /assets/icons/google-cloud.svg
    - title: GCP credentials for the Vault server
      content: |
        HashiCorp Vault must call GCP IAM APIs to verify incoming service account JWTs. You need a separate GCP service account for the Vault server with `roles/iam.serviceAccountKeyAdmin`.
        1. In the [Google Cloud console](https://console.cloud.google.com/), create a Vault server service account and grant IAM permissions:
           1. In the [Service Account settings](https://console.cloud.google.com/iam-admin/serviceaccounts), click your project.
           1. Click **Create service account**.
           1. Enter a name for your Vault server service account.
           1. Click **Create and continue**.
           1. From the **Select a role** dropdown menu, select "Service Account Key Admin". 
              For more information about this role, see [Roles for service account authentication](https://docs.cloud.google.com/iam/docs/service-account-permissions#token-creator-role).
           1. Click **Continue**.
           1. Click **Done**.
          1. Click the service account you just created.
          2. From the **Keys** tab, create a new key from the add key menu and select JSON for the key type.
          3. Save the JSON file you downloaded.
          1. Export the Vault server service account JSON:
             ```sh
             export VAULT_GCP_CREDENTIALS_FILE="/path/to/vault-server-sa-key.json"
             ```
      icon_url: /assets/icons/google-cloud.svg
  gateway:
    - name: GOOGLE_APPLICATION_CREDENTIALS
  konnect:
    - name: GOOGLE_APPLICATION_CREDENTIALS

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
  - q: My Vault role uses `roles/iam.serviceAccountTokenCreator` granted at the project level — is that a problem?
    a: |
      Yes. HashiCorp explicitly warns that granting `roles/iam.serviceAccountTokenCreator` at the project level allows the service account to impersonate **any** service account in the project, which is a significant security risk. Scope this role to the {{site.base_gateway}} service account itself only.
  - q: Do I need to set `DECK_GCP_SERVICE_ACCOUNT` on every {{site.base_gateway}}node?
    a: Yes. Each {{site.base_gateway}} node needs access to the GCP service account credentials to sign the JWT used in the `gcp_iam` auth flow. Set `DECK_GCP_SERVICE_ACCOUNT` to the path of the JSON key file on every node, or use a secrets management solution to distribute the key.
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

First, create the primary configuration file `config.hcl` for HashiCorp Vault in the `./vault` directory:
```
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

storage "file" {
  path = "./vault/data"
}

ui = true
```

Then, create the HashiCorp Vault policy file `rw-secrets.hcl` in the `./vault` directory:
```
# Full access to everything — use with caution!
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
```

### Configure the Vault and store a secret

1. In a new terminal, start HashiCorp Vault:
   ```sh
   vault server -config=./vault/config.hcl
   ```

1. In your previous terminal, set the Vault address:
   ```sh
   export VAULT_ADDR="http://localhost:8200"
   ```

1. Initialize the Vault:
   ```sh
   vault operator init -key-shares=1 -key-threshold=1
   ```
   This outputs your unseal key and initial root token. Export them as environment variables:
   ```sh
   export HCV_UNSEAL_KEY='YOUR-UNSEAL-KEY'
   export DECK_HCV_TOKEN='YOUR-INITIAL-ROOT-TOKEN'
   ```

1. Unseal your Vault:
   ```sh
   vault operator unseal $HCV_UNSEAL_KEY
   ```

1. Log in to your Vault:
   ```sh
   vault login $DECK_HCV_TOKEN
   ```

1. Write the policy to access secrets:
   ```sh
   vault policy write rw-secrets ./vault/rw-secrets.hcl
   ```

1. Enable GCP authentication:
   ```sh
   vault auth enable gcp
   ```

1. Configure the GCP auth method with the Vault server's GCP credentials:
   ```sh
   vault write auth/gcp/config \
     credentials=@$VAULT_GCP_CREDENTIALS_FILE
   ```

1. Create an IAM role that binds to {{site.base_gateway}}'s GCP service account:
   ```sh
   vault write auth/gcp/role/kong-role \
     type="iam" \
     bound_service_accounts="$DECK_GCP_SERVICE_ACCOUNT" \
     token_policies="rw-secrets"
   ```

1. Verify the GCP IAM login works:
   ```sh
   vault login -method=gcp \
     role="kong-role" \
     service_account="$GCP_SERVICE_ACCOUNT_EMAIL" \
     jwt_exp="15m" \
     credentials=@"$DECK_GCP_SERVICE_ACCOUNT"
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

Export the following environment variables before creating the Vault entity:

```sh
export DECK_HCV_HOST=host.docker.internal
export DECK_GCP_AUTH_ROLE=kong-role
```

In this tutorial, `host.docker.internal` is used as the host instead of `localhost` because {{site.base_gateway}} is running in a Docker container and uses a different `localhost` from the Vault server.

## Create a Vault entity for HashiCorp Vault

Using decK, create a [Vault entity](/gateway/entities/vault/) in the `kong.yaml` file with the required parameters for HashiCorp Vault GCP IAM authentication:

{% entity_examples %}
entities:
  vaults:
    - name: hcv
      prefix: hashicorp-vault
      description: Storing secrets in HashiCorp Vault
      config:
        host: ${hcv_host}
        kv: v1
        mount: kong
        port: 8200
        protocol: http
        auth_method: gcp_iam
        gcp_auth_role: ${gcp_auth_role}
        gcp_service_account: ${gcp_service_account}
        gcp_jwt_exp: 900

variables:
  hcv_host:
    value: $HCV_HOST
  gcp_auth_role:
    value: $GCP_AUTH_ROLE
  gcp_service_account:
    value: $GCP_SERVICE_ACCOUNT
{% endentity_examples %}

## Validate

To validate that the secret was stored correctly in HashiCorp Vault, call a secret from your vault using the `kong vault get` command within the Data Plane container.

<!--
```sh
docker cp /path/to/service-account.json kong-quickstart-gateway:/tmp/kong-sa.json
docker exec kong-quickstart-gateway bash -c "export GOOGLE_APPLICATION_CREDENTIALS=/tmp/kong-sa.json && kong vault get '{vault://hashicorp-vault/headers/request/header}'"
```
-->

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/headers/request/header}'
value: 'x-kong:test'
{% endvalidation %}

If the vault was configured correctly, this command returns the value of the secret. You can use `{vault://hashicorp-vault/headers/request/header}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).
