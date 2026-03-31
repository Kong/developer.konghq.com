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
  - text: HashiCorp AWS auth method reference
    url: https://developer.hashicorp.com/vault/api-docs/auth/aws

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
      Enable the AWS auth method in HashiCorp Vault, configure it with credentials that can verify IAM identity, and create an IAM role bound to {{site.base_gateway}}'s IAM principal ARN.

      Then in {{site.base_gateway}}, configure a Vault entity with the following:
      * Set `config.auth_method` to `aws_iam`.
      * Set `config.aws_auth_role` to the Vault role name.
      * Set `config.aws_auth_region` to your AWS region.
      * Optionally, set `config.aws_access_key_id` and `config.aws_secret_access_key` for {{site.base_gateway}}'s AWS credentials. If omitted, {{site.base_gateway}} uses the default AWS credentials provider chain.

tools:
    - admin-api

prereqs:
  skip_product: true
  inline:
    - title: AWS IAM principal for {{site.base_gateway}}
      content: |
        You need an [AWS IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started-workloads.html) that {{site.base_gateway}} will use to authenticate to HashiCorp Vault.

        {{site.base_gateway}}'s IAM principal doesn't need any additional IAM policies. The `sts:GetCallerIdentity` action that Vault uses to verify the identity is available to all authenticated AWS principals by default.

        Export {{site.base_gateway}}'s AWS credentials and the ARN of the IAM principal:
        ```sh
        export AWS_ACCESS_KEY_ID="KONG-ACCESS-KEY-ID"
        export AWS_SECRET_ACCESS_KEY="KONG-SECRET-ACCESS-KEY"
        export AWS_AUTH_REGION="us-east-1"
        export KONG_IAM_PRINCIPAL_ARN="arn:aws:iam::123456789012:user/kong"
        ```
      icon_url: /assets/icons/aws.svg
    - title: HashiCorp Vault
      content: |
        You need [HashiCorp Vault installed](https://developer.hashicorp.com/vault/install) on your VM. 

        The steps in this how to assume that HashiCorp Vault and {{site.base_gateway}} are installed on the same VM. 
        Production instances will often install HashiCorp Vault and {{site.base_gateway}} on separate VMS. 
        If this is the case, see the [HashiCorp Vault AWS authentication documentation](https://developer.hashicorp.com/vault/docs/auth/aws) for the configuration changes you'll need to make.
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
        unset AWS_ACCESS_KEY_ID
        unset AWS_SECRET_ACCESS_KEY
        ```
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: Do I have to provide `aws_access_key_id` and `aws_secret_access_key` in the Vault entity?
    a: |
      No, these fields are optional. If omitted, {{site.base_gateway}} uses the default AWS credentials provider chain, which checks environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), shared credential files, and EC2 instance profiles in order. Providing them explicitly in the entity is useful when you want to configure {{site.base_gateway}}'s AWS identity independently of the host environment.
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

{% include /gateway/hashicorp-vault-create-policies.md %}

### Configure the Vault and store a secret

{% include /gateway/hashicorp-vault-basic-setup.md %}

1. Enable AWS authentication:
   ```sh
   vault auth enable aws
   ```

1. (skip to try out) Configure the AWS client with access keys:
   ```sh
   vault write auth/aws/config/client \
    secret_key=$AWS_SECRET_ACCESS_KEY \
    access_key=$AWS_ACCESS_KEY_ID \
    use_sts_region_from_client=true
   ```

1. Create an IAM role that binds to {{site.base_gateway}}'s IAM principal:
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

Find the internal IP for your VM:
```sh
hostname -I
```

Export the following environment variables before creating the Vault entity:

```sh
export HCV_HOST="YOUR VM INTERNAL IP"
export AWS_AUTH_ROLE=kong-role
```

## Create a Vault entity for HashiCorp Vault

Using decK, create a [Vault entity](/gateway/entities/vault/) in the `kong.yaml` file with the required parameters for HashiCorp Vault AWS IAM authentication:

{% control_plane_request %}
url: /vaults
method: POST
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
    auth_method: aws_iam
    aws_auth_role: $AWS_AUTH_ROLE
    aws_auth_region: $AWS_AUTH_REGION
{% endcontrol_plane_request %}

{:.info}
> **Cross-account access:** If {{site.base_gateway}} and your Vault server are in different AWS accounts, configure `aws_assume_role_arn` with the ARN of the role Kong should assume in the target account, and `aws_role_session_name` with a session identifier. If you configure the Vault this way for cross-account access, `aws_access_key_id` and `aws_secret_access_key` are optional.

## Validate

To validate that the secret was stored correctly in HashiCorp Vault, call a secret from your vault using the `kong vault get` command within the Data Plane container.

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/headers/request/header}'
value: 'x-kong:test'
{% endvalidation %}

If the vault was configured correctly, this command returns the value of the secret. You can use `{vault://hashicorp-vault/headers/request/header}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).
