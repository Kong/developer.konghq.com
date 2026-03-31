---
title: Configure HashiCorp Vault as a vault backend with Azure managed identity authentication
permalink: /how-to/configure-hashicorp-vault-with-azure-auth/
content_type: how_to
description: "Learn how to configure HashiCorp Vault with Azure managed identity authentication and reference HashiCorp Vault secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Configure HashiCorp Vault as a vault backend with GCP service account authentication
    url: /how-to/configure-hashicorp-vault-with-gcp-service-account-auth/
  - text: Configure HashiCorp Vault as a vault backend with GCP workload identity
    url: /how-to/configure-hashicorp-vault-with-gcp-workload-identity/
  - text: Configure HashiCorp Vault as a vault backend with AWS IAM authentication
    url: /how-to/configure-hashicorp-vault-with-aws-iam-auth/
  - text: Configure HashiCorp Vault as a vault backend with AWS EC2 authentication
    url: /how-to/configure-hashicorp-vault-with-aws-ec2-auth/
  - text: Store Keyring data in a HashiCorp Vault
    url: /how-to/store-keyring-in-hashicorp-vault/
  - text: HashiCorp Azure auth method reference
    url: https://developer.hashicorp.com/vault/docs/auth/azure

works_on:
    - on-prem

min_version:
  gateway: '3.14'

entities:
  - vault

tags:
    - secrets-management
    - security
    - hashicorp-vault
    - azure

search_aliases:
  - Hashicorp Vault
  - Azure
  - azure
  - managed identity

tldr:
    q: How do I configure HashiCorp Vault to authenticate using Azure managed identity?
    a: |
      Run {{site.base_gateway}} on an Azure VM with a managed identity enabled. Enable the Azure auth method in HashiCorp Vault, configure it with your Azure AD app registration credentials, and create a role bound to your subscription and resource group.

      Then in {{site.base_gateway}}:
      * Configure a Vault entity with `config.auth_method` set to `azure`.
      * Set `config.azure_auth_role` to the Vault role name. The Azure managed identity token is provided automatically by the Azure Instance Metadata Service — no credential files are required on the {{site.base_gateway}} side.

tools:
    - admin-api

