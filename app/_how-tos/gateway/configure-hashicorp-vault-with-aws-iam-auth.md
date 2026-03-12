---
title: Configure HashiCorp Vault as a vault backend with AWS IAM authentication
permalink: /how-to/configure-hashicorp-vault-with-aws-iam-auth/
content_type: how_to
description: "Learn how to configure HashiCorp Vault with AWS IAM authentication and reference HashiCorp Vault secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Configure HashiCorp Vault as a vault backend with AWS EC2 authentication
    url: /how-to/configure-hashicorp-vault-with-aws-ec2-auth/
  - text: Configure HashiCorp Vault as a vault backend with GCP service account authentication
    url: /how-to/configure-hashicorp-vault-with-gcp-service-account-auth/
  - text: Configure HashiCorp Vault as a vault backend with GCP workload identity
    url: /how-to/configure-hashicorp-vault-with-gcp-workload-identity/
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
    - aws

search_aliases:
  - Hashicorp Vault
  - AWS
  - aws_iam

tldr:
    q: How do I configure HashiCorp Vault to authenticate using AWS IAM?
    a: |
      Enable the AWS auth method in HashiCorp Vault, configure it with credentials that can verify IAM identity, and create an IAM role bound to Kong's IAM principal ARN.

      Then in {{site.base_gateway}}:
      * Configure a Vault entity with `config.auth_method` set to `aws_iam`.
      * Set `config.aws_auth_role` to the Vault role name.
      * Set `config.aws_auth_region` to your AWS region.
      * Optionally set `config.aws_access_key_id` and `config.aws_secret_access_key` for Kong's AWS credentials. If omitted, Kong uses the default AWS credentials provider chain.

tools:
    - deck

prereqs:
  inline:
    - title: AWS IAM principal for Kong
      content: |
        You need an AWS IAM role or user that Kong will use to authenticate to HashiCorp Vault.

        Kong's IAM principal does not need any additional IAM policies. The `sts:GetCallerIdentity` action — which Vault uses to verify the identity — is available to all authenticated AWS principals by default.

        Export Kong's AWS credentials and the ARN of the IAM principal:
        ```sh
        export DECK_AWS_ACCESS_KEY_ID="KONG-ACCESS-KEY-ID"
        export DECK_AWS_SECRET_ACCESS_KEY="KONG-SECRET-ACCESS-KEY"
        export DECK_AWS_AUTH_REGION="us-east-1"
        export KONG_IAM_PRINCIPAL_ARN="arn:aws:iam::123456789012:user/kong"
        ```

        Replace `KONG-ACCESS-KEY-ID` and `KONG-SECRET-ACCESS-KEY` with the credentials for Kong's IAM principal, and `KONG_IAM_PRINCIPAL_ARN` with the ARN of the IAM user or role.
      icon_url: /assets/icons/aws.svg
    - title: AWS credentials for the Vault server
      content: |
        HashiCorp Vault must call AWS IAM APIs to verify incoming authentication requests. The Vault server needs IAM credentials with the following permissions:
        * `iam:GetUser`
        * `iam:GetRole`

        Export the Vault server's AWS credentials:
        ```sh
        export VAULT_AWS_ACCESS_KEY="VAULT-SERVER-ACCESS-KEY"
        export VAULT_AWS_SECRET_KEY="VAULT-SERVER-SECRET-KEY"
        ```
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
        unset VAULT_AWS_ACCESS_KEY
        unset VAULT_AWS_SECRET_KEY
        ```
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: Do I have to provide `aws_access_key_id` and `aws_secret_access_key` in the Vault entity?
    a: |
      No, these fields are optional. If omitted, {{site.base_gateway}} uses the default AWS credentials provider chain, which checks environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), shared credential files, and EC2 instance profiles in order. Providing them explicitly in the entity is useful when you want to configure Kong's AWS identity independently of the host environment.
  - q: How does Vault verify the AWS IAM identity without requiring extra IAM permissions?
    a: |
      {{site.base_gateway}} signs an AWS `sts:GetCallerIdentity` request using the configured AWS credentials and sends it to HashiCorp Vault. Vault then forwards the signed request to AWS STS and checks the returned identity against the `bound_iam_principal_arn` configured in the role. The `sts:GetCallerIdentity` action requires no explicit IAM policy — it is available to all authenticated AWS identities by default.
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

Before you can configure the Vault entity in {{site.base_gateway}}, you must configure HashiCorp Vault to authenticate clients using AWS IAM identity and store a secret.

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
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
```

### Configure the Vault and store a secret

1. Start HashiCorp Vault:
   ```sh
   vault server -config=./vault/config.hcl
   ```

1. In a new terminal, set the Vault address:
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

1. Enable AWS authentication:
   ```sh
   vault auth enable aws
   ```

1. Configure the AWS auth method with the Vault server's AWS credentials:
   ```sh
   vault write auth/aws/config/client \
     access_key="$VAULT_AWS_ACCESS_KEY" \
     secret_key="$VAULT_AWS_SECRET_KEY"
   ```

1. Create an IAM role that binds to Kong's IAM principal:
   ```sh
   vault write auth/aws/role/kong-role \
     auth_type=iam \
     bound_iam_principal_arn="$KONG_IAM_PRINCIPAL_ARN" \
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

Export the following environment variables before creating the Vault entity:

```sh
export DECK_HCV_HOST=host.docker.internal
export DECK_AWS_AUTH_ROLE=kong-role
```

In this tutorial, `host.docker.internal` is used as the host instead of `localhost` because {{site.base_gateway}} is running in a Docker container and uses a different `localhost` from the Vault server.

## Create a Vault entity for HashiCorp Vault

Using decK, create a [Vault entity](/gateway/entities/vault/) in the `kong.yaml` file with the required parameters for HashiCorp Vault AWS IAM authentication:

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
        auth_method: aws_iam
        aws_auth_role: ${aws_auth_role}
        aws_auth_region: ${aws_auth_region}
        aws_access_key_id: ${aws_access_key_id}
        aws_secret_access_key: ${aws_secret_access_key}

variables:
  hcv_host:
    value: $HCV_HOST
  aws_auth_role:
    value: $AWS_AUTH_ROLE
  aws_auth_region:
    value: $AWS_AUTH_REGION
  aws_access_key_id:
    value: $AWS_ACCESS_KEY_ID
  aws_secret_access_key:
    value: $AWS_SECRET_ACCESS_KEY
{% endentity_examples %}

`aws_access_key_id` and `aws_secret_access_key` are optional. If omitted, {{site.base_gateway}} uses the default AWS credentials provider chain (environment variables, shared credential files, EC2 instance profile).

## Validate

To validate that the secret was stored correctly in HashiCorp Vault, call a secret from your vault using the `kong vault get` command within the Data Plane container.

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/headers/request/header}'
value: 'x-kong:test'
{% endvalidation %}

If the vault was configured correctly, this command returns the value of the secret. You can use `{vault://hashicorp-vault/headers/request/header}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).
