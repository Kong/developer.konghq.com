---
title: "Azure Key Vault"
layout: reference
content_type: reference
description: "Use Azure Key Vault to store and reference secrets in {{site.base_gateway}}."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/azure/

works_on:
  - on-prem
  - konnect

products:
  - gateway

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - secrets-management
  - azure

min_version:
  gateway: '3.5'

related_resources:
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
  - text: "Supported {{site.base_gateway}} Vault backends"
    url: /gateway/entities/vault/#supported-vault-backends
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Azure Key Vault documentation
    url: https://learn.microsoft.com/azure/key-vault/
---

You can set up an [Azure Key Vault](https://learn.microsoft.com/azure/key-vault/) vault in one of the following ways:
* Using the [Vault entity](/gateway/entities/vault/)
* Using [environment variables](/gateway/manage-kong-conf/#environment-variables), set at {{site.base_gateway}} startup
* Using parameters in [`kong.conf`](/gateway/configuration/), set at {{site.base_gateway}} startup

The Vault entity can only be used once the database is initialized.
Secrets for values that are used before the database is initialized can't make use of the Vaults entity.

## Azure Key Vault authentication

{{site.base_gateway}} uses a key to automatically authenticate
with the [Azure Key Vaults API](https://learn.microsoft.com/en-us/rest/api/keyvault/) and grant you access.
If you're using a client secret for authentication, set the following environment variable on your data plane to connect with an Azure Key Vault:

```bash
export AZURE_CLIENT_SECRET=YOUR_CLIENT_SECRET
```
If you're using an Instance Managed Identity Token, you don't need to set the client secret env variable.

{% include_cached /gateway/azure-vault-dcgw-unsupported.md %}

At minimum, you'll also need to set the following values on your data plane.

```sh
export KONG_VAULT_AZURE_VAULT_URI=https://your-vault.vault.azure.com
export KONG_VAULT_AZURE_TENANT_ID=YOUR_TENANT_ID
export KONG_VAULT_AZURE_CLIENT_ID=YOUR_CLIENT_ID
```

## Create an Azure Key Vault

The following example creates an `azure` Vault entity in the Azure region `eastus2`.
The Vault name **must** be `azure`. The `vault.prefix` value can be your own custom prefix:

{% entity_example %}
type: vault
data:
  name: azure
  prefix: azure-vault
  description: Storing secrets in Azure Key Vaults
  config:
    type: secrets
    vault_uri: https://azure.example.com
    location: eastus2
    tenant_id: example-tenant
    client_id: example-client
{% endentity_example %}

## Vault configuration options

The following table lists all of the available configuration parameters for an Azure Key Vault:

<!--vale off-->
{% table %}
columns:
  - title: Field name
    key: field
  - title: Parameter format
    key: parameter
  - title: Description
    key: description
rows:
  - field: Vault URI
    parameter: |
      * **Vault entity:** `vaults.config.vault_uri`
      * **kong.conf parameter:** `vault_azure_vault_uri`
      * **Environment variable:** `KONG_VAULT_AZURE_VAULT_URI`
    description: |
      The URI from which the vault is reachable. This value can be found in your Azure Key Vault Dashboard under the Vault URI entry.
  - field: Client ID
    parameter: |
      * **Vault entity:** `vaults.config.client_id`
      * **kong.conf parameter:** `vault_azure_client_id`
      * **Environment variable:** `KONG_VAULT_AZURE_CLIENT_ID`
    description: |
      The client ID for your registered application. You can find this in the Azure Dashboard under App Registrations.
  - field: Tenant ID
    parameter: |
      * **Vault entity:** `vaults.config.tenant_id`
      * **kong.conf parameter:** `vault_azure_tenant_id`
      * **Environment variable:** `KONG_VAULT_AZURE_TENANT_ID`
    description: |
      The `DirectoryId` and `TenantId` are the same: both refer to the GUID representing your Azure Active Directory tenant. Microsoft documentation and products may use either term depending on context.
  - field: Location
    parameter: |
      * **Vault entity:** `vaults.config.location`
      * **kong.conf parameter:** `vault_azure_location`
      * **Environment variable:** `KONG_VAULT_AZURE_LOCATION`
    description: |
      Each Azure geography includes one or more regions that meet specific data residency and compliance requirements.
  - field: Type
    parameter: |
      * **Vault entity:** `vaults.config.type`
      * **kong.conf parameter:** `vault_azure_type`
      * **Environment variable:** `KONG_VAULT_AZURE_TYPE`
    description: |
      Azure Key Vault supports different data types such as keys, secrets, and certificates. Kong currently supports only `secrets`.
  - field: TTL
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_azure_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_TTL`
    description: |
      Time-to-live (in seconds) for a cached secret. A value of 0 (default) means no rotation. For non-zero values, it is recommended to use intervals of at least 60 seconds.
  - field: Negative TTL
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_azure_neg_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_NEG_TTL`
    description: |
      Time-to-live (in seconds) for caching failed secret lookups. A value of 0 (default) disables negative caching. After `neg_ttl` expires, Kong retries fetching the secret.
  - field: Resurrect TTL
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_azure_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_RESURRECT_TTL`
    description: |
      Duration (in seconds) that secrets remain usable after expiration (`config.ttl` limit). Useful when the vault is unreachable or a secret is deleted. Kong retries refreshing the secret for this duration. Afterward, it stops. The default is 1e8 seconds (~3 years) to ensure resiliency during issues.
  - field: |
      Base64 Decode <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.base64_decode`
      * **kong.conf parameter:** `vault_azure_decode_base64`
      * **Environment variable:** `KONG_VAULT_AZURE_DECODE_BASE64`
    description: |
      Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
  - field: |
      Credentials prefix
    parameter: |
      * **Vault entity:** `vaults.config.credentials_prefix`
    description: |
      The prefix for environment variables used for authentication. The vault reads `{prefix}_CLIENT_SECRET` from the environment. Defaults to `AZURE`.
      This can only be set using the Vault entity.
{% endtable %}
<!--vale on-->