prereqs:
  skip_product: true
  inline:
    - title: Azure AD app registration for the Vault server
      content: |
        HashiCorp Vault must call Azure APIs to verify incoming managed identity tokens. You need an Azure AD app registration that Vault will use as the resource for generating MSI access tokens, with a client secret for authentication.

        1. [Register an application in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app). This is the app registration Vault will use to call Azure APIs.

        1. [Create a client secret](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal#option-3-create-a-new-application-secret) for the app registration.

        1. Note the following values and export them as environment variables:
           ```sh
           export VAULT_AZURE_TENANT_ID="YOUR-TENANT-ID"
           export VAULT_AZURE_CLIENT_ID="YOUR-CLIENT-ID"
           export VAULT_AZURE_CLIENT_SECRET="YOUR-CLIENT-SECRET"
           ```
           You can find the tenant ID and client ID in the Azure portal under your app registration's **Overview** tab. The client secret value is only shown at creation time.

        1. [Grant the app registration the following role assignment](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal) so Vault can verify VM identity during authentication. In the [Azure portal](https://portal.azure.com/), go to your subscription or resource group, select **Access control (IAM)**, select the app you created as a member, and assign the **Reader** role to your app registration's service principal:
           * `Microsoft.Compute/virtualMachines/*/read`

      icon_url: /assets/icons/azure.svg
    - title: Azure VM with managed identity
      content: |
        To complete this tutorial, {{site.base_gateway}} must be running on an Azure VM with a system-assigned managed identity enabled. The managed identity token is automatically provided by the [Azure Instance Metadata Service](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token), so no credential files are required on the {{site.base_gateway}} side.

        1. [Create an Azure VM with a system-assigned managed identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-configure-managed-identities) enabled. 
           When creating the VM, go to **Management** > **Identity** and select the **Enable system-assigned managed identity** checkbox.

        1. Copy the following values for your VM and export them as environment variables:
           ```sh
           export AZURE_SUBSCRIPTION_ID="YOUR-SUBSCRIPTION-ID"
           export AZURE_RESOURCE_GROUP="YOUR-RESOURCE-GROUP"
           export AZURE_VM_NAME="YOUR-VM-NAME"
           ```
           You can find these values in the Azure portal in your VM's **Overview** tab.

        1. Copy the service principal ID of your VM's managed identity and export it:
           ```sh
           export AZURE_SERVICE_PRINCIPAL_ID="YOUR-SERVICE-PRINCIPAL-ID"
           ```
           You can find this in the Azure portal in your VM's **Security > Identity** tab, under **System assigned > Object (principal) ID**.

        If {{site.base_gateway}} isn't running on an Azure VM, this auth method won't work. The Azure Instance Metadata Service is only available from within Azure infrastructure.

      icon_url: /assets/icons/azure.svg
    - title: HashiCorp Vault
      content: |
        You need [HashiCorp Vault installed](https://developer.hashicorp.com/vault/install) on your VM. 

        The steps in this how to assume that HashiCorp Vault and {{site.base_gateway}} are installed on the same VM. 
        Production instances will often install HashiCorp Vault and {{site.base_gateway}} on separate VMS. 
        If this is the case, see the [HashiCorp Vault Azure authentication documentation](https://developer.hashicorp.com/vault/docs/auth/azure) for the configuration changes you'll need to make.
      icon_url: /assets/icons/hashicorp.svg

cleanup:
  inline:
    - title: Clean up HashiCorp Vault
      content: |
        Stop the HashiCorp Vault process by running the following:
        ```sh
        pkill vault
        ```

        Unset environment variables:
        ```sh
        unset VAULT_ADDR
        unset VAULT_AZURE_TENANT_ID
        unset VAULT_AZURE_CLIENT_ID
        unset VAULT_AZURE_CLIENT_SECRET
        ```
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: Can I use a user-assigned managed identity instead of a system-assigned managed identity?
    a: |
      Yes. Azure supports both system-assigned and user-assigned managed identities. For environments with high ephemeral workloads where VMs are frequently recreated, HashiCorp recommends user-assigned identities to avoid accumulating Vault entities. See [Azure managed identities](https://developer.hashicorp.com/vault/docs/auth/azure#azure-managed-identities) in the HashiCorp Vault documentation for more information.
  - q: How do I rotate my secrets in HashiCorp Vault and how does {{site.base_gateway}} pick up the new secret values?
    a: You can rotate your secret in HashiCorp Vault by creating a new secret version with the updated value. You'll also want to configure the `ttl` settings in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} pulls the rotated secret periodically.
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

## Configure HashiCorp Vault

Before you can configure the Vault entity in {{site.base_gateway}}, you must configure HashiCorp Vault to authenticate clients using Azure managed identity tokens and store a secret.

### Create configuration files

{% include /gateway/hashicorp-vault-create-policies.md %}

### Configure the Vault and store a secret

{% include /gateway/hashicorp-vault-basic-setup.md %}

1. Enable Azure authentication:
   ```sh
   vault auth enable azure
   ```

1. Configure the Azure auth method with the Vault server's Azure AD app registration credentials:
   ```sh
   vault write auth/azure/config \
     tenant_id=$VAULT_AZURE_TENANT_ID \
     resource=https://management.azure.com/ \
     client_id=$VAULT_AZURE_CLIENT_ID \
     client_secret=$VAULT_AZURE_CLIENT_SECRET
   ```

1. Create an Azure role that binds to {{site.base_gateway}}'s subscription, resource group, and service principal:
   ```sh
   vault write auth/azure/role/kong-role \
     policies="rw-secrets" \
     bound_subscription_ids=$AZURE_SUBSCRIPTION_ID \
     bound_resource_groups=$AZURE_RESOURCE_GROUP \
     bound_service_principal_ids=$AZURE_SERVICE_PRINCIPAL_ID
   ```

1. Enable the K/V secrets engine:
   ```sh
   vault secrets enable -path=kong kv
   ```

1. Create a secret:
   ```sh
   vault kv put kong/headers/request header="x-kong:test"
   ```

1. Confirm you can retrieve the secret through Vault:
   ```sh
   vault kv get kong/headers/request
   ```

## Set environment variables

Find the internal IP for your VM:
```sh
hostname -I
```

Export the following environment variables before creating the Vault entity:

```sh
export HCV_HOST="YOUR VM INTERNAL IP"
export AZURE_AUTH_ROLE=kong-role
```

## Create a Vault entity for HashiCorp Vault

Create a [Vault entity](/gateway/entities/vault/) with the required parameters for HashiCorp Vault Azure managed identity authentication:
{% control_plane_request %}
url: /vaults
method: POST
body:
  name: hcv
  prefix: hashicorp-vault
  description: Storing secrets in HashiCorp Vault
  config:
    host: $HCV_HOST
    kv: v1
    mount: kong
    port: 8200
    protocol: http
    auth_method: azure
    azure_auth_role: $AZURE_AUTH_ROLE
{% endcontrol_plane_request %}

## Validate

To validate that the secret was stored correctly in HashiCorp Vault, call a secret from your vault using the `kong vault get` command:

```sh
sudo -E kong vault get {vault://hashicorp-vault/headers/request/header}
```

If the vault was configured correctly, this command returns the value of the secret. You can use `{vault://hashicorp-vault/headers/request/header}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).