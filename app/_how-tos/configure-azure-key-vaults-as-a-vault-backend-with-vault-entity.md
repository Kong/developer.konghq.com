---
title: Configure Azure Key Vaults as a vault backend using the Vault entity
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management

products:
  - gateway

tier: enterprise

works_on:
  - on-prem

min_version:
  gateway: '3.5'

entities: 
  - vault

tags:
  - security
  - secrets-management

tldr:
    q: How can I access Azure Key Vaults secrets in {{site.base_gateway}}?
    a: |
      Set the `AZURE_CLIENT_SECRET` environment variable, then start {{site.base_gateway}} with this environment variable. Create a Vault entity and add the required Azure parameters: `vault_uri`, `location`, `tenant_id`, and `client_id`.

tools:
    - deck

faqs:
  - q: What type of Azure Key Vaults objects can I reference?
    a: You can only reference secrets. Azure Key Vaults keys and certificates are not supported.

prereqs:
  gateway:
    - name: AZURE_CLIENT_SECRET
  inline:
    - title: Azure resources
      position: before
      content: |
        This example requires a few Azure resources. You need an Azure subscription and permissions to create or access these resources:
        - A [registered application](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate) to use for authentication.
        - A [key vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) with at least one [secret](https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-portal). Make sure that your application has access to the key vault.

        In this example, the key vault is named `my-example-vault` and contains a secret named `token` whose value is a Bearer token.

        Once the resources are created, you'll need the following credentials to connect {{site.base_gateway}} to your Azure key vault:
        - Your application's client ID
        - Your application's client secret
        - Your Azure tenant ID
        - Your vault URI, `https://my-example-vault.vault.azure.net/` in this example
        - You Azure location, `eastus` in this example
      icon_url: /assets/icons/azure.svg
      
    - title: Environment variables
      position: before
      content: |
          Set the environment variables needed to authenticate to Azure:
          ```sh
          export AZURE_CLIENT_SECRET=your-azure-application-client-secret
          export DECK_AZURE_TENANT_ID=your-azure-tenant-id
          export DECK_AZURE_CLIENT_ID=your-azure-application-id
          export DECK_AZURE_VAULT_URI="https://my-example-vault.vault.azure.net/"
          export DECK_AZURE_LOCATION="eastus"
          ```

          Note that the `AZURE_CLIENT_SECRET` variable needs to be passed when creating your Data Plane container.
      icon_url: /assets/icons/file.svg
cleanup:
  inline:
    - title: Clean up Azure resources
      include_content: cleanup/third-party/azure
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
---

## 1. Configure the Vault entity

Using decK, create a Vault entity with the required parameters for Azure:

{% entity_example %}
type: vault
data:
  name: azure
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
{% endentity_example %}

## 2. Validate

To validate that the secret was stored correctly in Azure, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. If the Docker container is named `kong-quickstart-gateway`, you can use the following command:

```sh
docker exec kong-quickstart-gateway kong vault get {vault://azure-vault/token}
```

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://azure-vault/token}` to reference the secret in any referenceable field.