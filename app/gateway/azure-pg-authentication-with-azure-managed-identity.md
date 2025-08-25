---
title: "{{site.base_gateway}} Connect to Azure Postgres Server using Azure Managed Identity"
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/
products:
    - gateway

tags:
  - azure

min_version:
    gateway: '3.12'

description: "Learn how to use Azure Managed Identity authentication to connect to the Azure Postgres Server that you use for {{site.base_gateway}}"

related_resources:
  - text: "Install {{site.base_gateway}}"
    url: /gateway/install/

works_on:
  - on-prem
---

Microsoft Entra authentication (formerly Azure AD) provides a secure way to connect {{site.base_gateway}} to your Azure PostgreSQL database without storing database passwords in configuration files. This feature supports both Service Principal and Managed Identity authentication methods. This documentation provides an example about how to use Azure Managed Identity authentication to connect to Azure Postgres Server.

## Prerequisites

Before configuring Azure authentication in {{site.base_gateway}}, there are several things you need to prepare:

- **Azure PostgreSQL Flexible Server** with Microsoft Entra authentication enabled. To enable Microsoft Entra authentication, open your Azure Database for PostgreSQL flexible server instance, and navigate to **Security** -> **Authentication**, and choose **PostgreSQL and Microsoft Entra authentication** in the **Authentication Method**. Click the **Save** button to let it take effect.
- **Managed Identity** and an Azure resource that used this Managed Identity for authentication. In this document we'll use Azure VM and a user-assigned managed identity as an example. Go to **Managed Identities** page in Azure portal and create a Managed Identity, assume the name of the Managed Identity is `my-managed-identity`. After creating the Managed Identity, open the Azure VM page and go to **Security** -> **Identity** -> **User assigned** and click **Add** button to assign the `my-managed-identity` to your VM. You can also use Cloudshell to execute commands like `az vm identity assign -g <YOUR_RESOURCE_GROUP_NAME> -n <YOUR_VM_NAME> --identities my-managed-identity` to assign `my-managed-identity` to your VM. After that, copy the **Client ID** of this managed identity `my-managed-identity` and we'll use it as the Client ID for Azure authentication in {{site.base_gateway}} later, assume the ID is `00000000-0000-0000-0000-000000000001`. You can find the **Client ID** on the Managed Identity's detail page in the Azure Portal.
- **Azure Postgres User**: you'll need to create an Azure Database for PostgreSQL flexible server user for your Managed Identity. To create a PostgreSQL user for your managed identity, you'll need to connect to the Azure PostgreSQL server as Microsoft Entra administrator. You can refer to the [Azure documentation](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-configure-sign-in-azure-ad-authentication#authenticate-with-microsoft-entra-id) to learn how to connect to the Azure PostgreSQL server as Microsoft Entra administrator. After successfully login to the Azure PostgreSQL server, run the following SQL command:

```SQL
postgres=> select * from pgaadauth_create_principal('my-managed-identity', false, false);

           pgaadauth_create_principal
------------------------------------------------
 Created role for "my-managed-identity"
(1 row)
```

You'll also need to prepare the correct Kong database for the Azure Postgres User. For example the following command creates a `kong` database and assign permissions on schema public to the managed identity:

```SQL
postgres=> create database kong owner 'my-managed-identity' encoding 'utf-8';
CREATE DATABASE
postgres=> \c kong
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
You are now connected to database "kong" as user "XXXXX".
kong=> grant all on schema public to "my-managed-identity";
GRANT
```

## Configuring Azure authentication in {{site.base_gateway}}

{% navtabs "Configuration" %}

{% navtab "Environment variables" %}

### Environment Variables


```bash
# Basic database configuration
export KONG_DATABASE=postgres
export KONG_PG_HOST=your-server.postgres.database.azure.com
export KONG_PG_PORT=5432
export KONG_PG_DATABASE=kong
export KONG_PG_USER=my-managed-identity # needs to be the name of the managed identity

export KONG_PG_AZURE_AUTH=on
export KONG_PG_AZURE_CLIENT_ID=00000000-0000-0000-0000-000000000001 # the Client ID of the user assigned managed identity
```

### Read-Only Database Connection (Optional)

If you use a separate read-only database connection:

```bash
# Read-only database configuration
export KONG_PG_RO_HOST=your-ro-server.postgres.database.azure.com
export KONG_PG_RO_PORT=5432
export KONG_PG_RO_DATABASE=kong
export KONG_PG_RO_USER=my-managed-identity # needs to be the name of the managed identity

export KONG_PG_RO_AZURE_AUTH=on
export KONG_PG_RO_AZURE_CLIENT_ID=00000000-0000-0000-0000-000000000001 # the Client ID of the user assigned managed identity
```

{% endnavtab %}

{% navtab "Configuration file" %}

### Configuration File

```bash
# Basic database configuration
database = postgres
pg_host = your-server.postgres.database.azure.com
pg_port = 5432
pg_database = kong
pg_user = my-managed-identity # needs to be the name of the managed identity

pg_azure_auth = on
pg_azure_client_id = 00000000-0000-0000-0000-000000000001 # the Client ID of the user assigned managed identity
```

### Read-Only Connection (Config File)

```bash
# Read-only database configuration
pg_ro_host = your-ro-server.postgres.database.azure.com
pg_ro_port = 5432
pg_ro_database = kong
pg_ro_user = my-managed-identity # needs to be the name of the managed identity

pg_ro_azure_auth = on
pg_ro_azure_client_id = 00000000-0000-0000-0000-000000000001 # the Client ID of the user assigned managed identity
```

{% endnavtab %}

{% endnavtabs %}

## Configuration Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `pg_azure_auth` | Enable Azure authentication | No | `off` |
| `pg_azure_tenant_id` | Azure tenant ID  | Conditional | - |
| `pg_azure_client_id` | Azure client ID | Conditional | - |
| `pg_azure_client_secret` | Azure client secret | Conditional | - |
| `pg_ro_azure_auth` | Enable Azure authentication for Read only connection | No | `off` |
| `pg_ro_azure_tenant_id` | Azure tenant ID for Read only connection  | Conditional | - |
| `pg_ro_azure_client_id` | Azure client ID for Read only connection | Conditional | - |
| `pg_ro_azure_client_secret` | Azure client secret for Read only connection | Conditional | - |


## Troubleshooting

### Common Issues

1. **What if the kong command fails with `failed to initialize Azure client: no authentication mechanism worked for azure`?**
   - Try run kong command with `--vv` parameter to show the debug log. You'll see the reason why the Azure authentication failed, for example the following log shows an error when authenticating with Managed Identity:
   ```
   2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] init.lua:32: auth(): could not authenticate to azure with ClientCredentials class, error: Couldn't find AZURE_CLIENT_SECRET env variable
  2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] init.lua:32: auth(): could not authenticate to azure with WorkloadIdentityCredentials class, error: Couldn't find AZURE_FEDERATED_TOKEN_FILE env variable
  2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] ManagedIdentityCredentials.lua:217: configureIMDSCredentialRequest(): use managed identity in IMDS
  2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] ManagedIdentityCredentials.lua:150: try to use managed identity client_id XXXXXXXX
  2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] http_connect.lua:253: connect(): poolname: http:169.254.169.254:80:nil::nil:::
  2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] init.lua:32: auth(): could not authenticate to azure with ManagedIdentityCredentials class, error: managed identity credentials request failed, status: 400, body: {"error":"invalid_request","error_description":"Identity not found"}
   ```
2. **Can I still use `pg_password` together with the Azure authentication?**
  - No, when `pg_azure_auth` is enabled, `pg_password` will be ignored.

