---
title: "{{site.base_gateway}} Google Cloud Postgres database authentication with GCP IAM and Workload Identity"
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/
products:
    - gateway

tags:
  - database

min_version:
    gateway: '3.13'

description: "Learn how to use GCP Identity and Access Management (IAM) and Workload Identity authentication to connect to the Google Cloud Postgres database that you use for {{site.base_gateway}}"

related_resources:
  - text: "Install {{site.base_gateway}}"
    url: /gateway/install/
  - text: Connect a {{site.base_gateway}} Azure PostgreSQL Server using Azure Managed Identity
    url: /gateway/azure-pg-authentication-with-azure-managed-identity/
  - text: Connect a {{site.base_gateway}} Azure PostgreSQL Server using Azure Service Principal
    url: /gateway/azure-pg-authentication-with-azure-app-service-principal/
  - text: "{{site.base_gateway}} Amazon RDS database authentication with AWS IAM"
    url: /gateway/amazon-rds-authentication-with-aws-iam/

faqs:
    - q: "I'm getting a `Error: [PostgreSQL error] failed to bootstrap database: ERROR: permission denied for schema public (32)` when {{site.base_gateway}} tries to connect to the Cloud SQL PostgreSQL. How do I resolve this?"
      a: |
        If {{site.base_gateway}} reports an error when connecting to Cloud SQL PostgreSQL, it indicates that the IAM (service account) PostgreSQL user needs public permissions.

        You need to connect as a user with the ability to grant privileges. Usually, this is the Postgres built-in user. Run a SQL command like the following to grant privileges for the IAM user:

        ```
        -- allow usage of public schema
        GRANT USAGE ON SCHEMA public TO "service-account-name@project-name.iam";
        -- allow creating tables in public schema
        GRANT CREATE ON SCHEMA public TO "service-account-name@project-name.iam";
        ```

works_on:
  - on-prem
---

You can use GCP Identity and Access Management (IAM) and Workload Identity authentication to connect to the Google Cloud Postgres database that you use for {{site.base_gateway}}. This page explains how to configure IAM and Workload Identity authentication to secure your database settings and connections.

With authentication enabled, you don't need a password to connect to a database instance. Instead, you use a temporary authentication token. Because GCP manages the authentication externally, the database doesn't store user credentials. If you're using Google Cloud Postgres for {{site.base_gateway}}'s database, you can enable authentication on your running cluster. This eliminates the need to store user credentials on both the {{site.base_gateway}} (`pg_password`) and Google Cloud Postgres sides.

## GCP authentication limitations

GCP authentication has some limitations. Go through each one before you use this feature in your production environment:

* This feature cannot be used together with databases from other cloud providers, such as [AWS RDS](/gateway/amazon-rds-authentication-with-aws-iam/). These auth providers are mutually exclusive. 
* When `pg_gcp_auth` is enabled, the `pg_password` won't be used. You can't use both methods at the same time.
* Any incorrect configuration on the GCP side will result in a failure in initializing the database connection, such as an improperly configured managed identity or a missing role inside GCP Postgres.

