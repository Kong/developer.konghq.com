## Using cloud authentication with Redis {% new_in 3.13 %}

Starting in {{site.base_gateway}} 3.13, you can authenticate with a cloud Redis provider for your Redis strategy. This allows you to seamlessly rotate credentials without relying on static passwords. 

The following providers are supported:
* AWS ElastiCache
* Azure Managed Redis
* Google Cloud Memorystore (with or without Valkey)

Each provider also supports an instance and cluster configuration.

{:.warning}
> **Important:** {{site.base_gateway}} open source plugins do not support any Redis cloud provider cluster configurations.

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% navtabs "providers" %}
{% navtab "AWS instance" %}

You need:
* A running Redis instance on an [AWS ElastiCache instance](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html) for Valkey 7.2 or later or ElastiCache for Redis OSS version 7.0 or later
* The [ElastiCache user needs to set "Authentication mode" to "IAM"](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup)
* The following policy assigned to the IAM user/IAM role that is used to connect to the ElastiCache:
  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "elasticache:Connect"
              ],
              "Resource": [
                  "arn:aws:elasticache:ARN_OF_THE_ELASTICACHE",
                  "arn:aws:elasticache:ARN_OF_THE_ELASTICACHE_USER"
              ]
          }
      ]
  }
  ```

```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: aws
        aws_cache_name: $AWS_CACHE_NAME
        aws_is_serverless: false
        aws_region: $AWS_REGION
        aws_access_key_id: $AWS_ACCESS_KEY_ID
        aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The ElastiCache instance address.
* `$INSTANCE_USERNAME`: The ElastiCache username with [IAM Auth mode configured](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup).
* `$AWS_CACHE_NAME`: Name of your AWS ElastiCache instance.
* `$AWS_REGION`: Your AWS ElastiCache instance region.
* `$AWS_ACCESS_KEY_ID`: (Optional) Your AWS access key ID. 
* `$AWS_ACCESS_SECRET_KEY`: (Optional) Your AWS secret access key.
{% endnavtab %}
{% navtab "AWS cluster" %}

You need:
* A running Redis instance on an [AWS ElastiCache cluster](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html) for Valkey 7.2 or later or ElastiCache for Redis OSS version 7.0 or later
* The [ElastiCache user needs to set "Authentication mode" to "IAM"](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup)
* The following policy assigned to the IAM user/IAM role that is used to connect to the ElastiCache:
  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "elasticache:Connect"
              ],
              "Resource": [
                  "arn:aws:elasticache:ARN_OF_THE_ELASTICACHE",
                  "arn:aws:elasticache:ARN_OF_THE_ELASTICACHE_USER"
              ]
          }
      ]
  }
  ```

```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      username: $CLUSTER_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: aws
        aws_cache_name: $AWS_CACHE_NAME
        aws_is_serverless: false
        aws_region: $AWS_REGION 
        aws_access_key_id: $AWS_ACCESS_KEY_ID
        aws_secret_access_key: $AWS_ACCESS_SECRET_KEY 
```

Replace the following with your actual values:
* `$CLUSTER_ADDRESS`: The ElastiCache cluster address.
* `$CLUSTER_USERNAME`: The ElastiCache username with [IAM Auth mode configured](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup).
* `$AWS_CACHE_NAME`: Name of your AWS ElastiCache cluster.
* `$AWS_REGION`: Your AWS ElastiCache cluster region.
* `$AWS_ACCESS_KEY_ID`: (Optional) Your AWS access key ID. 
* `$AWS_ACCESS_SECRET_KEY`: (Optional) Your AWS secret access key.
{% endnavtab %}
{% navtab "Azure instance" %}

You need:
* A running Redis instance on an [Azure Managed Redis instance](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication) with Entra authentication configured
* Add the [user/service principal/identity to the "Microsoft Entra Authentication Redis user" list](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication#add-users-or-system-principal-to-your-cache) for the Azure Managed Redis instance

```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```
Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Azure Managed Redis instance address.
* `$INSTANCE_USERNAME`: The object (principal) ID of the Principal/Identity with essential access.
* `$AZURE_CLIENT_ID`: The client ID of the Principal/Identity.
* `$AZURE_CLIENT_SECRET`: (Optional) The client secret of the Principal/Identity. 
* `$AZURE_TENANT_ID`: (Optional) The tenant ID of the Principal/Identity.

{% endnavtab %}
{% navtab "Azure cluster" %}

You need:
* A running Redis instance on an [Azure Managed Redis cluster](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication) with Entra authentication configured
* Add the [user/service principal/identity to the "Microsoft Entra Authentication Redis user" list](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication#add-users-or-system-principal-to-your-cache) for the Azure Managed Redis instance

```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      username: $CLUSTER_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```
Replace the following with your actual values:
* `$CLUSTER_ADDRESS`: The Azure Managed Redis cluster address.
* `$CLUSTER_USERNAME`: The object (principal) ID of the Principal/Identity with essential access.
* `$AZURE_CLIENT_ID`: The client ID of the Principal/Identity.
* `$AZURE_CLIENT_SECRET`: (Optional) The client secret of the Principal/Identity. 
* `$AZURE_TENANT_ID`: (Optional) The tenant ID of the Principal/Identity.

{% endnavtab %}
{% navtab "GCP instance" %}

You need:
* A running Redis instance on an [Google Cloud Memorystore instance](https://cloud.google.com/memorystore/docs/cluster/about-iam-auth)
* Assign the principal to the corresponding role: 
    * [Cloud Memorystore Redis DB Connection User(`roles/redis.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/cluster/about-iam-auth) for Memorystore for Redis Cluster
    * [Memorystore DB Connector User (`roles/memorystore.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/valkey/about-iam-auth) for Memorystore for Valkey

```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: $INSTANCE_ADDRESS
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Memorystore instance address.
* `$GCP_SERVICE_ACCOUNT`: (Optional) The GCP service account JSON.
{% endnavtab %}
{% navtab "GCP cluster" %}

You need:
* A running Redis instance on an [Google Cloud Memorystore cluster](https://cloud.google.com/memorystore/docs/cluster/about-iam-auth)
* Assign the principal to the corresponding role: 
    * [Cloud Memorystore Redis DB Connection User(`roles/redis.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/cluster/about-iam-auth) for Memorystore for Redis Cluster
    * [Memorystore DB Connector User (`roles/memorystore.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/valkey/about-iam-auth) for Memorystore for Valkey

```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379 
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
Replace the following with your actual values:
* `$CLUSTER_ADDRESS`: The Memorystore cluster address.
* `$GCP_SERVICE_ACCOUNT`: The GCP service account JSON.
{% endnavtab %}
{% endnavtabs %}