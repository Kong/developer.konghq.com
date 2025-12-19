---
title: "{{site.base_gateway}} Amazon RDS database authentication with AWS IAM"
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/
products:
    - gateway

tags:
  - aws

min_version:
    gateway: '3.3'

description: "Learn how to use AWS Identity and Access Management (IAM) authentication to connect to the Amazon RDS database that you use for {{site.base_gateway}}"

related_resources:
  - text: "Install {{site.base_gateway}}"
    url: /gateway/install/
  - text: Connect a {{site.base_gateway}} Azure PostgreSQL Server using Azure Managed Identity
    url: /gateway/azure-pg-authentication-with-azure-managed-identity/
  - text: Connect a {{site.base_gateway}} Azure PostgreSQL Server using Azure Service Principal
    url: /gateway/azure-pg-authentication-with-azure-app-service-principal/
  - text: "{{site.base_gateway}} Google Cloud Postgres database authentication with GCP IAM and Workload Identity"
    url: /gateway/gcp-postgres-authentication/

works_on:
  - on-prem
---

You can use AWS Identity and Access Management (IAM) authentication to connect to the Amazon RDS database that you use for {{site.base_gateway}}. This page explains how to configure IAM authentication to secure your database settings and connections.

With IAM authentication enabled, you don't need a password to connect to a database instance. Instead, you use a temporary authentication token. Because AWS IAM manages the authentication externally, the database doesn't store user credentials. If you're using Amazon RDS for {{site.base_gateway}}'s database, you can enable IAM authentication on your running cluster. This eliminates the need to store user credentials on both the {{site.base_gateway}} (`pg_password`) and RDS sides.

## AWS IAM authentication limitations

AWS IAM authentication has some limitations. Go through each one before you use this feature in your production environment:

* For a traditional {{site.base_gateway}} cluster or single traditional nodes, only use IAM database authentication if {{site.base_gateway}} requires less than 200 new IAM database authentications per second. Establishing more connections per second can result in throttling. Authentication only happens on each connection's initialization part after the connection is successfully established; the following queries and communication don't authenticate. Check the TPS of the connection establishment on your database to ensure you aren't encountering this limitation. Traditional clusters are more likely to encounter this limitation because each node needs to establish connections to the database. For more information, see [Recommendations for IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html#UsingWithRDS.IAMDBAuth.ConnectionsPerSecond) in the Amazon RDS user guide. 
* Enabling AWS IAM authentication requires SSL connection to the database. To do this, you must configure your RDS cluster correctly and provide the correct SSL-related configuration on the {{site.base_gateway}} side. Enabling SSL may cause some performance overhead if you weren't using it before. Currently, TLSv1.3 isn't supported by Amazon RDS.
- Since the Postgres RDS does not support mTLS, you can't enable mTLS between the {{site.base_gateway}} and the Postgres RDS database when AWS IAM authentication is enabled.
- You **can't** change the value of the environment variables that you use for the AWS credential after booting {{site.base_gateway}}.

For additional recommendations and limitations, see [IAM database authentication for MariaDB, MySQL, and PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html) in the Amazon RDS user guide. 


## Enabling AWS IAM authentication

You can enable AWS IAM authentication through an environment variable or the {{site.base_gateway}} configuration file. It supports both read-only and read-write modes, or you can enable it in read-only mode only.

{:.info}
> **Note:** When AWS IAM authentication is enabled, {{site.base_gateway}} ignores the corresponding password configurations. If authentication is enabled only for read-only mode, the read-write settings—such as `pg_user` and `pg_password` remain unaffected and continue to function as usual.

Before you enable AWS IAM authentication, you must do the following in the `kong.conf` file:
* Remove `pg_password` or `pg_ro_password`.
* Check that `pg_user` or `pg_ro_user` matches the username you defined in the IAM policy and created in the Postgres RDS database.

### Configuring your AWS resources

Before you enable the AWS IAM authentication, you must configure your Amazon RDS database and the AWS IAM role that {{site.base_gateway}} uses.

- **Enable the IAM database authentication on your database instance.** For more information, see [Enabling and disabling IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.Enabling.html) in the Amazon RDS user guide.
- **Assign an IAM role to your {{site.base_gateway}} instance.** {{site.base_gateway}} can automatically discover and fetch the AWS credentials to use for the IAM role.
   - If you use an EC2 environment, use the [EC2 IAM role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html).
   - If you use an ECS cluster, use a [ECS task IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html).
   - If you use an EKS cluster, configure a Kubernetes service account that can annotate your assigned role and configure the pods to use an [IAM role defined by `serviceaccount`](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html). 
   
      Using an IAM role defined by `serviceaccount` requires a request to the AWS STS service, so you also need to make sure that your Kong instance inside the Pod can access the AWS STS service endpoint. 
   
      When using STS regional endpoints, you must set the `AWS_STS_REGIONAL_ENDPOINTS` environment variable.
   - If you run {{site.base_gateway}} locally, use the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to define the access key and secret key, or `AWS_PROFILE` and `AWS_SHARED_CREDENTIALS_FILE` to use a profile and a credentials file.
   
   {:.warning}
   > **Warning:** You **can't** change the value of the environment variables you used to provide the AWS credential after booting {{site.base_gateway}}. Any changes are ignored.

   {:.info}
   > **Note:** IAM Identity Center credential provider and Process credential provider are not supported.

   - {% new_in 3.8 %} If you want Kong to assume a different IAM role, ensure that the original IAM role it uses has permission to assume the target role, and that the target role has permission to connect to the database using IAM authentication.
   - {% new_in 3.8 %} If you have users with non-public VPC networks and private VPC endpoints (without private DNS names enabled), you can configure an AWS Service Token Service (STS) endpoint globally with `vault_aws_sts_endpoint_url` or on a custom AWS Vault entity with `sts_endpoint_url`.

