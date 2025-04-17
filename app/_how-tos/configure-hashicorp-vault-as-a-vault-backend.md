---
title: Configure HashiCorp Vault as a vault backend
content_type: how_to
related_resources:
  - text: Rotate secrets in HashiCorp Vault with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-hashicorp-vault/
  - text: Secrets management
    url: /gateway/secrets-management/

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

tldr:
    q: How can I access HashiCorp Vaults secrets in {{site.base_gateway}}? 
    a: |
      [Install and run HashiCorp Vault](https://developer.hashicorp.com/vault/tutorials/get-started/install-binary#install-vault) in dev mode or self-managed. [Write a secret to the Vault](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv?variants=vault-deploy%3Aselfhosted#write-secrets) like `vault kv put secret/customer/acme name="ACME Inc."`. Save your HashiCorp Vault token, host, port, protocol, and KV secrets engine version and use them to configure a {{site.base_gateway}} [Vault entity](/gateway/entities/vault/). Use `{vault://hashicorp-vault/customer/acme/name}` to reference the secret in any referenceable field.

tools:
    - deck

prereqs:
  inline: 
    - title: HashiCorp Vault
      include_content: prereqs/hashicorp
      icon_url: /assets/icons/hashicorp.svg

cleanup:
  inline:
    - title: Clean up HashiCorp Vault
      include_content: cleanup/third-party/hashicorp
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: How do I rotate my secrets in HashiCorp Vault and how does {{site.base_gateway}} pick up the new secret values?
    a: You can rotate your secret in HashiCorp Vault by creating a new secret version with the updated value. You'll also want to configure the `ttl` settings in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} pulls the rotated secret periodically.

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---

## 1. Create a secret in HashiCorp Vault

Write a secret to HashiCorp Vault:
```
vault kv put secret/customer/acme name="ACME Inc."
```

## 2. Create decK environment variables 

We'll use decK environment variables for the `host` and `token` in the {{site.base_gateway}} Vault configuration. This is because these values typically can vary between environments. 

In this tutorial, we're using `host.docker.internal` as our host instead of the `localhost` that HashiCorp Vault is using because {{site.base_gateway}} is running in a container that has a different `localhost` to you.

As stated in the prerequisites, we're using `root` for our `token` in this tutorial since we are running HashiCorp Vault in dev mode.

```
export DECK_HCV_HOST=host.docker.internal
export DECK_HCV_TOKEN='root'
```


## 3. Create a Vault entity for HashiCorp Vault 

Using decK, create a Vault entity in the `kong.yaml` file with the required parameters for HashiCorp Vault:

{% entity_examples %}
entities:
  vaults:
    - name: hcv
      prefix: hashicorp-vault
      description: Storing secrets in HashiCorp Vault
      config:
        host: ${hcv_host}
        token: ${hcv_token}
        kv: v2
        mount: secret
        port: 8200
        protocol: http

variables:
  hcv_host:
    value: $HCV_HOST
  hcv_token:
    value: $HCV_TOKEN
{% endentity_examples %}

## 4. Validate

Since {{site.konnect_short_name}} data plane container names can vary, set your container name as an environment variable:
{: data-deployment-topology="konnect" }
```sh
export KONNECT_DP_CONTAINER='your-dp-container-name'
```
{: data-deployment-topology="konnect" }

To validate that the secret was stored correctly in HashiCorp Vault, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. 

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/customer/acme/name}'
value: 'ACME Inc.'
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://hashicorp-vault/customer/acme/name}` to reference the secret in any referenceable field.