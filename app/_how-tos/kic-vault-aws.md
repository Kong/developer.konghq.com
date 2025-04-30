---
title: Configure an AWS Secrets Manager Vault
description: "Configure Secrets Manager AWS Vault with {{ site.kic_product_name }} and the KongVault CRD"
content_type: how_to

permalink: /kubernetes-ingress-controller/vault/aws/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - /gateway/secrets-management/

min_version:
  kic: '3.1'

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I configure Hashicorp Vault with {{ site.kic_product_name }}?
  a: Create a `KongVault` CRD and then use the `vault://` reference in your plugin configuration

prereqs:
  enterprise: true
  kubernetes:
    skip_proxy_ip: true
    gateway_custom_env:
      AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
      AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
  inline:
    - title: AWS configuration
      position: before
      content: |
        This tutorial requires at least one [secret](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html) in AWS Secrets Manager. In this example, the secret is named `my-aws-secret` and contains a key/value pair in which the key is `token`.

        You will also need the following authentication information to connect your AWS Secrets Manager with {{site.ee_product_name}}:
        - Your access key ID
        - Your secret access key
        - Your AWS region, `us-east-1` in this example
      icon_url: /assets/icons/aws.svg

    - title: Environment variables
      position: before
      content: |
          Set the environment variables needed to authenticate to AWS:
          ```sh
          export AWS_ACCESS_KEY_ID=your-aws-access-key-id
          export AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
          ```

          These values will be populated in `values.yaml` when installing {{ site.kic_product_name }}
      icon_url: /assets/icons/file.svg

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
    - title: Clean up AWS resources
      include_content: cleanup/third-party/aws
      icon_url: /assets/icons/aws.svg

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/

tags:
  - secrets-management
  - security
---


## Create a KongVault entity

{{ site.kic_product_name }} uses the `KongVault` entity to configure the connection to a Vault. As we're running Hashicorp Vault in `dev` mode, we can use the `root` token to access the Vault:

{% entity_example %}
type: vault
data:
  name: aws
  prefix: aws-vault
  description: Storing secrets in AWS Secrets Manager
  config:
    region: us-east-1
{% endentity_example %}

We can now access secrets in this vault using the `vault://aws-vault/$KEY` syntax. The `aws-vault` prefix matches the `prefix` field in the `KongVault` resource.

## Validate your configuration

To validate that the secret was stored correctly in AWS Secrets Manager, you can call a secret from your vault using the `kong vault get` command within the Data Plane Pod.

{% validation vault-secret %}
secret: '{vault://aws-vault/my-aws-secret/token}'
value: 'ACME Inc.'
command: kubectl exec -n kong -it deployment/kong-gateway -c proxy --
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://aws-vault/my-aws-secret/token}` to reference the secret in any referenceable field.