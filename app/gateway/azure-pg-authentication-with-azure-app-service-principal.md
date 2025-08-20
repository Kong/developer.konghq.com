---
title: "{{site.base_gateway}} Connect to Azure Postgres Server using Azure Service Principal"
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

description: "Learn how to use Azure Service Principal authentication to connect to the Azure Postgres Server that you use for {{site.base_gateway}}"

related_resources:
  - text: "Install {{site.base_gateway}}"
    url: /gateway/install/

works_on:
  - on-prem
---

Microsoft Entra authentication (formerly Azure AD) provides a secure way to connect {{site.base_gateway}} to your Azure PostgreSQL database without storing database passwords in configuration files. This feature supports both Service Principal and Managed Identity authentication methods. This documentation provides an example about how to use Azure App and its Service Principal with its client credential to authenticate and connect to Azure Postgres Server.

## Prerequisites

Before configuring Azure authentication in {{site.base_gateway}}, there are several things you need to prepare:

- **Azure PostgreSQL Flexible Server** with Microsoft Entra authentication enabled. To enable Microsoft Entra authentication, open your Azure Database for PostgreSQL flexible server instance, and navigate to **Security** -> **Authentication**, and choose **PostgreSQL and Microsoft Entra authentication** in the **Authentication Method**. Click the **Save** button to let it take effect.
- **Microsoft Entra identities**: To connect Azure PostgreSQL database you'll need a Microsoft Entra identity. In this documentation we will use an Active Directory application as an example. Open Azure portal and go to **Microsoft Entra ID** service, and go to **Manage** -> **App registrations** -> **Owned Application** and click **New Registration** to add a new application. Assume the application's name is `my-application`. After creating the application successfully, click on the application in the **Owned Application** list and go to the detail page, then go to **Manage** -> **Certificates and secrets** -> **Client secrets**, click the **New client secret** button to add a new client secret.
Copy the secret value `my-secret-value` and we'll use it as client secret in {{site.base_gateway}}'s configuration later. Also copy the **Application (client) ID** (assume the value is `UUID-APPLICATION-ID`) and **Directory (tenant) ID**(assume the value is `UUID-TENANT-ID`) in the application's detail page.
- **Create corresponding Azure PostgreSQL user(role)**: You can choose to create an administrator user(role) for the application or a normal user(role) for the application.
  - If you want to create an administrator user(role) for the application, go to the Azure Postgres Server page, go to **Security** -> **Authentication** -> **Microsoft Entra administrators** and click the link **Add Microsoft Entra administrators**. Search for the application name `my-application` in **Enterprise applications** and click **Select** to add it into the administrator list. You'll see the application's service principal showed up in the list with a type "Service principal". Click **Save** button to let it take effect on the Azure Postgres Server. Azure will create the corresponding Postgres user(role) for you automatically inside the Postgres server.
  - If you want to create a normal user(role) for the application, you'll need to connect to the Azure PostgreSQL server as Microsoft Entra administrator. You can refer to the [Azure documentation](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-configure-sign-in-azure-ad-authentication#authenticate-with-microsoft-entra-id) to learn how to connect to the Azure PostgreSQL server as Microsoft Entra administrator. After successfully login to the Azure PostgreSQL server, connect to the database `postgres` and run the following SQL command:

```
postgres=> \c postgres
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
You are now connected to database "postgres" as user "XXXXX".

## Note: this is not needed if you have already created an administrator user(role)
postgres=> select * from pg_catalog.pgaadauth_create_principal('my-application', false, false);
            pgaadauth_create_principal
--------------------------------------------------
 Created role for "my-application"
(1 row)

## You can check if the role was created successfully
postgres=> select * from pg_catalog.pgaadauth_list_principals(false);
            rolname            | principaltype |               objectid               |               tenantid               | ismfa | isadmin
-------------------------------+---------------+--------------------------------------+--------------------------------------+-------+---------
 my-application               | service       |                 XXX                  |                  XXXXXX              |     0 |       0
```

You'll also need to prepare the correct Kong database for the Azure Postgres User. For example the following command creates a `kong` database and assign permissions on schema public to the service principal:

```SQL
postgres=> create database kong owner "my-application" encoding 'utf-8';
CREATE DATABASE
postgres=> \c kong
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
You are now connected to database "kong" as user "XXXXX".
kong=> grant all on schema public to "my-application";
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
export KONG_PG_USER=my-application

export KONG_PG_AZURE_AUTH=on
export KONG_PG_AZURE_CLIENT_ID=UUID-APPLICATION-ID
export KONG_PG_AZURE_TENANT_ID=UUID-TENANT-ID
export KONG_PG_AZURE_CLIENT_SECRET=my-secret-value
```

### Read-Only Database Connection (Optional)

If you use a separate read-only database connection:

```bash
# Read-only database configuration
export KONG_PG_RO_HOST=your-ro-server.postgres.database.azure.com
export KONG_PG_RO_PORT=5432
export KONG_PG_RO_DATABASE=kong
export KONG_PG_RO_USER=my-application

export KONG_PG_RO_AZURE_AUTH=on
export KONG_PG_RO_AZURE_CLIENT_ID=UUID-APPLICATION-ID
export KONG_PG_RO_AZURE_TENANT_ID=UUID-TENANT-ID
export KONG_PG_RO_AZURE_CLIENT_SECRET=my-secret-value
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
pg_user = my-application

pg_azure_auth = on
pg_azure_client_id = UUID-APPLICATION-ID
pg_azure_tenant_id = UUID-TENANT-ID
pg_azure_client_secret = my-secret-value
```

### Read-Only Connection (Config File)

```bash
# Read-only database configuration
pg_ro_host = your-ro-server.postgres.database.azure.com
pg_ro_port = 5432
pg_ro_database = kong
pg_ro_user = my-application

pg_ro_azure_auth = on
pg_ro_azure_client_id = UUID-APPLICATION-ID
pg_ro_azure_tenant_id = UUID-TENANT-ID
pg_ro_azure_client_secret = my-secret-value
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

