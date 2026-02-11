---
title: Configure Azure Key Vaults as a vault backend
content_type: how_to
permalink: /how-to/configure-azure-key-vaults-as-a-vault-backend-with-vault-entity/
related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Azure Vault configuration parameters
    url: "/gateway/entities/vault/?tab=azure#vault-provider-specific-configuration-parameters"
  - text: Azure Key Vault documentation
    url: https://learn.microsoft.com/azure/key-vault/
description: Learn how to set up Azure Key Vaults as a Vault in {{site.base_gateway}} and reference a secret stored there.
products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.5'

entities: 
  - vault

tags:
  - security
  - secrets-management
  - azure
search_aliases:
  - key vault
  - Azure

tldr:
    q: How can I access Azure Key Vaults secrets in {{site.base_gateway}}?
    a: |
      Set the `AZURE_CLIENT_SECRET` environment variable, then start {{site.base_gateway}} with this environment variable. Create a Vault entity and add the required Azure parameters: `vault_uri`, `location`, `tenant_id`, and `client_id`.

tools:
    - deck

faqs:
  - q: What type of Azure Key Vaults objects can I reference?
    a: You can only reference secrets. Azure Key Vaults keys and certificates are not supported.
  - q: |
      {% include /gateway/vaults-format-faq.md type='question' %}
    a: |
      {% include /gateway/vaults-format-faq.md type='answer' %}
prereqs:
  gateway:
    - name: AZURE_CLIENT_SECRET
  konnect:
    - name: AZURE_CLIENT_SECRET
  cloud:
    azure:
      secret: true
  inline: 
    - title: Environment variables
      content: |
          Set the environment variables needed to authenticate to Azure:
          ```sh
          export DECK_AZURE_TENANT_ID=your-azure-tenant-id
          export DECK_AZURE_CLIENT_ID=your-azure-application-id
          export DECK_AZURE_VAULT_URI="https://my-example-vault.vault.azure.net/"
          export DECK_AZURE_LOCATION="eastus"
          ```
      icon_url: /assets/icons/file.svg
cleanup:
  inline:
    - title: Clean up Azure
      include_content: cleanup/cloud/azure
      icon_url: /assets/icons/azure.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg 

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/

published: false
# Fails to authenticate with Azure
---

## Configure the Vault entity

Using decK, create a [Vault entity](/gateway/entities/vault/) with the required parameters for Azure:

{% entity_examples %}
entities:
  vaults:
    - name: azure
      prefix: azure-vault
      description: Storing secrets in Azure Key Vaults
      config:
        type: secrets
        vault_uri: ${vault_uri}
        location: ${location}
        tenant_id: ${tenant_id}
        client_id: ${client_id}

variables:
  vault_uri:
    value: $AZURE_VAULT_URI
  location:
    value: $AZURE_LOCATION
  tenant_id:
    value: $AZURE_TENANT_ID
  client_id:
    value: $AZURE_CLIENT_ID
{% endentity_examples %}

## Validate

To validate that the secret was stored correctly in Azure, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. 

{% validation vault-secret %}
secret: '{vault://azure-vault/token}'
value: 'secret'
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://azure-vault/token}` to reference the secret in any referenceable field.