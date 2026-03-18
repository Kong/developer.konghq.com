---
title: Configure HashiCorp Vault as a vault backend with AWS EC2 authentication
permalink: /how-to/configure-hashicorp-vault-with-aws-ec2-auth/
content_type: how_to
description: "Learn how to configure HashiCorp Vault with AWS EC2 authentication and reference HashiCorp Vault secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Configure HashiCorp Vault as a vault backend with AWS IAM authentication
    url: /how-to/configure-hashicorp-vault-with-aws-iam-auth/
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
  - aws_ec2
  - EC2

tldr:
    q: How do I configure HashiCorp Vault to authenticate using AWS EC2?
    a: |
      Run {{site.base_gateway}} on an EC2 instance with an instance profile attached. Enable the AWS auth method in HashiCorp Vault and create an EC2 role bound to the instance's AMI ID.

      Then in {{site.base_gateway}}:
      * Configure a Vault entity with `config.auth_method` set to `aws_ec2`.
      * Set `config.aws_auth_role` to the Vault role name.
      * Set `config.aws_auth_nonce` to a unique nonce string. The EC2 instance identity document is provided automatically by the instance metadata service — no AWS credentials are required on {{site.base_gateway}}'s side.

tools:
    - deck

prereqs:
  inline:
    - title: EC2 instance with instance profile
      content: |
        {{site.base_gateway}} must be running on an EC2 instance with an instance profile attached. The EC2 instance identity document is automatically provided by the instance metadata service — no additional IAM permissions are required on {{site.base_gateway}}'s side.

        If {{site.base_gateway}} is not running on an EC2 instance, use [AWS IAM authentication](/how-to/configure-hashicorp-vault-with-aws-iam-auth/) instead.

        Note the AMI ID of your EC2 instance and export it:
        ```sh
        export KONG_EC2_AMI_ID="ami-0abcdef1234567890"
        ```

        Generate a unique nonce string. This nonce is stored with the Vault token and validated on subsequent logins to prevent replay attacks:
        ```sh
        export DECK_AWS_AUTH_NONCE="$(openssl rand -hex 16)"
        ```
      icon_url: /assets/icons/aws.svg
    - title: AWS credentials for the Vault server
      content: |
        HashiCorp Vault must call AWS EC2 APIs to verify incoming EC2 instance identity documents. The Vault server needs IAM credentials with the following permissions:
        * `ec2:DescribeInstances`
        * `iam:GetInstanceProfile`

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
  - q: What if {{site.base_gateway}} is not running on an EC2 instance?
    a: |
      The `aws_ec2` auth method requires {{site.base_gateway}} to run on an EC2 instance — it relies on the EC2 instance metadata service to provide the instance identity document automatically. If {{site.base_gateway}} is not on EC2, use [AWS IAM authentication](/how-to/configure-hashicorp-vault-with-aws-iam-auth/) (`aws_iam`) instead, which works from any environment with AWS credentials.
  - q: What is the nonce used for in EC2 authentication?
    a: |
      The nonce is a unique client-provided value stored alongside the Vault token after the first successful EC2 login. On subsequent logins from the same instance, Vault validates that the same nonce is presented, preventing replay attacks where a stolen instance identity document could be used to authenticate from a different host. Store the nonce securely and use the same value consistently across {{site.base_gateway}} nodes running on the same instance.
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

{:.warning}
> **Important:** This how-to requires {{site.base_gateway}} to be running on an EC2 instance with an instance profile attached. The instance identity document is provided automatically by the EC2 instance metadata service — no additional IAM permissions are required on {{site.base_gateway}}'s side. If {{site.base_gateway}} is not running on EC2, use [AWS IAM authentication](/how-to/configure-hashicorp-vault-with-aws-iam-auth/) instead.

## Configure HashiCorp Vault

Before you can configure the Vault entity in {{site.base_gateway}}, you must configure HashiCorp Vault to authenticate clients using EC2 instance identity documents and store a secret.

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

1. Create an EC2 role that binds to your {{site.base_gateway}} instance's AMI ID:
   ```sh
   vault write auth/aws/role/kong-role \
     auth_type=ec2 \
     bound_ami_id="$KONG_EC2_AMI_ID" \
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

Using decK, create a [Vault entity](/gateway/entities/vault/) in the `kong.yaml` file with the required parameters for HashiCorp Vault AWS EC2 authentication:

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
        auth_method: aws_ec2
        aws_auth_role: ${aws_auth_role}
        aws_auth_nonce: ${aws_auth_nonce}

variables:
  hcv_host:
    value: $HCV_HOST
  aws_auth_role:
    value: $AWS_AUTH_ROLE
  aws_auth_nonce:
    value: $AWS_AUTH_NONCE
{% endentity_examples %}

## Validate

To validate that the secret was stored correctly in HashiCorp Vault, call a secret from your vault using the `kong vault get` command within the Data Plane container.

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/headers/request/header}'
value: 'x-kong:test'
{% endvalidation %}

If the vault was configured correctly, this command returns the value of the secret. You can use `{vault://hashicorp-vault/headers/request/header}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).
