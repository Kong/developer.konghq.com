---
title: Configuring Kong to use Azure Key Vaults with Managed Identities authentication
content_type: support
description: "Set up a Managed Identity in Azure, assign it to the Kong VM or AKS instance, grant it access in Key Vault, and configure `AZURE_CLIENT_ID` and `KONG_VAULT_AZURE_VAULT_URI` so Kong can authenticate to Azure Key Vault without explicit credentials."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can Kong be configured to use Azure Key Vaults with Managed Identities authentication?
  a: |
    Create an Azure Managed Identity, assign it to the VM or AKS instance running Kong, and grant it `Secrets -> Get` access in Key Vault. Then set `AZURE_CLIENT_ID` and `KONG_VAULT_AZURE_VAULT_URI` as environment variables so Kong's Azure SDK can use the managed identity to authenticate and retrieve secrets, for example `kong vault get {vault://azure/your-secret-name}`.
---

## Overview

How to Configure Azure Key Vaults Backend with Managed Identities in Kong?

## Steps

Configuring Azure Key Vaults as a backend for secrets management in Kong using managed identities involves a series of steps to ensure secure and seamless integration. This process allows Kong to authenticate with Azure Key Vaults without the need for explicit credentials, leveraging Azure's managed identities for a more secure and manageable setup.

The core issue addressed here is the lack of documentation on configuring Kong with Azure Key Vaults using managed identities. The resolution involves setting up the environment correctly and ensuring that Kong can authenticate with Azure Key Vaults using the managed identity assigned to the Azure resource (VM or AKS).

Here are the steps to achieve this configuration:

1. Create a Managed Identity in Azure

- Navigate to the Azure portal and create a new managed identity. Note the `AZURE_CLIENT_ID` of the created identity.

2. Assign the Managed Identity to Your Azure Resource

- Assign the managed identity to the Azure VM or AKS instance where Kong is deployed.

3. Configure Access Policies in Azure Key Vault

- Go to your Azure Key Vault instance and add an access policy. Grant the managed identity `Secrets -> Get` permission.

4. Set Required Environment Variables in Kong

- Set the following environment variables in the Kong environment, replacing the placeholders with actual values:

```

AZURE_CLIENT_ID=
KONG_VAULT_AZURE_VAULT_URI=
```

5. Retrieve Secrets from Azure Key Vault in Kong

- Use the following command to retrieve a secret from Azure Key Vault:

```bash

kong vault get {vault://azure/your-secret-name}
```

During this process, you might encounter error messages related to authentication or missing environment variables. These errors often indicate a misconfiguration in the environment variables or access policies. Ensure that the `AZURE_CLIENT_ID` and `KONG_VAULT_AZURE_VAULT_URI` are correctly set and that the managed identity has the appropriate permissions in Azure Key Vault.

Additionally, it's important to note that Kong's integration with Azure Key Vaults using managed identities is designed to work with minimal configuration. The Azure SDK automatically picks up the managed identity of the machine or pod, using it to authenticate and read secrets from Azure Key Vaults. Therefore, apart from setting the `AZURE_CLIENT_ID` as a hint for the SDK, no further specific configuration should be necessary.

This setup allows for a secure and efficient way to manage secrets in Kong, leveraging Azure's managed identities and Key Vaults.