For additional recommendations and limitations, see the [IAM authentication restrictions](https://docs.cloud.google.com/sql/docs/postgres/iam-authentication#restrictions) in the Google Cloud documentation.

## Enabling GCP authentication

You can enable GCP authentication through an environment variable or the {{site.base_gateway}} configuration file. You can enable it for both read-write and read-only modes, or for read-only mode only.

{:.info}
> **Note:** When GCP authentication is enabled, {{site.base_gateway}} ignores the corresponding password configurations. If authentication is enabled only for read-only mode, the read-write settings—such as `pg_user` and `pg_password`—remain unaffected and continue to function as usual.

### Configuring your GCP resources

Before you enable GCP authentication, you must configure your Google Cloud Postgres database and the IAM role or Workload Identity that {{site.base_gateway}} uses.

* [A GCP service account key](https://docs.cloud.google.com/iam/docs/keys-create-delete#creating). The service account must have sufficiently broad permissions; at minimum, it must be able to access GCP Postgres.
* [A database user bound to the GCP service account](https://docs.cloud.google.com/sql/docs/postgres/add-manage-iam-users#creating-a-database-user) with the Cloud SQL Instance User role (`roles/cloudsql.instanceUser`). The user must also be able to connect to the GCP Postgres instance from their GCP VM using `psql`.
* For IAM database authentication, you need a principal with [the `cloudsql.instances.login` permission](https://docs.cloud.google.com/sql/docs/mysql/iam-authentication) to log in to an instance, which is included in the Cloud SQL Instance User role.

### Configuring GCP authentication in {{site.base_gateway}}

Before you enable GCP authentication, you must do the following in the `kong.conf` file:
* Remove `pg_password` or `pg_ro_password`.
* Check that `pg_user` or `pg_ro_user` matches the username you defined in the IAM policy and created in the Postgres RDS database.

{% navtabs "Configuration" %}
{% navtab "Environment variables" %}


To enable GCP authentication in read-write and read-only mode, set the `KONG_PG_GCP_AUTH` environment variable to `on`: 

```bash
KONG_PG_GCP_AUTH=on
```

To enable GCP authentication in read-only mode, you can set the following:

```bash
KONG_PG_GCP_AUTH=off # This variable can be omitted because off is the default value
KONG_PG_RO_GCP_AUTH=on
```

Then, set the following, replacing placeholders with your values:
```bash
KONG_PG_USER='username@project-name.iam'        # Postgres user.
KONG_PG_DATABASE='kong'                         # The database name to connect to.
KONG_PG_HOST='35.200.xx.yy'                     # Host of the Postgres server.
KONG_PG_PORT='5432'                             # Port of the Postgres server.
KONG_PG_GCP_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"example-project-294816","private_key_id":"a7b3c9d2e8f1g4h6i5j7k9m2n4p6q8r1","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANB…………………………..…5xX5yY5zA==\n-----END PRIVATE KEY-----\n","client_email":"example-sa@example-project-294816.iam.gserviceaccount.com","client_id":"103847562938475629384","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/example-sa%40example-project-294816.iam.gserviceaccount.com","universe_domain":"googleapis.com"}'
```

{:.info}
> **Workload Identity only:** If you're using Workload Identity to authenticate, you don't need to configure the `KONG_PG_GCP_SERVICE_ACCOUNT_JSON`. {{site.base_gateway}}'s GCP authentication feature is designed to automatically fall back to the Workload Identity mechanism if the GCP service account JSON key isn't found in the configuration.

{% endnavtab %}

{% navtab "Configuration file" %}
To enable GCP authentication in read-write mode, set `pg_gcp_auth` to `on` in [`kong.conf`](/gateway/configuration/):
```text
pg_gcp_auth=on
```

To enable GCP authentication in read-only mode, set `pg_ro_gcp_auth` to `on`:
```text
pg_ro_gcp_auth=on
```

Then, set the following, replacing placeholders with your values:
```text
pg_user = username@project-name.iam        # Postgres user.
pg_database = kong                         # The database name to connect to.
pg_host = 35.200.xx.yy                     # Host of the Postgres server.
pg_port = 5432                             # Port of the Postgres server.
pg_gcp_service_account_json={"type":"service_account","project_id":"example-project-294816","private_key_id":"a7b3c9d2e8f1g4h6i5j7k9m2n4p6q8r1","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANB…………………………..…5xX5yY5zA==\n-----END PRIVATE KEY-----\n","client_email":"example-sa@example-project-294816.iam.gserviceaccount.com","client_id":"103847562938475629384","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/example-sa%40example-project-294816.iam.gserviceaccount.com","universe_domain":"googleapis.com"}
```

{:.info}
> **Notes:** 
> * If you enable GCP authentication in the configuration file, you must specify the configuration file with this feature configured on when you run the migrations command. For example, `kong migrations bootstrap -c /path/to/kong.conf`.
> * Workload Identity only: If you're using the Workload Identity to authenticate, you don't need to configure the `pg_gcp_service_account_json`. {{site.base_gateway}}'s GCP authentication feature is designed to automatically fall back to the Workload Identity mechanism if the GCP service account JSON key isn't found in the configuration.

{% endnavtab %}
{% endnavtabs %}