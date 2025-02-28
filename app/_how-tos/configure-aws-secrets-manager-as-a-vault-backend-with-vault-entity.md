---
title: Configure AWS Secrets Manager as a vault backend using the Vault entity
content_type: how_to
related_resources:
  - text: Rotate secrets in AWS Secrets Manager with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-aws-secrets-manager/
  - text: Secrets management
    url: /secrets-management/

products:
  - gateway

tier: enterprise

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
    q: How can I access AWS Secrets Manager secrets in {{site.base_gateway}}?
    a: |
      Set the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` environment variables, then start {{site.base_gateway}} with these environment variables. Create a Vault entity and add the required `region` parameter.

tools:
  - deck

prereqs:
  gateway:
    - name: AWS_ACCESS_KEY_ID
    - name: AWS_SECRET_ACCESS_KEY
    - name: AWS_SESSION_TOKEN
  inline:
    - title: AWS configuration
      position: before
      content: |
        This tutorial requires at least one [secret](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html) in AWS Secrets Manager. In this example, the secret is named `my-aws-secret` and contains a key/value pair in which the key is `token`.
        
        You will also need the following authentication information to connect your AWS Secrets Manager with {{site.ee_product_name}}:
        - Your access key ID
        - Your secret access key
        - Your session token
        - Your AWS region, `us-east-1` in this example
      icon_url: /assets/icons/aws.svg

    - title: Environment variables
      position: before
      content: |
          Set the environment variables needed to authenticate to AWS:
          ```sh
          export AWS_ACCESS_KEY_ID=your-aws-access-key-id
          export AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
          export AWS_SESSION_TOKEN=your-aws-session-token
          ```
          Note that these variables need to be passed when creating your Data Plane container.
      icon_url: /assets/icons/file.svg

cleanup:
  inline:
    - title: Clean up AWS resources
      include_content: cleanup/third-party/aws
      icon_url: /assets/icons/aws.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg 

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---

## 1. Configure the Vault entity

Using decK, create a Vault entity with the required parameters for AWS:

{% entity_example %}
type: vault
data:
  name: aws
  prefix: aws-vault
  description: Storing secrets in AWS Secrets Manager
  config:
    region: us-east-1
{% endentity_example %}

## 2. Validate

To validate that the secret was stored correctly in AWS you can use the `kong vault get` command within the Data Plane container. If the Docker container is named `kong-quickstart-gateway`, you can use the following command:

```sh
docker exec kong-quickstart-gateway kong vault get {vault://aws-vault/my-aws-secret/token}
```

If the vault was configured correctly, this command should return the value of the secret. Then, you can use `{vault://aws-vault/my-aws-secret/token}` to reference the secret in any referenceable field.