- **Assign an IAM policy to the {{site.base_gateway}} IAM role**. For more information, see [Creating and using an IAM policy for IAM database access](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html) in the Amazon RDS documentation.

- **Ensure you create the database account in the RDS**. For more information, see [Using IAM authentication with PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.DBAccounts.html#UsingWithRDS.IAMDBAuth.DBAccounts.PostgreSQL) in the Amazon RDS documentation. 

   {:.info}
   > **Notes:** 
   > * The database user assigned to the `rds_iam` role can only use the IAM database authentication.
   > * Make sure to create the database and grant the correct permissions to the database user you just created.

### Configuring AWS IAM authentication in {{site.base_gateway}}

{% navtabs "Configuration" %}
{% navtab "Environment variables" %}

To enable AWS IAM authentication in read-write and read-only mode, set the `KONG_PG_IAM_AUTH` environment variable to `on`: 

```bash
KONG_PG_IAM_AUTH=on
```

To enable AWS IAM authentication in read-only mode, you can set the following:

```bash
KONG_PG_IAM_AUTH=off # This variable can be omitted because off is the default value
KONG_PG_RO_IAM_AUTH=on
```

{% new_in 3.8 %} If you want to [assume a role](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html), also set the following environment variables:

```bash
# For read-write connections
KONG_PG_IAM_AUTH_ASSUME_ROLE_ARN=$ROLE_ARN
KONG_PG_IAM_AUTH_ROLE_SESSION_NAME=$ROLE_SESSION_NAME

# Optional: Specify a custom STS endpoint URL for IAM role assumption
# This value will override the default STS endpoint URL, which should be
# `https://sts.amazonaws.com`, or `https://sts.$REGION.amazonaws.com` if
# `AWS_STS_REGIONAL_ENDPOINTS` is set to `regional`(by default).
# Only set this if you're using a private VPC endpoint for the STS service
KONG_PG_IAM_AUTH_STS_ENDPOINT_URL=$STS_ENDPOINT

# For read-only connections, if you need a different role than for read-write
KONG_PG_RO_IAM_AUTH_ASSUME_ROLE_ARN=$ROLE_ARN
KONG_PG_RO_IAM_AUTH_ROLE_SESSION_NAME=$ROLE_SESSION_NAME
# Optional, same as KONG_PG_IAM_AUTH_STS_ENDPOINT_URL
KONG_PG_RO_IAM_AUTH_STS_ENDPOINT_URL=$STS_ENDPOINT
```
{% endnavtab %}

{% navtab "Configuration file" %}
To enable AWS IAM authentication in read-write mode, set `pg_iam_auth` to `on` in [`kong.conf`](/gateway/configuration/):
```text
pg_iam_auth=on
```

To enable AWS IAM authentication in read-only mode, set `pg_ro_iam_auth` to `on`:
```text
pg_ro_iam_auth=on
```

{% new_in 3.8 %} If you want to [assume a role](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html), also set the following configuration parameters:

```bash
# For read-write connections
pg_iam_auth_assume_role_arn=$ROLE_ARN
pg_iam_auth_role_session_name=$ROLE_SESSION_NAME
# Optional: Specify a custom STS endpoint URL for IAM role assumption 
# This value will override the default STS endpoint URL, which should be
# `https://sts.amazonaws.com`, or `https://sts.$REGION.amazonaws.com` if
# `AWS_STS_REGIONAL_ENDPOINTS` is set to `regional`(by default).
# Only set this if you're using a private VPC endpoint for the STS service 
pg_iam_auth_sts_endpoint_url=$STS_ENDPOINT

# For read-only connections, if you need a different role than for read-write
pg_ro_iam_auth_assume_role_arn=$ROLE_ARN
pg_ro_iam_auth_role_session_name=$ROLE_SESSION_NAME
# Optional: same as `pg_iam_auth_sts_endpoint_url`
pg_ro_iam_auth_sts_endpoint_url=$STS_ENDPOINT
```

{:.info}
> **Note:** If you enable AWS IAM authentication in the configuration file, you must specify the configuration file with the feature property on when you run the migrations command. For example, `kong migrations bootstrap -c /path/to/kong.conf`.

{% endnavtab %}
{% endnavtabs %}