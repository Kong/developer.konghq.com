---
title: "Connect a {{site.base_gateway}} Azure PostgreSQL Server using Azure Managed Identity"
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

description: "Learn how to use Azure Managed Identity authentication to connect to the Azure PostgreSQL Server that you use for {{site.base_gateway}}"

related_resources:
  - text: "Install {{site.base_gateway}}"
    url: /gateway/install/
  - text: "Connect a {{site.base_gateway}} Azure PostgreSQL Server using Azure Service Principal"
    url: /gateway/azure-pg-authentication-with-azure-app-service-principal/
  - text: "{{site.base_gateway}} Amazon RDS database authentication with AWS IAM"
    url: /gateway/amazon-rds-authentication-with-aws-iam/
  - text: "{{site.base_gateway}} Google Cloud Postgres database authentication with GCP IAM and Workload Identity"
    url: /gateway/gcp-postgres-authentication/

search_aliases:
  - Entra

works_on:
  - on-prem

faqs:
  - q: "How do I fix the `failed to initialize Azure client: no authentication mechanism worked for azure` error?"
    a: |
      Try running the {{site.base_gateway}} command with the `--vv` parameter to show the debug log. You'll see the reason why the Azure authentication failed. For example the following log shows an error when authenticating with Managed Identity:
      ```sh
      2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] init.lua:32: auth(): could not authenticate to azure with ClientCredentials class, error: Couldn't find AZURE_CLIENT_SECRET env variable
      2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] init.lua:32: auth(): could not authenticate to azure with WorkloadIdentityCredentials class, error: Couldn't find AZURE_FEDERATED_TOKEN_FILE env variable
      2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] ManagedIdentityCredentials.lua:217: configureIMDSCredentialRequest(): use managed identity in IMDS
      2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] ManagedIdentityCredentials.lua:150: try to use managed identity client_id XXXXXXXX
      2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] http_connect.lua:253: connect(): poolname: http:169.254.169.254:80:nil::nil:::
      2025/08/20 06:55:13 [debug] 68220#0: *2 [lua] init.lua:32: auth(): could not authenticate to azure with ManagedIdentityCredentials class, error: managed identity credentials request failed, status: 400, body: {"error":"invalid_request","error_description":"Identity not found"}
      ```
  - q: "Can I use `pg_password` together with the Azure authentication?"
    a: "No, when `pg_azure_auth` is enabled, `pg_password` will be ignored."
---

Microsoft Entra authentication (formerly Azure AD) provides a secure way to connect {{site.base_gateway}} to your Azure PostgreSQL database without storing database passwords in configuration files. This feature supports both Service Principal and Managed Identity authentication methods. This documentation provides an example about how to use Azure Managed Identity authentication to connect to Azure PostgreSQL Server.

## Prerequisites

Before configuring Azure authentication in {{site.base_gateway}}, you need the following:

* [Enable Azure PostgreSQL Flexible Server](https://learn.microsoft.com/azure/postgresql/flexible-server/security-entra-configure) by selecting **PostgreSQL and Microsoft Entra authentication** as your authentication method for your Azure Database for PostgreSQL flexible server instance.
* You need a managed identity and an Azure resource that uses the managed identity for authentication. For example, you can [create a user-assigned managed identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp#create-a-user-assigned-managed-identity) and [assign it to an Azure VM](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/how-to-configure-managed-identities?pivots=qs-configure-portal-windows-vm#assign-a-user-assigned-managed-identity-to-an-existing-vm). Copy and save the managed identity's client ID. You can find the client ID on the managed identity's detail page in the Azure Portal.
* Create an Azure Database for PostgreSQL flexible server user for your Managed Identity. To create a PostgreSQL user for your managed identity, you'll need to [connect to the Azure PostgreSQL server as Microsoft Entra administrator](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-configure-sign-in-azure-ad-authentication#authenticate-with-microsoft-entra-id). After successfully logging in to the Azure PostgreSQL server, run the following SQL command:
  ```
  postgres=> select * from pgaadauth_create_principal('my-managed-identity', false, false);

            pgaadauth_create_principal
  ------------------------------------------------
  Created role for "my-managed-identity"
  (1 row)
  ```
 You'll also need to prepare the correct {{site.base_gateway}} database for the Azure PostgreSQL user. For example the following command creates a `kong` database and assigns permissions on the public schema to the managed identity:
  ```
  postgres=> create database kong owner 'my-managed-identity' encoding 'utf-8';
  CREATE DATABASE
  postgres=> \c kong
  SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
  You are now connected to database "kong" as user "XXXXX".
  kong=> grant all on schema public to "my-managed-identity";
  GRANT
  ```

## Configuring Azure authentication in {{site.base_gateway}}

Now you can configure Azure authentication in {{site.base_gateway}} by setting configuration settings for your database.

{% navtabs "Configuration" %}

{% navtab "Environment variables" %}

To configure a read-write database with environment variables, use the following example: 

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

To configure a read-only database with environment variables, use the following example: 

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

To configure a read-write database using the [kong.conf file](/gateway/manage-kong-conf/), use the following example: 

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

To configure a read-only database using the [kong.conf file](/gateway/manage-kong-conf/), use the following example:

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

## Azure PostgreSQL Server configuration parameters

The following table describes the different configuration parameters you can set when configuring Azure Service Principal authentication to connect to the Azure PostgreSQL Server:

<!--vale off-->
{% kong_config_table %}
config:
  - name: pg_azure_auth
  - name: pg_azure_tenant_id
  - name: pg_azure_client_id
  - name: pg_azure_client_secret
  - name: pg_ro_azure_auth
  - name: pg_ro_azure_tenant_id
  - name: pg_ro_azure_client_id
  - name: pg_ro_azure_client_secret
{% endkong_config_table %}
<!--vale on-->


