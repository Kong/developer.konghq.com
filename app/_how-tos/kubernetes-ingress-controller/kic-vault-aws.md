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
  cloud:
    aws:
      secret: true

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
  - text: What can be stored as a secret?
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret    

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

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret). 