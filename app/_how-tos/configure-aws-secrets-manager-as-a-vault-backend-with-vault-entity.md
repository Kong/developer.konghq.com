---
title: Configure AWS Secrets Manager as a vault backend using the Vault entity
content_type: how_to
related_resources:
  - text: Rotate secrets in AWS Secrets Manager with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-aws-secrets-manager  
  - text: Secrets management
    url: /secrets-management 

products:
  - gateway

tier: enterprise

works_on:
  - on-prem

min_version:
  gateway: '3.4'

plugins:

entities: 
  - vault

tags:
  - security

tldr:
    q: How can I access AWS Secrets Manager secrets in {{site.base_gateway}}?
    a: |
      Set the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` environment variables, then start {{site.base_gateway}} with these environment variables. Create a Vault entity and add the required `region` parameter.

tools:
  - deck

prereqs:
  inline:
    - title: AWS configuration
      content: |
        This tutorial requires at least one [secret](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html) in AWS Secrets Manager. In this example, the secret is named `my-aws-secret` and contains a key/value pair in which the key is `token`.
        
        You will also need the following authentication information to connect your AWS Secrets Manager with {{site.ee_product_name}}:
        - Your access key ID
        - Your secret access key
        - Your session token
        - Your AWS region, `us-east-1` in this example
      icon_url: /assets/icons/aws.svg

    - title: Environment variables
      content: |
          Set the environment variables needed to authenticate to AWS:
          ```sh
          export AWS_ACCESS_KEY_ID=your-aws-access-key-id
          export AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
          export AWS_SESSION_TOKEN=your-aws-session-token
          ```
          Note that these variables need to be passed when creating your Data Plane container.
      icon_url: /assets/icons/file.svg
    - title: Kong Gateway running
      content: |
        @TODO - Temporary prereq, to be removed when custom parameter option is implemented
        This tutorial requires {{site.ee_product_name}}.
        If you don't have {{site.base_gateway}} set up yet, you can use the
        [quickstart script](https://get.konghq.com/quickstart) with an enterprise license
        to get an instance of {{site.base_gateway}} running almost instantly.
        1. Export your license to an environment variable:
            ```
            export KONG_LICENSE_DATA='<license-contents-go-here>'
            ```
        2. Run the quickstart script:
            ```bash
            curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA \
              -e AWS_ACCESS_KEY_ID \
              -e AWS_SECRET_ACCESS_KEY \
              -e AWS_SESSION_TOKEN
            ```
            Once {{site.base_gateway}} is ready, you will see the following message:
            ```bash
            Kong Gateway Ready
            ```
            {:.no-copy-code}
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
---

## 1. Configure the Vault entity

Create a Vault entity with the required parameters for AWS:

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

To validate, you can call your secret using the `kong vault get` command in your Data Plane container. If the Docker container is named `kong-quickstart-gateway`, you can use the following command:

```sh
docker exec kong-quickstart-gateway kong vault get {vault://aws-vault/my-aws-secret/token}
```

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://aws-vault/my-aws-secret/token}` to reference the secret in any referenceable field.