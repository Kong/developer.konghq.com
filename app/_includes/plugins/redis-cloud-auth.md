## Using cloud authentication with Redis {% new_in 3.13 %}

Starting in {{site.base_gateway}} 3.13, you can authenticate with a cloud Redis provider for your Redis strategy. This allows you to seamlessly rotate credentials without relying on static passwords. 

The following providers are supported:
* AWS ElastiCache
* Azure Managed Redis
* Google Cloud Memorystore

Each provider also supports an instance and cluster configuration.

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% navtabs "providers" %}
{% navtab "AWS instance" %}

You need a running Redis instance on an [AWS ElastiCache instance](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html) for Valkey 7.2 or later or Elasticache for Redis OSS version 7.0 or later.

```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: ${instance_address}
      username: ${instance_username}
      port: 6379
    cloud_authentication:
      auth_provider: aws
      aws_cache_name: ${aws_cache}
      aws_is_serverless: false
      aws_region: ${aws_region}
      aws_access_key_id: ${aws_key_id}
      aws_secret_access_key: ${aws_secret_key}
```

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The ElastiCache instance address.
* `$INSTANCE_USERNAME`: The ElastiCache instance username.
* `$AWS_CACHE_NAME`: Name of your AWS ElastiCache instance.
* `$AWS_REGION`: Your AWS Elasticache instance region.
* `$AWS_ACCESS_KEY_ID`: (Optional) Your AWS access key ID. 
* `$AWS_ACCESS_SECRET_KEY`: (Optional) Your AWS secret access key.
{% endnavtab %}
{% navtab "AWS cluster" %}

You need a running Redis instance on an [AWS ElastiCache cluster](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html) for Valkey 7.2 or later or Elasticache for Redis OSS version 7.0 or later.

```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes: $CLUSTER_ADDRESS
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
* `$CLUSTER_USERNAME`: The ElastiCache cluster username.
* `$AWS_CACHE_NAME`: Name of your AWS ElastiCache cluster.
* `$AWS_REGION`: Your AWS Elasticache cluster region.
* `$AWS_ACCESS_KEY_ID`: (Optional) Your AWS access key ID. 
* `$AWS_ACCESS_SECRET_KEY`: (Optional) Your AWS secret access key.
{% endnavtab %}
{% navtab "Azure instance" %}

You need a running Redis instance on an [Azure Managed Redis instance](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication) with Entra authentication configured.

```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: ${instance_address}
      username: ${instance_username}
      port: 6379
    cloud_authentication:
      auth_provider: azure
      azure_client_id: ${azure_client_id}
      azure_client_secret: ${azure_client_secret}
      azure_tenant_id: ${azure_tenant_id}
```
Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Azure Managed Redis instance address.
* `$INSTANCE_USERNAME`: The Azure Managed Redis instance principal ID with essential access.
* `$AZURE_CLIENT_ID`: Your Azure Managed Redis instance client ID.
* `$AZURE_CLIENT_SECRET`: (Optional) Your Azure Managed Redis instance client secret. 
* `$AZURE_TENANT_ID`: (Optional) Your Azure Managed Redis instance tenant ID.

{% endnavtab %}
{% navtab "Azure cluster" %}

You need a running Redis instance on an [Azure Managed Redis cluster](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication) with Entra authentication configured.

```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes: ${cluster_address}
      username: ${cluster_username}
      port: 6379
    cloud_authentication:
      auth_provider: azure
      azure_client_id: ${azure_client_id}
      azure_client_secret: ${azure_client_secret}
      azure_tenant_id: ${azure_tenant_id}
```
Replace the following with your actual values:
* `$CLUSTER_ADDRESS`: The Azure Managed Redis cluster address.
* `$CLUSTER_USERNAME`: The Azure Managed Redis cluster principal ID with essential access.
* `$AZURE_CLIENT_ID`: Your Azure Managed Redis cluster client ID.
* `$AZURE_CLIENT_SECRET`: (Optional) Your Azure Managed Redis cluster client secret. 
* `$AZURE_TENANT_ID`: (Optional) Your Azure Managed Redis cluster tenant ID.

{% endnavtab %}
{% navtab "GCP instance" %}

You need a running Redis instance on an [Google Cloud Memorystore instance](https://cloud.google.com/memorystore/docs/cluster/about-iam-auth).

```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: ${instance_address}
      port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: ${service_account}
```
Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Memorystore instance address.
* `$GCP_SERVICE_ACCOUNT`: The GCP service account JSON.

instance_address:
    value: $INSTANCE_ADDRESS
    description: The Memorystore instance address.
  service_account:
    value: $GCP_SERVICE_ACCOUNT
    description: The GCP service account JSON.
{% endnavtab %}
{% navtab "GCP cluster" %}

You need a running Redis instance on an [Google Cloud Memorystore cluster](https://cloud.google.com/memorystore/docs/cluster/about-iam-auth).

```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes: ${cluster_address}
      port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: ${service_account}
```
Replace the following with your actual values:
* `$CLUSTER_ADDRESS`: The Memorystore cluster address.
* `$GCP_SERVICE_ACCOUNT`: The GCP service account JSON.
{% endnavtab %}
{% endnavtabs %}