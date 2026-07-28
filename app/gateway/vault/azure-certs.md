---
title: "Azure Key Vault (Certificates)"
layout: reference
content_type: reference
description: "Use Azure Key Vault to retrieve certificates for {{site.base_gateway}} TLS termination."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/azure-certs/

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
  gateway: '3.15'

related_resources:
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
  - text: "Supported {{site.base_gateway}} Vault backends"
    url: /gateway/entities/vault/#supported-vault-backends
  - text: Azure Key Vault secrets
    url: /gateway/entities/vault/azure/
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Azure Key Vault Certificates documentation
    url: https://learn.microsoft.com/en-us/azure/key-vault/certificates/
---

{{site.base_gateway}} can retrieve [Azure Key Vault for Certificates](https://learn.microsoft.com/en-us/azure/key-vault/certificates/) for {{site.base_gateway}} TLS termination.

You can set up an Azure Key Vault for Certificates vault in one of the following ways:

{% include_cached /gateway/vault-provider-intro.md %}

## Azure Key Vault authentication

{{site.base_gateway}} uses a key to automatically authenticate
with the [Azure Key Vaults API](https://learn.microsoft.com/en-us/rest/api/keyvault/) and grant you access.
If you're using a client secret for authentication, set the following environment variable on your data plane to connect with an Azure Key Vault:

```bash
export AZURE_CLIENT_SECRET='YOUR_CLIENT_SECRET'
```
By default, the vault looks for `AZURE_CLIENT_SECRET`, but you can customize this with the `credentials_prefix` field.

If you're using an Instance Managed Identity Token, you don't need to set the client secret env variable.

{% include_cached /gateway/azure-vault-dcgw-unsupported.md %}

You also need to set `KONG_LUA_SSL_VERIFY_DEPTH` to at least `3` on your data plane to allow Kong to verify the Azure Key Vault TLS certificate chain:

```bash
export KONG_LUA_SSL_VERIFY_DEPTH=3
```

At minimum, you'll also need to set the following values on your data plane:

```sh
export KONG_VAULT_AZURE_CERTS_VAULT_URI='https://your-vault.vault.azure.com'
export KONG_VAULT_AZURE_CERTS_TENANT_ID='YOUR_TENANT_ID'
export KONG_VAULT_AZURE_CERTS_CLIENT_ID='YOUR_CLIENT_ID'
```

## Create an Azure Key Vault (Certificates) vault

The following example creates an `azure-certs` Vault entity.
The Vault name **must** be `azure-certs`. The `vault.prefix` value can be your own custom prefix:

<!--vale off-->
{% entity_example %}
type: vault
data:
  name: azure-certs
  prefix: azure-certs-vault
  description: Retrieving certificates from Azure Key Vault
  config:
    vault_uri: https://azure.example.com
    tenant_id: example-azure-tenant-id
    client_id: example-azure-client-id
{% endentity_example %}
<!--vale on-->

## Vault configuration options

The following table lists all of the available configuration parameters for an Azure Key Vault (Certificates) vault:

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
  - field: |
      Vault URI <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.vault_uri`
      * **kong.conf parameter:** `vault_azure_certs_vault_uri`
      * **Environment variable:** `KONG_VAULT_AZURE_CERTS_VAULT_URI`
    description: |
      The URI the vault is reachable from.
  - field: |
      Credentials prefix <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.credentials_prefix`
    description: |
      The prefix for environment variables used for authentication. The vault reads `{prefix}_CLIENT_SECRET` from the environment. Defaults to `AZURE`.
      This can only be set using the Vault entity.
  - field: |
      Client ID <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.client_id`
      * **kong.conf parameter:** `vault_azure_certs_client_id`
      * **Environment variable:** `KONG_VAULT_AZURE_CERTS_CLIENT_ID`
    description: |
      The client ID from your registered Application. Visit your Azure Dashboard and select **App Registrations** to check your client ID.
  - field: |
      Tenant ID <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.tenant_id`
      * **kong.conf parameter:** `vault_azure_certs_tenant_id`
      * **Environment variable:** `KONG_VAULT_AZURE_CERTS_TENANT_ID`
    description: |
      The `DirectoryId` and `TenantId` are the same: both refer to the GUID representing your Azure Entra tenant.
      Depending on context, either term may be used by Microsoft documentation and products.
      In other words, the "Tenant ID" IS the "Directory ID".
  - field: |
      TTL <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_azure_certs_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_CERTS_TTL`
    description: |
      Time-to-live (in seconds) of a certificate from the Azure Key Vault when cached by this node.

      Defaults to 3600 (1 hour).
  - field: |
      Negative TTL <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_azure_certs_neg_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_CERTS_NEG_TTL`
    description: |
      Time-to-live (in seconds) of an Azure Key Vault miss (no certificate).
  - field: |
      Resurrect TTL <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_azure_certs_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_CERTS_RESURRECT_TTL`
    description: |
      Time (in seconds) for which stale certificates from the Azure Key Vault should be resurrected
      when they can't be refreshed (for example, if the vault is unreachable).
      When this TTL expires, a new attempt to refresh the stale certificates will be made.
{% endtable %}
<!--vale on-->
