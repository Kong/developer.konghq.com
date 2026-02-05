---
title: Configure AWS Secrets Manager as a vault backend
permalink: /how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/
content_type: how_to
related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: "{{site.base_gateway}} CLI: kong vault"
    url: /gateway/cli/reference/#kong-vault

description: Learn how to set up AWS Secrets Manager as a Vault in {{site.base_gateway}} and reference a secret stored there.
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
  - aws

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
  konnect:
    - name: AWS_ACCESS_KEY_ID
    - name: AWS_SECRET_ACCESS_KEY
    - name: AWS_SESSION_TOKEN
  cloud:
    aws:
      secret: true

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg 

faqs:
  - q: How do I rotate my secrets in AWS Secrets Manager and how does {{site.base_gateway}} pick up the new secret values?
    a: You can rotate your secret in AWS Secrets Manager by creating a new secret version with the updated value. You'll also want to configure the `ttl` settings in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} pulls the rotated secret periodically.
  - q: My secret in AWS Secret Manager has a `/` backslash in the secret name. How do I reference this secret in {{site.base_gateway}}?
    a: |
      The slash symbol (`/`) is a valid character for the secret name in AWS Secrets Manager. If you want to reference a secret name that starts with a slash or has two consecutive slashes, transform one of the slashes in the name into URL-encoded format. For example:
      * A secret named `/secret/key` should be referenced as `{vault://aws/%2Fsecret/key}`
      * A secret named `secret/path//aaa/key` should be referenced as `{vault://aws/secret/path/%2Faaa/key}`
      
      Since {{site.base_gateway}} tries to resolve the secret reference as a valid URL, using a slash instead of a URL-encoded slash will result in unexpected secret name fetching.
  - q: I have secrets stored in multiple AWS Secret Manager regions, how do I reference those secrets in {{site.base_gateway}}?
    a: |
      You can create multiple Vault entities, one per region with the `config.region` parameter. You'd then reference the secret by the name of the Vault:
      ```sh
      {vault://aws-eu-central-vault/secret-name/foo}
      {vault://aws-us-west-vault/secret-name/snip}
      ```
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

## Configure the Vault entity

Using decK, create a [Vault entity](/gateway/entities/vault/) with the required parameters for AWS:

{% entity_examples %}
entities:
  vaults:
    - name: aws
      prefix: aws-vault
      description: Storing secrets in AWS Secrets Manager
      config:
        region: us-east-1
{% endentity_examples %}

## Validate

To validate that the secret was stored correctly in AWS you can use the `kong vault get` command within the Data Plane container. 

{% validation vault-secret %}
secret: '{vault://aws-vault/my-aws-secret/token}'
value: 'secret'
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. Then, you can use `{vault://aws-vault/my-aws-secret/token}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret). 